;+
; Reads MLT image for given sites and time. This is a higher level program
; than themis_gen_mltimg_per_site and themis_read_mltimg_per_site.
;-
;
pro themis_read_mltimg, time, vars=vars, id=id, sites=sites, errmsg=errmsg, $
    local_root=local_root, version=version, renew=renew, _extra=extra

    compile_opt idl2
    on_error, 0
    errmsg = ''
    
;---Check inputs.
    if n_elements(time) eq 0 then begin
        errmsg = handle_error('No input time ...')
        return
    endif
    
    nsite = n_elements(sites)
    if nsite eq 0 then begin
        sites = themis_asi_sites()
        nsite = n_elements(sites)
    endif
    
    if n_elements(version) eq 0 then version = 'v01'
    if n_elements(local_root) eq 0 then local_root = join_path([default_local_root(),'sdata','themis'])

    cadence = 3600d ; sec, 1-hour cadence.
    
;---Get data for each site.
;    foreach site, sites do begin
;        lprmsg, 'Processing '+site+' ...'
;        base_pattern = 'thg_l1_mltimg_'+site+'_%Y%m%d%H_'+version+'.cdf'
;        local_path = join_path([local_root,'thg','l1','mltimg',site,'%Y','%m'])
;        file_times = break_down_times(time, cadence)
;        files = []
;        pre0 = 'thg_'+site+'_mltimg_'
;        
;        ; Generate the file if it is not found.
;        foreach file_time, file_times do begin
;            local_dir = apply_time_to_pattern(local_path, file_time)
;            base_name = apply_time_to_pattern(base_pattern, file_time)
;            file = join_path([local_dir,base_name])
;            file_exist = file_test(file)
;            if keyword_set(renew) or ~file_exist then begin
;                themis_gen_mltimg_per_site, file_time, site=site, errmsg=errmsg, _extra=extra
;                if errmsg ne '' then continue
;            endif
;            files = [files,file]
;        endforeach
;        
;        ; Read the MLT image per site.
;        in_vars = ['pixel_index','pixel_value','pixel_elev']
;        out_vars = pre0+in_vars
;        read_and_store_var, files, time_info=time, errmsg=errmsg, $
;            in_vars=in_vars, out_vars=out_vars, time_var_name='ut_sec', time_var_type='unix'
;    endforeach
    
    
;---Merge MLT images from the sites.
    image_size = [768,768]
    if n_elements(time) eq 1 then times = time else begin
        cadence0 = 3d   ; sec.
        times = time-(time mod cadence0)
        times = smkarthm(times[0], times[1], cadence0, 'dx')
    endelse
    ntime = n_elements(times)
    ;ptr_mltimg = ptrarr(ntime)
    for i=0, ntime-1 do begin
        ut0 = times[i]
        mltimgs = fltarr([image_size,nsite])
        for j=0, nsite-1 do begin
            pre0 = 'thg_'+sites[j]+'_mltimg_'
            get_data, pre0+'pixel_elev', uts, pixel_elevs
            index = where(abs(uts-ut0) lt cadence0, count)
            if count eq 0 then continue
            pixel_elevs = reform(pixel_elevs[index,*])
            pixel_values = reform((get_var_data(pre0+'pixel_value'))[index,*])
            pixel_indices = reform((get_var_data(pre0+'pixel_index'))[index,*])
            
            ; filter.
            min_elev = 8
            index = where(pixel_elevs le min_elev)
            pixel_values[index] = 0
            min_value = 20
            index = where(pixel_values le min_value)
            pixel_values[index] = 0
            
            index = where(pixel_values gt 0)
            mltimgs[*,*,j] = themis_asi_unzip_mltimg({$
                index:temporary(pixel_indices[index]), $
                value:temporary(pixel_values[index]), $
                elev:temporary(pixel_elevs[index]), $
                image_size:image_size})
           ;print, sites[j]+' has data ...'
        endfor
        
        mltimg = total(mltimgs,3)
        mltimg = bytscl(mltimg, min=10, max=500, top=254)

        tv, mltimg, 0
        xyouts, 0,0, /device, color=255, time_string(times[i],tformat='YYYY-MM-DD/hh:mm:ss')
    endfor
    
end

time = time_double(['2014-08-28/10:05','2014-08-28/10:15'])
sites = ['whit','fsim']

time = time_double(['2014-08-28/04:55','2014-08-28/05:00'])
sites = ['atha','fsmi','pina','gill','rank','kapu','snkq','kuuj','gbay','nrsq']
sites = ['atha','pina','gill','kapu','snkq','kuuj','gbay']

themis_read_mltimg, time, sites=sites
end