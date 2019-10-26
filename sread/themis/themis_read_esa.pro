;+
; Read Themis ESA data.
;-

pro themis_read_esa, time, id=datatype, probe=probe, $
    print_datatype=print_datatype, errmsg=errmsg, $
    local_files=files, file_times=file_times, version=version, $
    local_root=local_root, remote_root=remote_root

    compile_opt idl2
    on_error, 0
    errmsg = ''

;---Check inputs.
    sync_threshold = 86400d*120
    if n_elements(probe) eq 0 then probe = 'x'
    if n_elements(local_root) eq 0 then local_root = join_path([default_local_root(),'data','themis'])
    if n_elements(remote_root) eq 0 then remote_root = 'https://cdaweb.sci.gsfc.nasa.gov/pub/data/themis'
    if n_elements(version) eq 0 then version = 'v[0-9]{2}'

;---Init settings.
    type_dispatch = hash()
    thx = 'th'+probe
    ; Level 2.
    valid_range = ['2007-03-07']    ; the start date applies to tha-the.
    base_name = thx+'_l2_esa_%Y%m%d_'+version+'.cdf'
    local_path = [local_root,thx,'l2','esa','%Y']
    remote_path = [remote_root,thx,'l2','esa','%Y']
    type_dispatch['l2%ele_n'] = dictionary($
        'pattern', dictionary($
            'local_file', join_path([local_path,base_name]), $
            'local_index_file', join_path([local_path,default_index_file(/sync)]), $
            'remote_file', join_path([remote_path,base_name]), $
            'remote_index_file', join_path([remote_path,''])), $
        'valid_range', time_double(valid_range), $
        'cadence', 'day', $
        'extension', 'cdf', $
        'var_list', list($
            dictionary($
                'in_vars', thx+'_peer_density', $
                'out_vars', thx+'_ele_n', $
                'time_var_name', thx+'_peer_time', $
                'time_var_type', 'unix')))
    type_dispatch['l2%ele_t'] = dictionary($
        'pattern', dictionary($
            'local_file', join_path([local_path,base_name]), $
            'local_index_file', join_path([local_path,default_index_file(/sync)]), $
            'remote_file', join_path([remote_path,base_name]), $
            'remote_index_file', join_path([remote_path,''])), $
        'valid_range', time_double(valid_range), $
        'cadence', 'day', $
        'extension', 'cdf', $
        'var_list', list($
            dictionary($
                'in_vars', thx+'_peer_avgtemp', $
                'out_vars', thx+'_ele_t', $
                'time_var_name', thx+'_peer_time', $
                'time_var_type', 'unix')))
    type_dispatch['l2%ion_t'] = dictionary($
        'pattern', dictionary($
            'local_file', join_path([local_path,base_name]), $
            'local_index_file', join_path([local_path,default_index_file(/sync)]), $
            'remote_file', join_path([remote_path,base_name]), $
            'remote_index_file', join_path([remote_path,''])), $
        'valid_range', time_double(valid_range), $
        'cadence', 'day', $
        'extension', 'cdf', $
        'var_list', list($
            dictionary($
                'in_vars', thx+'_peir_avgtemp', $
                'out_vars', thx+'_ion_t', $
                'time_var_name', thx+'_peir_time', $
                'time_var_type', 'unix')))
    type_dispatch['l2%ion_u_gsm'] = dictionary($
        'pattern', dictionary($
            'local_file', join_path([local_path,base_name]), $
            'local_index_file', join_path([local_path,default_index_file(/sync)]), $
            'remote_file', join_path([remote_path,base_name]), $
            'remote_index_file', join_path([remote_path,''])), $
        'valid_range', time_double(valid_range), $
        'cadence', 'day', $
        'extension', 'cdf', $
        'var_list', list($
            dictionary($
                'in_vars', thx+'_peir_velocity_gsm', $
                'out_vars', thx+'_u_gsm', $
                'time_var_name', thx+'_peir_time', $
                'time_var_type', 'unix')))

    if keyword_set(print_datatype) then begin
        print, 'Suported data type: '
        ids = type_dispatch.keys()
        foreach id, ids do print, '  * '+id
        return
    endif


;---Dispatch patterns.
    if n_elements(datatype) eq 0 then begin
        errmsg = handle_error('No input datatype ...')
        return
    endif
    if not type_dispatch.haskey(datatype) then begin
        errmsg = handle_error('Do not support type '+datatype+' yet ...')
        return
    endif
    request = type_dispatch[datatype]

;---Find files, read variables, and store them in memory.
    files = prepare_files(request=request, errmsg=errmsg, local_files=files, $
        file_times=file_times, time=time, nonexist_files=nonexist_files)

;---Read data from files and save to memory.
    read_files, time, files=files, request=request

end
