;+
; Load calibrated mlon image.
;-

function themis_load_asf_mlon_image_per_site, input_time_range, site=site, id=datatype, $
    print_datatype=print_datatype, errmsg=errmsg, $
    local_files=files, file_times=file_times, version=version, $
    local_root=local_root, remote_root=remote_root, $
    return_request=return_request, $
    calibration_method=calibration_method
    

    compile_opt idl2
    on_error, 1
    errmsg = ''


;---Check inputs.
    sync_threshold = 1
    if n_elements(site) eq 0 then begin
        errmsg = 'No input site ...'
        return, ''
    endif
    sites = themis_read_asi_sites()
    index = where(sites eq site, count)
    if count eq 0 then begin
        errmsg = 'Invalid site: '+site[0]+' ...'
        return, ''
    endif
    if n_elements(local_root) eq 0 then local_root = join_path([default_local_root(),'sdata','themis'])
    if n_elements(version) eq 0 then version = 'v01'

    if size(input_time_range[1],type=1) eq 7 then begin
        time_range = time_double(input_time_range)
    endif else begin
        time_range = input_time_range
    endelse
    
    if n_elements(calibration_method) eq 0 then calibration_method = 'simple'



;---Init settings.
    type_dispatch = hash()

    ; ASF MLon image calibrated.
    valid_range = [time_double('2008'),systime(1)]
    base_name = 'thg_l3_asf_mlon_image_'+site+'_%Y%m%d%H_'+version+'.cdf'
    if calibration_method eq 'simple' then base_name = 'thg_l3_asf_mlon_image_simple_'+site+'_%Y%m%d%H_'+version+'.cdf'
    local_path = [local_root,'thg','mlon_image',site,'%Y','%m']
    request = dictionary($
        'pattern', dictionary($
            'local_file', join_path([local_path,base_name]), $
            'local_index_file', join_path([local_path,default_index_file(/sync)])), $
        'valid_range', time_double(valid_range), $
        'cadence', 'hour', $
        'extension', fgetext(base_name) )
    if keyword_set(return_request) then return, request

;---Find files, read variables, and store them in memory.
    files = prepare_files(request=request, errmsg=errmsg, local_files=files, $
        file_times=file_times, time=time_range, nonexist_files=nonexist_files)
    if n_elements(nonexist_files) ne 0 then begin
        foreach file, request.nonexist_files do begin
            file_time = file.file_time
            local_file = file.local_file
            themis_load_asf_mlon_image_per_site_gen_file, file_time, site=site, filename=local_file, calibration_method=calibration_method
        endforeach
        files = prepare_files(request=request, errmsg=errmsg, local_files=files, $
            file_times=file_times, time=time_range, nonexist_files=nonexist_files)
    endif

    if n_elements(files) eq 0 then return, '' else return, files

end


time_range = time_double(['2014-03-17/07:00','2013-03-17/09:00'])
sites = ['kian','mcgr','fykn','gako','fsim',$
    'talo','snap','fsmi','tpas','gill','snkq']
foreach site, sites do files = themis_load_asf_mlon_image_per_site(time_range, site=site)
end
