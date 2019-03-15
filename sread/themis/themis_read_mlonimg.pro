;+
;-
;

pro themis_read_mlonimg_gen_metadata, time, filename=file, errmsg=errmsg, save_vars=save_vars

    errmsg = ''

    if n_elements(local_root) eq 0 then local_root = join_path([default_local_root(),'sdata','themis'])
    sites = themis_asi_sites()
    ;sites = ['pina','gill','tpas']  ; for test purpose.
    foreach site, sites do themis_read_mlonimg_metadata, time, site=site

    ; Collect all pixels from all site.
    ; List is too slow!!! So use array and then shrink.
    npixel = 0
    foreach site, sites do begin
        pre0 = 'thg_'+site+'_asf_'
        all_1d_index = get_var_data(pre0+'new_uniq_index')
        npixel += n_elements(all_1d_index)
    endforeach
    
    pre0 = 'thg_'+sites[0]+'_asf_'
    tmp = get_var_data(pre0+'new_mlon_bins')
    dmlon_bin = tmp[1]-tmp[0]
    tmp = get_var_data(pre0+'new_mlat_bins')
    dmlat_bin = tmp[1]-tmp[0]
    
    all_mlons = fltarr(npixel)      ; the mlon in deg, elements are numbers.
    all_mlats = fltarr(npixel)      ; the mlat in deg, elements are numbers.
    all_elevs = fltarr(npixel)      ; the elev in deg, elements are arrays.
    all_sites = strarr(npixel)      ; the site in string, elements are arrays.
    map_dict = lon64arr(npixel)
    uniq_xs = []    ; has to convert to integers, floats are bad for where
    uniq_ys = []
    all_xs = lon64arr(npixel)
    all_ys = lon64arr(npixel)

    tic
    nuniq_pixel = 0ull
    last_index = 0ull
    foreach site, sites do begin
        lprmsg, 'Processing site: '+site+' ...'
        pre0 = 'thg_'+site+'_asf_'
        all_1d_index = get_var_data(pre0+'new_uniq_index')
        image_size = get_var_data(pre0+'new_image_size')
        mlon_2d = get_var_data(pre0+'new_mlons')
        mlat_2d = get_var_data(pre0+'new_mlats')
        x_2d = round(mlon_2d/dmlon_bin)
        y_2d = round(mlat_2d/dmlat_bin)
        elev_2d = get_var_data(pre0+'new_elevs')
        foreach current_1d_index, all_1d_index do begin
            current_x = x_2d[current_1d_index]
            current_y = y_2d[current_1d_index]
            all_xs[last_index] = current_x
            all_ys[last_index] = current_y
            all_elevs[last_index] = elev_2d[current_1d_index]
            all_sites[last_index] = site
            index = where(uniq_xs eq current_x and uniq_ys eq current_y, count)
            if count eq 0 then begin
                uniq_xs = [uniq_xs, current_x]
                uniq_ys = [uniq_ys, current_y]
                nuniq_pixel += 1
                map_dict[last_index] = nuniq_pixel
            endif else map_dict[last_index] = index
            last_index += 1
        endforeach
    endforeach

    
    ; Map to uniq (mlon,mlat) pairs.
    uniq_mlons = fltarr(nuniq_pixel)
    uniq_mlats = fltarr(nuniq_pixel)
    uniq_elevs = list(length=nuniq_pixel)
    uniq_sites = list(length=nuniq_pixel)
    uniq_count = ulonarr(nuniq_pixel)
    for ii=0ull, nuniq_pixel-1 do begin
        index = where(map_dict eq ii, count)
        uniq_count[ii] = count
        uniq_mlons[ii] = all_xs[index]
        uniq_mlats[ii] = all_ys[index]
        uniq_elevs[ii] = all_elevs[index]
        uniq_sites[ii] = all_sites[index]
    endfor
    uniq_mlons *= dmlon_bin
    uniq_mlats *= dmlat_bin

    x_bins = round(make_bins(uniq_xs, 1))
    y_bins = round(make_bins(uniq_ys, 1))
    nx_bin = n_elements(x_bins)
    ny_bin = n_elements(y_bins)
    
    count_2d = intarr(nx_bin,ny_bin)
    for ii=0ull, nuniq_pixel-1 do begin
        xx = where(x_bins eq uniq_xs[ii])
        yy = where(y_bins eq uniq_ys[ii])
        count_2d[xx,yy] = uniq_count[ii]
    endfor
    toc

    pre0 = 'thg_mlonimg_pixel_'
    store_data, pre0+'mlons', 0, uniq_mlons
    store_data, pre0+'mlats', 0, uniq_mlats
    store_data, pre0+'elevs', 0, uniq_elevs
    store_data, pre0+'sites', 0, uniq_sites
    store_data, pre0+'npixel', 0, nuniq_pixel
    store_data, pre0+'bin_size', 0, [dmlon_bin,dmlat_bin]

    save_vars = pre0+['mlons','mlats','elevs','sites','npixel','bin_size']
    tplot_save, save_vars, filename=file
    
end


pro themis_read_mlonimg_read_file, filename=file
    
    pre0 = 'thg_mlonimg_pixel_'
    save_vars = pre0+['mlons','mlats','elevs','sites','npixel','bin_size']

    load = 0
    foreach tvar, save_vars do if tnames(tvar) eq '' then load = 1
    if load then tplot_restore, filename=file
    
end

pro themis_read_mlonimg_gen_file, time, site=site, filename=file, errmsg=errmsg, extra=_extra

    errmsg = ''

    if n_elements(file) eq 0 then begin
        errmsg = 'No output file ...'
        return
    endif

    ; Read data to memory.
    ;time = time[0]+[0,9]   ; for tests.
    themis_read_mlonimg_per_site, time, site=site, errmsg=errmsg, extra=_extra
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
    height=height, min_lat=min_lat, mlon_range=mlon_range, mlat_range=mlat_range, min_elevs=min_elevs, $
    local_root=local_root, version=version, renew_file=renew_file, extra=_extra

    compile_opt idl2
    on_error, 0
    errmsg = ''

    deg = 180d/!dpi
    rad = !dpi/180d
    
    test = 1

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
    if n_elements(min_lat) eq 0 then min_lat = 50d  ; deg.
    if n_elements(mlat_range) eq 0 then mlat_range = [min_lat,90]
    if n_elements(mlon_range) eq 0 then mlon_range = [-180d,180]
    if n_elements(min_elevs) eq 0 then min_elevs = 7+fltarr(nsite) ; deg.

    
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
            if file_test(file) eq 0 then themis_read_mlonimg_gen_file, file_time+[0,cadence], site=site, filename=file, errmsg=errmsg, extra=_extra
            if file_test(file) eq 1 then files.add, file
        endforeach
        
        pre0 = 'thg_'+site+'_asf_'
        out_vars = pre0+['mlon_image']
        read_and_store_var, files, time_info=time, errmsg=errmsg, $
            in_vars=in_vars, out_vars=out_vars, $
            time_var_name=time_var_name, time_var_type=time_var_type
        
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
    
    ; Prepare the meta-data.
    elev_2ds = list()
    mlon_2ds = list()
    mlat_2ds = list()
    foreach site, sites do begin
        pre0 = 'thg_'+site+'_asf_'
        elev_2ds.add, get_var_data(pre0+'new_elevs')
        mlon_2ds.add, get_var_data(pre0+'new_mlons')
        mlat_2ds.add, get_var_data(pre0+'new_mlats')
    endforeach
    

;---Get the meta-data for merging.
    file = join_path([local_root,'thg','l2','mlonimg','metadata','thg_l2_mlonimg_metadata_'+version+'.tplot'])
    if file_test(file) eq 0 then themis_read_mlonimg_gen_metadata, time, filename=file
    themis_read_mlonimg_read_file, filename=file
    pre1 = 'thg_mlonimg_pixel_'
    all_xs = get_var_data(pre1+'mlons')
    all_ys = get_var_data(pre1+'mlats')
    npx = get_var_data(pre1+'npixel')       ; # of pixels that have data.
    px_mlons = get_var_data(pre1+'mlons')   ; the mlon in deg for each pixel.
    px_mlats = get_var_data(pre1+'mlats')   ; the mlat in deg for each pixel.
    px_elevs = get_var_data(pre1+'elevs')   ; the elev in deg for each pixel.
    px_sites = get_var_data(pre1+'sites')   ; the sites for each pixel.
    
    
    bin_size = get_var_data(pre1+'bin_size')
    dmlon_bin = bin_size[0]
    dmlat_bin = bin_size[1]
    x_bins = fix(make_bins(round((mlon_range-mlon_range[0])/dmlon_bin),1))
    y_bins = fix(make_bins(round((mlat_range-mlat_range[0])/dmlat_bin),1))
    px_is = round(px_mlons/dmlon_bin)-x_bins[0]
    px_js = round(px_mlats/dmlat_bin)-y_bins[0]
    
    nx_bin = n_elements(x_bins)
    ny_bin = n_elements(y_bins)
    image_size = [nx_bin,ny_bin]
    cadence = 3d
    times = (n_elements(time) eq 1)? time: make_bins(time,cadence)
    ntime = n_elements(times)
    mosimgs = fltarr([ntime,image_size])
    
    if keyword_set(test) then begin
        window, 0, xsize=image_size[0], ysize=image_size[1]
        loadct, 40
        device, decomposed=0
    endif

    for ii=0, ntime-1 do begin
        mosimg = fltarr(image_size)
        moscnt = intarr(image_size)
        
        ; Fill in the pixels by sites.
        for jj=0, nsite-1 do begin
            pre0 = 'thg_'+sites[jj]+'_asf_'
            timg = get_var_data(pre0+'mlon_image_norm', at=times[ii])
            tmlons = get_var_data(pre0+'new_mlon_bins')
            tmlats = get_var_data(pre0+'new_mlat_bins')
            televs = get_var_data(pre0+'new_elevs')
            
            ; Filter by elevation.
            min_elev = min_elevs[jj]
            index = where(televs le min_elev, count)
            if count ne 0 then begin
                timg[index] = 0
                televs[index] = min_elev
            endif
            
            tcnt = intarr(size(timg,/dimensions))
            index = where(timg ne 0, count)
            if count ne 0 then tcnt[index] = 1    ; only count the good pixels.

            ; Crop the image from a site and paste it to the mosaic.
            a1 = 0
            a2 = n_elements(tmlons)-1
            b1 = 0
            b2 = n_elements(tmlats)-1
            
            i1 = round((tmlons[0]-mlon_range[0])/dmlon_bin)
            j1 = round((tmlats[0]-mlat_range[0])/dmlat_bin)
            i2 = i1+a2
            j2 = j1+b2
            
            if i1 lt 0 then begin
                a1 = a1+(0-i1)
                i1 = 0
            endif
            if i2 gt image_size[0]-1 then begin
                a2 = a2+(image_size[0]-1-i2)
                i2 = image_size[0]-1
            endif
            if j1 lt 0 then begin
                b1 = b1+(0-j1)
                j1 = 0
            endif
            if j2 gt image_size[1]-1 then begin
                b2 = b2+(image_size[1]-1-j2)
                j2 = image_size[1]-1
            endif
            mosimg[i1:i2,j1:j2] += timg[a1:a2,b1:b2]
            moscnt[i1:i2,j1:j2] += tcnt[a1:a2,b1:b2]
        endfor

        
        ; Treat the overlapping points.
        
        
        if keyword_set(test) then begin
            tv, bytscl(mosimg, max=700, top=254)
            wait, 0.05
        endif
        
        mosimgs[ii,*,*] = mosimg
    endfor

    store_data, 'thg_mlonimg', times, mosimgs
    stop
    mosinfo = {$
        mlon_bins:mlon_range[0]+x_bins*dmlon_bin, $
        mlat_bins:mlat_range[0]+y_bins*dmlat_bin, $
        nmlon_bin:nx_bin, $
        nmlat_bin:ny_bin}
    store_data, 'thg_mlonimg_info', 0, mosinfo
end


time = time_double(['2014-08-28/10:05','2014-08-28/10:15'])
sites = ['whit','fsim']
min_elevs = [5,10]
mlon_range = [-100,-55]
mlat_range = [55,75]
renew_file = 0

time = time_double(['2014-08-28/05:00','2014-08-28/05:07'])
time = time_double(['2014-08-28/04:55','2014-08-28/05:07'])
;time = time_double(['2014-08-28/05:05','2014-08-28/05:06'])
sites = ['pina','kapu','snkq']
min_elevs = [5,10,10]
mlon_range = [-50,10]
mlat_range = [55,75]
renew_file = 0

themis_read_mlonimg, time, sites=sites, min_elevs=min_elevs, $
    mlon_range=mlon_range, mlat_range=mlat_range, renew_file=renew_file


end
