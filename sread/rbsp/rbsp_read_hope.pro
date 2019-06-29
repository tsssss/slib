;+
; Read RBSP HOPE data.
;-

pro rbsp_read_hope, time, id=datatype, probe=probe, $
    release=release, $
    print_datatype=print_datatype, errmsg=errmsg, $
    in_vars=in_vars, out_vars=out_vars, files=files, version=version, $
    local_root=local_root, remote_root=remote_root, $
    sync_after=sync_after, file_times=file_times, index_file=index_file, skip_index=skip_index, $
    sync_index=sync_index, sync_files=sync_files, stay_local=stay_loca, $
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


;--Default settings.
    if n_elements(local_root) eq 0 then local_root = join_path([default_local_root(),'data','rbsp'])
    if n_elements(remote_root) eq 0 then remote_root = 'https://cdaweb.gsfc.nasa.gov/pub/data/rbsp'
    if n_elements(version) eq 0 then version = 'v[0-9.]{5}'
    if n_elements(index_file) eq 0 then index_file = default_index_file()
    if n_elements(release) eq 0 then release = 'rel04'  ; updated 2019-06.

    type_dispatch = hash()
    ; Level 3 data.
    type_dispatch['l3%pa%electron'] = dictionary($
        'base_pattern', 'rbsp'+probe+'_'+release+'_ect-hope-pa-l3_%Y%m%d_'+version+'.cdf', $
        'remote_paths', [remote_root,'rbsp'+probe,'l3','ect','hope','pitchangle',release,'%Y'], $
        'local_paths', [local_root,'rbsp'+probe,'hope','level3','pa_'+release,'%Y'], $
        'in_vars', ['Epoch_Ele_DELTA','HOPE_ENERGY_Ele','FEDU'], $
        'out_vars', ['epoch_ele_delta','hope_energy_ele','fedu'], $
        'time_var_name', 'Epoch_Ele', $
        'time_var_type', 'Epoch', $
        'generic_time', 0, $
        'cadence', 'day')
    type_dispatch['l3%pa%ion'] = dictionary($
        'base_pattern', 'rbsp'+probe+'_'+release+'_ect-hope-pa-l3_%Y%m%d_'+version+'.cdf', $
        'remote_paths', [remote_root,'rbsp'+probe,'l3','ect','hope','pitchangle',release,'%Y'], $
        'local_paths', [local_root,'rbsp'+probe,'hope','level3','pa_'+release,'%Y'], $
        'in_vars', ['Epoch_Ion_DELTA','HOPE_ENERGY_Ion','FPDU','FODU','FHEDU'], $
        'out_vars', ['epoch_ion_delta','hope_energy_ion','fpdu','fodu','fhedu'], $
        'time_var_name', 'Epoch_Ion', $
        'time_var_type', 'Epoch', $
        'generic_time', 0, $
        'cadence', 'day')
    type_dispatch['l3%pa%misc'] = dictionary($
        'base_pattern', 'rbsp'+probe+'_'+release+'_ect-hope-pa-l3_%Y%m%d_'+version+'.cdf', $
        'remote_paths', [remote_root,'rbsp'+probe,'l3','ect','hope','pitchangle',release,'%Y'], $
        'local_paths', [local_root,'rbsp'+probe,'hope','level3','pa_'+release,'%Y'], $
        'in_vars', ['PITCH_ANGLE'], $
        'out_vars', ['pitch_angle'], $
        'time_var_name', '', $
        'time_var_type', '', $
        'generic_time', 1, $
        'cadence', 'day')
    ; Level 2 data.
    type_dispatch['l2%electron'] = dictionary($
        'base_pattern', 'rbsp'+probe+'_'+release+'_ect-hope-sci-l2_%Y%m%d_'+version+'.cdf', $
        'remote_paths', [remote_root,'rbsp'+probe,'l2','ect','hope','sectors',release,'%Y'], $
        'local_paths', [local_root,'rbsp'+probe,'hope','level2','sectors_'+release,'%Y'], $
        'in_vars', ['Epoch_Ele_DELTA','HOPE_ENERGY_Ele','FEDU'], $
        'out_vars', ['epoch_ele_delta','hope_energy_ele','fedu'], $
        'time_var_name', 'Epoch_Ele', $
        'time_var_type', 'Epoch', $
        'generic_time', 0, $
        'cadence', 'day')
    type_dispatch['l2%ion'] = dictionary($
        'base_pattern', 'rbsp'+probe+'_'+release+'_ect-hope-sci-l2_%Y%m%d_'+version+'.cdf', $
        'remote_paths', [remote_root,'rbsp'+probe,'l2','ect','hope','sectors',release,'%Y'], $
        'local_paths', [local_root,'rbsp'+probe,'hope','level2','sectors_'+release,'%Y'], $
        'in_vars', ['Epoch_Ion_DELTA','HOPE_ENERGY_Ion','FPDU','FODU','FHEDU'], $
        'out_vars', ['epoch_ion_delta','hope_energy_ion','fpdu','fodu','fhedu'], $
        'time_var_name', 'Epoch_Ion', $
        'time_var_type', 'Epoch', $
        'generic_time', 0, $
        'cadence', 'day')
    type_dispatch['l2%misc'] = dictionary($
        'base_pattern', 'rbsp'+probe+'_'+release+'_ect-hope-sci-l2_%Y%m%d_'+version+'.cdf', $
        'remote_paths', [remote_root,'rbsp'+probe,'l2','ect','hope','sectors',release,'%Y'], $
        'local_paths', [local_root,'rbsp'+probe,'hope','level2','sectors_'+release,'%Y'], $
        'in_vars', ['Sector_Collapse_Cntr','Energy_Collapsed','Epoch'], $
        'out_vars', ['sector_collapse_cntr','energy_collapsed','epoch'], $
        'time_var_name', '', $
        'time_var_type', '', $
        'generic_time', 1, $
        'cadence', 'day')

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
    myinfo = (type_dispatch[datatype]).tostruct()
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

    in_vars = myinfo.in_vars
    out_vars = myinfo.out_vars
    read_and_store_var, files, time_info=time, errmsg=errmsg, $
        in_vars=in_vars, out_vars=out_vars, generic_time=generic_time, _extra=myinfo
    if errmsg ne '' then begin
        errmsg = handle_error('Error in reading or storing data ...')
        return
    endif


end


time = time_double(['2013-03-14/00:00','2013-03-14/00:10'])
probe = 'a'
;rbsp_read_hope, time, id='l2%rel03%ion', probe=probe
rbsp_read_hope, time, id='l2%electron', probe=probe
rbsp_read_hope, time, id='l2%misc', probe=probe
end
