;+
; Get the meta data for converting raw ASF image to MLon image.
; The "MLon image" unwraps the fish-eye perspective in the raw ASF image.
; 
; time. A dummy variable for consistent interface.
; site. A string. See available sites by calling themis_asi_sites.
; renew. A boolean, set to re-generate the meta-data file.
; save_vars. A string array containing the saved variable names.
; 
; Note that the meta-data file are in *.tplot, may change to *.cdf later,
; but the difficulty here is I want to save lists, which is not suppored in CDF.
; 
; The saved variables are:
;   'thg_site_asf_old_all_index'. All 1D index of the old image. Mapping is not 1-1, so there are redundent indices.
;   'thg_site_asf_new_all_index'. All 1D index of the new image. Have same # of element as above.
;   'thg_site_asf_old_uniq_index'. The unique 1D index of the old image. An array of [m].
;   'thg_site_asf_new_uniq_index'. The unique 1D index of the new image. An array of [n].
;   'thg_site_asf_old_count'. The # of new pixels that each old unique pixel maps to. An array of [m].
;   'thg_site_asf_old_dict'. The new 1D pixels that each old unique pixel maps to. A list of [m]. 
;       This is essentially the same info taken by [old,new]_all_index. The reason to save it is that the list gives a faster conversion speed.
;   'thg_site_asf_new_count'. The # of old pixels that each new unique pixel maps to. An array of [n].
;   'thg_site_asf_new_dict'. The old pixels that each new unique pixel maps to. A list of [n].
;   'thg_site_asf_old_image_size'. Used to convert 1D index to 2D index, in [2].
;   'thg_site_asf_new_image_size'. Used to convert 1D index to 2D index, in [2].
;   'thg_site_asf_new_mlon_bins'. The new image is uniform in mlon, thus this is just a 1D array.
;   'thg_site_asf_new_mlat_bins'. The new image is uniform in mlat, thus this is just a 1D array.
;   'thg_site_asf_new_elevs'. The new image's elevation in deg, in 2D.
;   'thg_site_asf_new_azims'. The new image's azimuth in deg, in 2D.
;   'thg_site_asf_new_mlons'. The new image's mlon in deg, in 2D. This is essentially the same as mlon_bins, save just for convenience.
;   'thg_site_asf_new_mlats'. The new image's mlat in deg, in 2D.
;-
;

pro themis_read_mlonimg_metadata_gen_file, time, site=site, filename=file, save_vars=save_vars, _extra=extra

    pre0 = 'thg_'+site+'_'
    pre1 = pre0+'asf_'
    
    ; Get positions of the old pixels.
    themis_read_asc, time, site=site, vars=['mlon','mlat','elev','azim'], id='asf%v01', _extra=extra
    mlon_var = pre1+'mlon'
    mlat_var = pre1+'mlat'
    corner_mlons = get_var_data(mlon_var)
    corner_mlats = get_var_data(mlat_var)

    elev_var = pre1+'elev'
    center_elevs = get_var_data(elev_var)
    azim_var = pre1+'azim'
    center_azims = get_var_data(azim_var)
    
    old_image_size = size(center_elevs,/dimensions)
    center_mlons = 0.25*($
        corner_mlons[0:old_image_size[0]-1,0:old_image_size[1]-1]+$
        corner_mlons[1:old_image_size[0]  ,0:old_image_size[1]-1]+$
        corner_mlons[1:old_image_size[0]  ,1:old_image_size[1]  ]+$
        corner_mlons[0:old_image_size[0]-1,1:old_image_size[1]  ])

    ; Get the size and good pixels of the old image.
    old_uniq_index = where(finite(center_elevs) and finite(center_mlons), nold_pixel)


    ; The median values for site WHIT are
    ; 0.038 deg for dMlat
    ; 0.077 deg for dMlon
    ; So 0.1 deg for step in Mlat and 0.2 deg for Mlon gives 225 pixels in Mlat and 233 pixels in Mlon.
    dmlon = 0.2d
    dmlat = 0.1d
    mlon_bins = make_bins(corner_mlons, dmlon)
    mlat_bins = make_bins(corner_mlats, dmlat)
    mlon_bin_min = min(mlon_bins)
    mlat_bin_min = min(mlat_bins)
    nmlon_bin = n_elements(mlon_bins)
    nmlat_bin = n_elements(mlat_bins)
    new_image_size = [nmlon_bin,nmlat_bin]


    ; For good pixels, get the full dictionary that maps between each old and new pixels.
    ; We save the 1d index of the pixels. 1 old pixel could map to multiple new pixels, and vice versa.
    old_all_index = list() 
    new_all_index = list()
    foreach old_index_1d, old_uniq_index do begin
        old_index_2d = array_indices(old_image_size, old_index_1d, /dimensions)

        pixel_mlons = corner_mlons[old_index_2d[0]:old_index_2d[0]+1,old_index_2d[1]:old_index_2d[1]+1]
        pixel_mlats = corner_mlats[old_index_2d[0]:old_index_2d[0]+1,old_index_2d[1]:old_index_2d[1]+1]

        i0_bins = (pixel_mlons-mlon_bin_min)/dmlon
        j0_bins = (pixel_mlats-mlat_bin_min)/dmlat
        i1_range = minmax(round(i0_bins))   ; Sheng: round is better than floor?
        j1_range = minmax(round(j0_bins))

        i_bins = make_bins(i1_range, 1)
        j_bins = make_bins(j1_range, 1)
        ni_bin = n_elements(i_bins)
        nj_bin = n_elements(j_bins)
        
        for i=0, ni_bin-1 do begin
            for j=0, nj_bin-1 do begin
                new_index_1d = ulong64(i_bins[i]+j_bins[j]*nmlon_bin)
                old_all_index.add, old_index_1d
                new_all_index.add, new_index_1d
            endfor
        endfor
    endforeach
    old_all_index = old_all_index.toarray()
    new_all_index = new_all_index.toarray()
    new_uniq_index = sort_uniq(new_all_index)


    ; Save the dictionary of the indices.
    store_data, pre1+'old_all_index', 0, old_all_index
    store_data, pre1+'new_all_index', 0, new_all_index
    store_data, pre1+'old_uniq_index', 0, old_uniq_index
    store_data, pre1+'new_uniq_index', 0, new_uniq_index
    store_data, pre1+'old_image_size', 0, old_image_size
    store_data, pre1+'new_image_size', 0, new_image_size
    store_data, pre1+'new_mlon_bins', 0, mlon_bins
    store_data, pre1+'new_mlat_bins', 0, mlat_bins

    ; Save the count of old pixels that a new pixel maps to, and vice versa.
    new_count = fltarr(product(new_image_size))
    new_dict = list()
    foreach new_index_1d, new_uniq_index do begin
        new_dict.add, old_all_index[where(new_all_index eq new_index_1d, count)]
        new_count[new_index_1d] = count
    endforeach
    new_count = reform(new_count, new_image_size)
    
    old_count = fltarr(product(old_image_size))
    old_dict = list()
    foreach old_index_1d, old_uniq_index do begin
        old_dict.add, new_all_index[where(old_all_index eq old_index_1d, count)]
        old_count[old_index_1d] = count
    endforeach
    old_count = reform(old_count, old_image_size)
    
    store_data, pre1+'new_count', 0, new_count
    store_data, pre1+'old_count', 0, old_count
    store_data, pre1+'new_dict', 0, new_dict
    store_data, pre1+'old_dict', 0, old_dict

    ; Save the elev and azim of the new image.
    old_image = center_elevs[*]
    new_image = fltarr(product(new_image_size))
    foreach new_index_1d, new_uniq_index, ii do begin
        old_index_1d = new_dict[ii]
        val = old_image[old_index_1d]
        if n_elements(val) gt 1 then val = mean(val)
        new_image[new_index_1d] = val
    endforeach
    new_elevs = reform(new_image, new_image_size)

    old_image = center_azims[*]
    new_image = fltarr(product(new_image_size))
    foreach new_index_1d, new_uniq_index, ii do begin
        old_index_1d = new_dict[ii]
        val = old_image[old_index_1d]
        if n_elements(val) gt 1 then val = mean(val)
        new_image[new_index_1d] = val
    endforeach
    new_azims = reform(new_image, new_image_size)
    
    store_data, pre1+'new_elevs', 0, new_elevs
    store_data, pre1+'new_azims', 0, new_azims

    ; Save the 2D mlon and mlat for the new image.
    new_mlons = mlon_bins # (fltarr(nmlat_bin)+1)
    new_mlats = (fltarr(nmlon_bin)+1) # mlat_bins
    store_data, pre1+'new_mlons', 0, new_mlons
    store_data, pre1+'new_mlats', 0, new_mlats


;    save_vars = pre1+['old_all_index','new_all_index', $
;        'old_uniq_index','new_uniq_index', $
;        'old_image_size','new_image_size', $
;        'old_count','new_count', $
;        'old_dict','new_dict', $
;        'new_mlon_bins','new_mlat_bins', $
;        'new_elevs','new_azims','new_mlons','new_mlats']
    tplot_save, save_vars, filename=file

end


pro themis_read_mlonimg_metadata_read_file, filename=file, save_vars=save_vars

    nsave_var = n_elements(save_vars)
    load = 0
    if nsave_var eq 0 then begin
        load = 1
    endif else begin
        foreach var, save_vars do begin
            if tnames(var) eq '' then begin
                load = 1
                break
            endif
        endforeach
    endelse
    
    if load then tplot_restore, filename=file

end

pro themis_read_mlonimg_metadata, time, site=site, errmsg=errmsg, renew=renew, $
    _extra=extra

    compile_opt idl2
    on_error, 0
    errmsg = ''
    
    ; Prepare file name.
    version = 'v01'
    local_root = join_path([default_local_root(),'sdata','themis'])
    base_name = 'thg_l2_mlonimg_metadata_'+site+'_'+version+'.tplot'
    local_dir = join_path([local_root,'thg','l2','mlonimg','metadata'])
    file = join_path([local_dir,base_name])
    if file_test(local_dir,/directory) eq 0 then file_mkdir, local_dir
    if keyword_set(renew) then if file_test(file) eq 1 then file_delete, file
    
    pre1 = 'thg_'+site[0]+'_asf_'
    save_vars = pre1+['old_all_index','new_all_index', $
        'old_uniq_index','new_uniq_index', $
        'old_image_size','new_image_size', $
        'old_count','new_count', $
        'old_dict','new_dict', $
        'new_mlon_bins','new_mlat_bins', $
        'new_elevs','new_azims','new_mlons','new_mlats']
    
    if file_test(file) eq 0 then begin
        lprmsg, 'Generating '+file[0]+' ...'
        themis_read_mlonimg_metadata_gen_file, time, site=site, filename=file, save_vars=save_vars, _extra=extra
    endif

    if file_test(file) eq 0 then begin
        errmsg = handle_error('Cannot find the file: '+file[0]+' ...')
        return
    endif

    themis_read_mlonimg_metadata_read_file, filename=file, save_vars=save_vars

end

themis_read_mlonimg_metadata, 0, site='pina';, /renew
end
