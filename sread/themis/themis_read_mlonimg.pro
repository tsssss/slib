;+
; Read MLon image for a given time range, sites and settings.
;
; time. A time or time range in UT sec.
; sites. A string or an array of site names in lower cases.
; site_infos. An array of structures. This is used to fine tune properties of each site. See details in themis_read_mlonimg_default_site_info.
; merge_method. A string sets how to deal with overlapping pixels.
;   'max_elev'. Use the pixel from the site has the largest elevation. This is the default option.
;   'merge_elev'. Weight the pixel of each site by its elevation. The weight is its elevation over the sum of elevations of all overlapping sites.
; height. A number sets the emission height in km in altitude. The default value is 110 km. Do not recommend to set this unless intentional.
; mlon_range. In [2], the range of MLon in deg. Optional.
; mlat_range. In [2], the range of MLat in deg. Optional.
; local_root. A string sets the local root directory for the CDFs of MLon images.
; version. A string for meta data.
; renew_file. A boolean to renew the CDF files for MLon images.
;
; Note: The program saves the "mosaic" MLon image to memory. The tplot name is 'thg_mlonimg'. The properties include 'mlon_bins', 'mlat_bins', and 'bin_size', 'image_size'. 'bin_size' is the [dmlon,dmlat] for the mlat/mlon bins.
; The program generates a CDF of MLon image for each CDF of the raw ASF data. The only difference between the MLon and ASF images is that the MLon images are flat in perspective.
; The program then merges the MLon images from each site. There are several ways to merge overlapping pixels.
;-



; Calculate the weight for each mlon image.
pro themis_read_mlonimg_gen_metadata, time, sites=sites, errmsg=errmsg, $
    site_infos=site_infos, merge_method=merge_method

    errmsg = ''

    ; Check inputs.
    nsite = n_elements(sites)
    if nsite eq 0 then begin
        errmsg = handle_error('No input site ...')
        return
    endif

    if nsite ne n_elements(site_infos) then begin
        site_infos = themis_read_mlonimg_default_site_info(sites)
    endif

    if n_elements(merge_method) eq 0 then merge_method = 'max_elev'

    ; Prepare meta data for each site.
    ptr_metadata = ptrarr(nsite, /allocate_heap)
    mlon_range = []
    mlat_range = []
    for ii=0, nsite-1 do begin
        site = sites[ii]

        ; prepare meta data.
        themis_read_mlonimg_metadata, time, site=site

        ; store necessary meta data for faster r/w.
        site_info = site_infos[ii]
        pre0 = 'thg_'+site+'_asf_'

        elev_2d = get_var_data(pre0+'new_elevs')
        i_cntr = where(elev_2d ge site_info.min_elev, /null, complement=i_edge)
        weight_2d = fltarr(size(elev_2d,/dimensions))
        weight_2d[i_cntr] = 1

        mlon_bins = get_var_data(pre0+'new_mlon_bins')
        mlat_bins = get_var_data(pre0+'new_mlat_bins')

        mlon_range = [mlon_range,minmax(mlon_bins)]
        mlat_range = [mlat_range,minmax(mlat_bins)]

        ptr_metadata[ii] = ptr_new({$
            name:site_info.name, $
            min_elev:site_info.min_elev, $
            dmlon:site_info.dmlon, $
            dmlat:site_info.dmlat, $
            elev_2d:elev_2d, $      ; the original elev 2d.
            weight_2d:weight_2d, $  ; weight will be applied to each pixel.
            i_cntr:i_cntr, $        ; index maps a 2d image to center.
            i_edge:i_edge, $        ; index maps a 2d image to edge.
            xbins:round(mlon_bins/site_info.dmlon), $
            ybins:round(mlat_bins/site_info.dmlat), $
            placeholder:0b})
    endfor

    ; Prepare meta data for the mosaic.
    mlon_range = minmax(mlon_range)
    mlat_range = minmax(mlat_range)
    mos_dmlon = min(site_infos.dmlon)
    mos_dmlat = min(site_infos.dmlat)
    mos_xbins = round(make_bins(round(mlon_range/mos_dmlon), 1))
    mos_ybins = round(make_bins(round(mlat_range/mos_dmlat), 1))
    mos_size = [n_elements(mos_xbins),n_elements(mos_ybins)]


    ; Map pixels from each site to the mosaic.
    mos_count = intarr(mos_size)
    for ii=0, nsite-1 do begin
        site_xrange = minmax((*ptr_metadata[ii]).xbins)
        site_yrange = minmax((*ptr_metadata[ii]).ybins)
        i1 = where(mos_xbins eq site_xrange[0])
        i2 = where(mos_xbins eq site_xrange[1])
        j1 = where(mos_ybins eq site_yrange[0])
        j2 = where(mos_ybins eq site_yrange[1])
        timg = (*ptr_metadata[ii]).weight_2d
        mos_count[i1:i2,j1:j2] += timg
    endfor

    ; Treat overlapping pixels.
    overlap_pixels = where(mos_count gt 1, noverlap_pixel)
    for ii=0, noverlap_pixel-1 do begin
        mos_index_1d = overlap_pixels[ii]
        mos_index_2d = array_indices(mos_size, mos_index_1d, /dimensions)
        current_x = mos_xbins[mos_index_2d[0]]
        current_y = mos_ybins[mos_index_2d[1]]

        ; Collect info for each site.
        site_pixel_info = {$
            index_1d:0ull, $    ; pixel's 1d index in the original 2d image.
            index_2d:[0ul,0], $ ; pixel's 2d index in the 2d image.
            elev:0., $          ; pixel's elevation in deg.
            name:'', $          ; the site name in string in lowercase.
            placeholder:0b}
        site_pixel = replicate(site_pixel_info, nsite)
        for jj=0, nsite-1 do begin
            i1 = where((*ptr_metadata[jj]).xbins eq current_x, count1)
            j1 = where((*ptr_metadata[jj]).ybins eq current_y, count2)
            if count1 eq 0 or count2 eq 0 then continue
            site_pixel[jj].index_2d = [i1,j1]
            site_pixel[jj].elev = (*ptr_metadata[jj]).elev_2d[i1,j1]
            site_pixel[jj].name = sites[jj]
        endfor
        site_pixel = site_pixel[where(site_pixel.name ne '', current_nsite)]

        ; Modify the weight for each site.
        weights = fltarr(current_nsite)
        case merge_method of
            'max_elev': begin   ; use the value of the max elevation.
                max_elev = max(site_pixel.elev, index)
                weights[index] = 1
            end
            'merge_elev': begin ; weight by elevation.
                weights = site_pixel.elev/total(site_pixel.elev)
            end
            else: weights[*] = 1
        endcase

        ; Distribute the weight for the current pixel to each site.
        for kk=0, current_nsite-1 do begin
            i1 = site_pixel[kk].index_2d[0]
            j1 = site_pixel[kk].index_2d[1]
            index = (where(sites eq site_pixel[kk].name))[0]
            (*ptr_metadata[index]).weight_2d[i1,j1] = weights[kk]
        endfor
    endfor

    ; Convert pointer to list.
    site_metadata = list()
    for ii=0, nsite-1 do begin
        site_metadata.add, *ptr_metadata[ii]
        ptr_free, ptr_metadata[ii]
    endfor

    ; Save the meta data to memory.
    pre0 = 'thg_mlonimg_'
    store_data, pre0+'xbins', 0, mos_xbins
    store_data, pre0+'ybins', 0, mos_ybins
    store_data, pre0+'mlon_bins', 0, mos_xbins*mos_dmlon
    store_data, pre0+'mlat_bins', 0, mos_ybins*mos_dmlat
    store_data, pre0+'bin_size', 0, [mos_dmlon,mos_dmlat]
    store_data, pre0+'image_size', 0, [mos_size]
    store_data, pre0+'site_metadata', 0, site_metadata
end


; Read data from the CDF files for the MLon image.
pro themis_read_mlonimg_read_file, filename=file

    pre0 = 'thg_mlonimg_pixel_'
    save_vars = pre0+['mlons','mlats','elevs','sites','npixel','bin_size']

    load = 0
    foreach tvar, save_vars do if tnames(tvar) eq '' then load = 1
    if load then tplot_restore, filename=file
end


; Save the MLon image for a corresponding ASF data file. This is usually a file for one site, for one hour.
pro themis_read_mlonimg_gen_file, time, site=site, height=height, filename=file, errmsg=errmsg, _extra=extra

    errmsg = ''

    if n_elements(file) eq 0 then begin
        errmsg = 'No output file ...'
        return
    endif

    ; Read data to memory.
    ;time = time[0]+[0,9]   ; for tests.
    themis_read_mlonimg_per_site, time, site=site, errmsg=errmsg, height=height, _extra=extra
    if errmsg ne '' then return
    pre0 = 'thg_'+site+'_asf_'

    ; Save data to file.
    mlonimg_var = pre0+'mlonimg'
    get_data, mlonimg_var, times, mlonimgs

    nrec = n_elements(times)
    if nrec eq 0 then begin
        errmsg = handle_error('Error in converting to MLon image ...')
        return
    endif
    image_size = (size(mlonimgs,/dimensions))[1:2]
    mlonimgs = transpose(mlonimgs,[1,2,0])

    ; For 4 records:
    ;  size KB  compress
    ;   888     0
    ;   237     1           so this is the optimal compress level.
    ;   231     2
    ;   218     4
    compress = 1
    ginfo = {$
        title: 'THEMIS ASI full-resolution images, converted to uniform MLon/MLat coordinate', $
        text: 'Generated by Sheng Tian at the University of Minnesota'}
    scdfwrite, file, gattribute=ginfo, errmsg=errmsg

    utname = 'ut_sec'
    ainfo = {$
        fieldnam: 'UT sec', $
        units: 'sec', $
        var_type: 'support_data'}
    scdfwrite, file, utname, value=times, attribute=ainfo, cdftype='CDF_DOUBLE', errmsg=errmsg

    mlon_bins = get_var_data(pre0+'new_mlon_bins')
    vname = 'mlon'
    ainfo = {$
        fieldnam: 'MLon', $
        units: 'deg', $
        var_type: 'support_data'}
    scdfwrite, file, vname, value=mlon_bins, attribut=ainfo, errmsg=errmsg

    mlat_bins = get_var_data(pre0+'new_mlat_bins')
    vname = 'mlat'
    ainfo = {$
        fieldnam: 'MLat', $
        units: 'deg', $
        var_type: 'support_data'}
    scdfwrite, file, vname, value=mlat_bins, attribut=ainfo, errmsg=errmsg

    vname = 'mlon_image'
    ainfo = {$
        fieldnam: 'MLon image', $
        units: '#', $
        var_type: 'data', $
        depend_0: utname, $
        depend_1: 'mlon', $
        depend_2: 'mlat'}
    scdfwrite, file, vname, value=mlonimgs, attribute=ainfo, errmsg=errmsg, $
        dimvary=[1,1], dimensions=image_size, compress=compress


    if errmsg ne 0 then begin
        errmsg = handle_error('Error in saving to CDF: '+errmsg+' ...')
        if file_test(file) then file_delete, file
        return
    endif
end


pro themis_read_mlonimg, time, sites=sites, errmsg=errmsg, $
    site_infos=site_infos, merge_method=merge_method, $
    height=height, mlon_range=mlon_range, mlat_range=mlat_range, $
    local_root=local_root, version=version, renew_file=renew_file, _extra=extra

    compile_opt idl2
    on_error, 0
    errmsg = ''

    deg = 180d/!dpi
    rad = !dpi/180d

    test = 0

;---Check inputs.
    if n_elements(time) eq 0 then begin
        errmsg = handle_error('No input time ...')
        return
    endif
    if size(time,/type) eq 7 then time = time_double(time)
    cadence = 3600d ; sec, i.e., 1 hour.
    file_times = break_down_times(time, cadence)

    nsite = n_elements(sites)
    if nsite eq 0 then begin
        errmsg = handle_error('No input site ...')
        return
    endif

    if n_elements(height) eq 0 then height = 110d   ; km.
    if n_elements(site_infos) ne nsite then site_infos = themis_read_mlonimg_default_site_info(sites)

    if n_elements(version) eq 0 then version = 'v01'
    if n_elements(local_root) eq 0 then local_root = join_path([default_local_root(),'sdata','themis'])


;---Get the MLon image for each site.
    in_vars = ['mlon_image']
    time_var_name = 'ut_sec'
    time_var_type = 'unix'
    foreach site, sites do begin
        base_pattern = 'thg_l2_mlonimg_'+site+'_%Y_%m%d_%H_'+version+'.cdf'
        local_pattern = join_path([local_root,'thg','l2','mlonimg',site,'%Y','%m',base_pattern])
        files = list()
        foreach file_time, file_times do begin
            file = apply_time_to_pattern(local_pattern, file_time)
            if keyword_set(renew_file) then if file_test(file) eq 1 then file_delete, file
            if file_test(file) eq 0 then themis_read_mlonimg_gen_file, file_time+[0,cadence], site=site, filename=file, errmsg=errmsg, height=height, _extra=extra
            if file_test(file) eq 1 then files.add, file
        endforeach

        pre0 = 'thg_'+site+'_asf_'
        out_vars = pre0+['mlon_image']
        request = dictionary($
            'var_list', list($
                dictionary($
                    'in_vars', in_vars, $
                    'out_vars', out_vars, $
                    'time_var_name', time_var_name, $
                    'time_var_type', time_var_type )))
        read_files, time, files=files, request=request
        themis_read_mlonimg_metadata, time, site=site
    endforeach


;---Merge MLon images from sites together.
    ; Scale raw count to photon count.
    foreach site, sites do begin
        pre0 = 'thg_'+site+'_asf_'
        get_data, pre0+'mlon_image', times, mlonimgs
        ntime = n_elements(times)
        themis_read_asi_treat_raw_count, pre0+'mlon_image', to=pre0+'mlon_image_norm'
    endforeach

;---Get the meta data for merging.
    themis_read_mlonimg_gen_metadata, time, sites=sites, site_infos=site_infos, merge_method=merge_method
    pre0 = 'thg_mlonimg_'
    image_size = get_var_data(pre0+'image_size')
    mos_bin_size = get_var_data(pre0+'bin_size')
    mos_xbins = get_var_data(pre0+'xbins')
    mos_ybins = get_var_data(pre0+'ybins')
    site_metadata = get_var_data(pre0+'site_metadata')
    site_is = intarr(nsite,2)
    site_js = intarr(nsite,2)
    for ii=0, nsite-1 do begin
        site_xrange = minmax(site_metadata[ii].xbins)
        site_yrange = minmax(site_metadata[ii].ybins)
        site_is[ii,0] = where(mos_xbins eq site_xrange[0])
        site_is[ii,1] = where(mos_xbins eq site_xrange[1])
        site_js[ii,0] = where(mos_ybins eq site_yrange[0])
        site_js[ii,1] = where(mos_ybins eq site_yrange[1])
    endfor


;---Get the mosaic image.
    cadence = 3d
    times = (n_elements(time) eq 1)? time: make_bins(time,cadence)
    ntime = n_elements(times)
    mos_images = fltarr([ntime,image_size])
    for ii=0, ntime-1 do begin
        lprmsg, time_string(times[ii])+' ...'
        mos_image = fltarr(image_size)
        ; Fill in the pixels by sites.
        for jj=0, nsite-1 do begin
            pre0 = 'thg_'+sites[jj]+'_asf_'
            site_image = get_var_data(pre0+'mlon_image_norm', at=times[ii])
            mos_image[site_is[jj,0]:site_is[jj,1], $
                site_js[jj,0]:site_js[jj,1]] += $
                site_image*site_metadata[jj].weight_2d
        endfor
        mos_images[ii,*,*] = mos_image
    endfor

;---Crop to the wanted mlon/mlat range.
    if n_elements(mlon_range) eq 2 then begin
        x_range = round(mlon_range/mos_bin_size[0])
        index = where(mos_xbins ge x_range[0] and mos_xbins le x_range[1], count)
        if count ne 0 then begin
            mos_images = mos_images[*,index,*]
            mos_xbins = mos_xbins[index]
        endif
    endif
    if n_elements(mlat_range) eq 2 then begin
        y_range = round(mlat_range/mos_bin_size[1])
        index = where(mos_ybins ge y_range[0] and mos_ybins le y_range[1], count)
        if count ne 0 then begin
            mos_images = mos_images[*,*,index]
            mos_ybins = mos_ybins[index]
        endif
    endif

    mos_mlons = mos_xbins*mos_bin_size[0]
    mos_mlats = mos_ybins*mos_bin_size[1]
    mlonimg_var = 'thg_mlonimg
    store_data, mlonimg_var, times, mos_images
    add_setting, mlonimg_var, /smart, {$
        bin_size:mos_bin_size, $
        image_size:image_size, $
        mlon_bins:mos_mlons, $
        mlat_bins:mos_mlats}

    if keyword_set(test) then begin
        image_size = size(reform(mos_images[0,*,*]),/dimensions)
        window, 0, xsize=image_size[0], ysize=image_size[1]
        loadct, 40
        device, decomposed=0
        for ii=0, ntime-1 do begin
            mos_image = reform(mos_images[ii,*,*])
            tv, bytscl(mos_image, max=700, top=254)
            wait, 0.02
        endfor
        stop
    endif
end


time = time_double(['2014-08-28/10:02','2014-08-28/10:17'])
sites = ['whit','fsim']
min_elevs = [5,10]
mlon_range = [-100,-55]
mlat_range = [60,75]
renew_file = 0
merge_method = 'merge_elev'

;time = time_double(['2014-08-28/04:55','2014-08-28/05:10'])
;sites = ['pina','kapu','snkq']
;min_elevs = [5,10,10]
;mlon_range = [-50,10]
;mlat_range = [60,70]
;renew_file = 0
;merge_method = 'max_elev'

time = time_double(['2014-08-28/10:02','2014-08-28/10:30'])
time = time_double(['2014-08-28/10:13:03','2014-08-28/10:13:06'])
sites = ['whit','fsim']
min_elevs = [5,20]
mlon_range = [-100,-55]
mlat_range = [60,75]
renew_file = 0
merge_method = 'max_elev'

site_infos = themis_read_mlonimg_default_site_info(sites)
foreach min_elev, min_elevs, ii do site_infos[ii].min_elev = min_elev

themis_read_mlonimg, time, sites=sites, site_infos=site_infos, $
    mlon_range=mlon_range, mlat_range=mlat_range, merge_method=merge_method


end
