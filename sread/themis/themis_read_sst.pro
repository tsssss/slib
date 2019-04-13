;+
;-

pro themis_read_sst, time, id=datatype, probe=probe, $
    print_datatype=print_datatype, errmsg=errmsg, $
    in_vars=in_vars, out_vars=out_vars, files=files, version=version, $
    local_root=local_root, remote_root=remote_root, $
    sync_after=sync_after, file_times=file_times, index_file=index_file, skip_index=skip_index, $
    sync_index=sync_index, sync_files=sync_files, stay_local=stay_local, $
    time_var_name=time_var_name, time_var_type=time_var_type, generic_time=generic_time

    compile_opt idl2
    on_error, 0
    errmsg = ''


;---Check inputs.
    nfile = n_elements(files)
    if n_elements(time) eq 0 and nfile eq 0 and ~keyword_set(print_datatype) then begin
        errmsg = handle_error('No time or file is given ...')
        return
    endif
    if keyword_set(print_datatype) then probe = 'x'
    if n_elements(probe) eq 0 then begin
        errmsg = handle_error('No input probe ...')
        return
    endif
    if n_elements(out_vars) ne n_elements(in_vars) then out_vars = in_vars

;---Default settings.
    if n_elements(local_root) eq 0 then local_root = join_path([default_local_root(),'data','themis'])
    if n_elements(remote_root) eq 0 then remote_root = 'https://cdaweb.sci.gsfc.nasa.gov/pub/data/themis'
    if n_elements(version) eq 0 then version = 'v[0-9]{2}'
    if n_elements(index_file) eq 0 then index_file = default_index_file()
    thx = 'th'+probe

    type_dispatch = []
    type_dispatch = [type_dispatch, $
        {id: 'l2%e_kev', $
        base_pattern: thx+'_l2_sst_%Y%m%d_'+version+'.cdf', $
        remote_paths: ptr_new([remote_root,thx,'l2','sst','%Y']), $
        local_paths: ptr_new([local_root,thx,'l2','sst','%Y']), $
        ptr_in_vars: ptr_new(thx+'_'+['psef_en_eflux','psef_en_eflux_yaxis']), $
        ptr_out_vars: ptr_new(thx+'_'+['e_flux','e_energy']), $
        time_var_name: thx+'_psef_time', $
        time_var_type: 'unix', $
        generic_time: 0, $
        cadence: 'day', $
        placeholder: 0b}]
    type_dispatch = [type_dispatch, $
        {id: 'l2%h_kev', $
        base_pattern: thx+'_l2_sst_%Y%m%d_'+version+'.cdf', $
        remote_paths: ptr_new([remote_root,thx,'l2','sst','%Y']), $
        local_paths: ptr_new([local_root,thx,'l2','sst','%Y']), $
        ptr_in_vars: ptr_new(thx+'_'+['psif_en_eflux','psif_en_eflux_yaxis']), $
        ptr_out_vars: ptr_new(thx+'_'+['h_flux','h_energy']), $
        time_var_name: thx+'_psif_time', $
        time_var_type: 'unix', $
        generic_time: 0, $
        cadence: 'day', $
        placeholder: 0b}]
    if keyword_set(print_datatype) then begin
        print, 'Suported data type: '
        ids = type_dispatch.id
        foreach id, ids do print, '  * '+id
        return
    endif

;---Dispatch patterns.
    if n_elements(datatype) eq 0 then begin
        errmsg = handle_error('No input datatype ...')
        return
    endif
    ids = type_dispatch.id
    index = where(ids eq datatype, count)
    if count eq 0 then begin
        errmsg = handle_error('Do not support type '+datatype+' yet ...')
        return
    endif
    myinfo = type_dispatch[index[0]]
    if n_elements(time_var_name) ne 0 then myinfo.time_var_name = time_var_name
    if n_elements(time_var_type) ne 0 then myinfo.time_var_type = time_var_type

;---Find files, read variables, and store them in memory.
    files = prepare_file(files=files, errmsg=errmsg, $
        file_times=file_times, index_file=index_file, time=time, $
        stay_local=stay_local, sync_index=sync_index, $
        sync_files=sync_files, sync_after=sync_time, $
        skip_index=skip_index, $
        _extra=myinfo)
    if errmsg ne '' then begin
        errmsg = handle_error('Error in finding files ...')
        return
    endif

    read_and_store_var, files, time_info=time, errmsg=errmsg, $
        in_vars=in_vars, out_vars=out_vars, generic_time=generic_time, _extra=myinfo
    if errmsg ne '' then begin
        errmsg = handle_error('Error in reading or storing data ...')
        return
    endif

end

time = time_double(['2014-08-28/09:00','2014-08-28/11:00'])
themis_read_sst, time, probe='d', id='l2%e_kev'
end
