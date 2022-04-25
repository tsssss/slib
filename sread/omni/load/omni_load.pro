;+
; Return omni files for a given time range.
;-
function omni_load, input_time_range, id=datatype, $
    print_datatype=print_datatype, errmsg=errmsg, $
    local_files=files, file_times=file_times, version=version, $
    local_root=local_root

    compile_opt idl2
    on_error, 0
    errmsg = ''

;---Check inputs.
    sync_threshold = 86400d*120
    if n_elements(remote_root) eq 0 then remote_root = 'https://cdaweb.gsfc.nasa.gov/pub/data/omni/omni_cdaweb'
    if n_elements(local_root) eq 0 then local_root = join_path([default_local_root(),'omni'])
    if n_elements(version) eq 0 then version = 'v[0-9]{2}'
    if n_elements(datatype) eq 0 then datatype = 'cdaweb%hro2%1min'

    if size(input_time_range[0],type=1) eq 7 then begin
        time_range = time_double(input_time_range)
    endif else begin
        time_range = input_time_range
    endelse


;---Init settings.
    type_dispatch = hash()
    ; hourly. one file for 6 months.
    valid_range = omni_valid_range('cdaweb%hourly')
    base_name = 'omni2_h0_mrg1hr_%Y%m01_'+version+'.cdf'
    remote_path = [remote_root,'hourly','%Y']
    local_path = [local_root,'hourly','%Y']
    type_dispatch['cdaweb%hourly'] = dictionary($
        'pattern', dictionary($
            'remote_file', join_path([remote_path,base_name]), $
            'remote_index_file', join_path([remote_path,'']), $
            'local_file', join_path([local_path,base_name]), $
            'local_index_file', join_path([local_path,default_index_file(/sync)])), $
        'valid_range', time_double(valid_range), $
        'sync_threshold', sync_threshold, $
        'cadence', 'month', $
        'extension', fgetext(base_name) )

    ; hro%1min.
    valid_range = omni_valid_range('cdaweb%hro%1min')
    base_name = 'omni_hro_1min_%Y%m01_'+version+'.cdf'
    remote_path = [remote_root,'hro_1min','%Y']
    local_path = [local_root,'hro_1min','%Y']
    type_dispatch['cdaweb%hro%1min'] = dictionary($
        'pattern', dictionary($
            'remote_file', join_path([remote_path,base_name]), $
            'remote_index_file', join_path([remote_path,'']), $
            'local_file', join_path([local_path,base_name]), $
            'local_index_file', join_path([local_path,default_index_file(/sync)])), $
        'valid_range', time_double(valid_range), $
        'sync_threshold', sync_threshold, $
        'cadence', 'month', $
        'extension', fgetext(base_name) )


    ; hro%5min.
    valid_range = omni_valid_range('cdaweb%hro%5min')
    base_name = 'omni_hro_5min_%Y%m01_'+version+'.cdf'
    remote_path = [remote_root,'hro_5min','%Y']
    local_path = [local_root,'hro_5min','%Y']
    type_dispatch['cdaweb%hro%5min'] = dictionary($
        'pattern', dictionary($
            'remote_file', join_path([remote_path,base_name]), $
            'remote_index_file', join_path([remote_path,'']), $
            'local_file', join_path([local_path,base_name]), $
            'local_index_file', join_path([local_path,default_index_file(/sync)])), $
        'valid_range', time_double(valid_range), $
        'sync_threshold', sync_threshold, $
        'cadence', 'month', $
        'extension', fgetext(base_name) )
    
    ; hro2%1min.
    valid_range = omni_valid_range('cdaweb%hro2%1min')
    base_name = 'omni_hro2_1min_%Y%m01_'+version+'.cdf'
    remote_path = [remote_root,'hro2_1min','%Y']
    local_path = [local_root,'hro2_1min','%Y']
    type_dispatch['cdaweb%hro2%1min'] = dictionary($
        'pattern', dictionary($
            'remote_file', join_path([remote_path,base_name]), $
            'remote_index_file', join_path([remote_path,'']), $
            'local_file', join_path([local_path,base_name]), $
            'local_index_file', join_path([local_path,default_index_file(/sync)])), $
        'valid_range', time_double(valid_range), $
        'sync_threshold', sync_threshold, $
        'cadence', 'month', $
        'extension', fgetext(base_name) )

    ; hro2%5min.
    valid_range = omni_valid_range('cdaweb%hro2%5min')
    base_name = 'omni_hro2_5min_%Y%m01_'+version+'.cdf'
    remote_path = [remote_root,'hro2_5min','%Y']
    local_path = [local_root,'hro2_5min','%Y']
    type_dispatch['cdaweb%hro2%5min'] = dictionary($
        'pattern', dictionary($
            'remote_file', join_path([remote_path,base_name]), $
            'remote_index_file', join_path([remote_path,'']), $
            'local_file', join_path([local_path,base_name]), $
            'local_index_file', join_path([local_path,default_index_file(/sync)])), $
        'valid_range', time_double(valid_range), $
        'sync_threshold', sync_threshold, $
        'cadence', 'month', $
        'extension', fgetext(base_name) )

;---Dispatch patterns.
    if n_elements(datatype) eq 0 then begin
        errmsg = handle_error('No input datatype ...')
        return, ''
    endif
    if not type_dispatch.haskey(datatype) then begin
        errmsg = handle_error('Do not support type '+datatype+' yet ...')
        return, ''
    endif
    request = type_dispatch[datatype]

;---Find files, read variables, and store them in memory.
    files = prepare_files(request=request, errmsg=errmsg, local_files=files, $
        file_times=file_times, time=time_range, nonexist_files=nonexist_files)
    
    if n_elements(files) eq 0 then return, '' else return, files

end



time_range = time_double(['2013-01-01','2014-01-01'])
;files = omni_load(time_range, id='cdaweb%hourly')
files = omni_load(time_range, id='cdaweb%hro2%1min')
end
