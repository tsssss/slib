;+
;-

pro themis_read_sst, time, id=datatype, probe=probe, $
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
    ; Level 2, electron.
    base_name = thx+'_l2_sst_%Y%m%d_'+version+'.cdf'
    local_path = [local_root,thx,'l2','sst','%Y']
    remote_path = [remote_root,thx,'l2','sst','%Y']
    type_dispatch['l2%e_kev'] = dictionary($
        'pattern', dictionary($
            'local_file', join_path([local_path,base_name]), $
            'local_index_file', join_path([local_path,default_index_file(/sync)]), $
            'remote_file', join_path([remote_path,base_name]), $
            'remote_index_file', join_path([remote_path,''])), $
        'sync_threshold', sync_threshold, $
        'cadence', 'day', $
        'extension', fgetext(base_name), $
        'var_list', list($
            dictionary($
                'in_vars', thx+'_'+['psef_en_eflux','psef_en_eflux_yaxis'], $
                'out_vars', thx+'_'+['e_flux','e_energy'], $
                'time_var_name', thx+'_psif_time', $
                'time_var_type', 'unix')))
    type_dispatch['l2%h_kev'] = dictionary($
        'pattern', dictionary($
            'local_file', join_path([local_path,base_name]), $
            'local_index_file', join_path([local_path,default_index_file(/sync)]), $
            'remote_file', join_path([remote_path,base_name]), $
            'remote_index_file', join_path([remote_path,''])), $
        'sync_threshold', sync_threshold, $
        'cadence', 'day', $
        'extension', fgetext(base_name), $
        'var_list', list($
            dictionary($
                'in_vars', thx+'_'+['psif_en_eflux','psif_en_eflux_yaxis'], $
                'out_vars', thx+'_'+['h_flux','h_energy'], $
                'time_var_name', thx+'_psif_time', $
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

time = time_double(['2014-08-28/09:00','2014-08-28/11:00'])
themis_read_sst, time, probe='d', id='l2%e_kev'
end
