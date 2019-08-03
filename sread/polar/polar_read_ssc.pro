;+
; Read Polar orbit, attitude, platform attitude, spin phase.
;-

pro polar_read_ssc, time, id=datatype, $
    print_datatype=print_datatype, errmsg=errmsg, $
    local_files=files, file_times=file_times, version=version, $
    local_root=local_root, remote_root=remote_root, $
    in_vars=in_vars, out_vars=out_vars

    compile_opt idl2
    on_error, 0
    errmsg = ''

;---Check inputs.
    sync_threshold = 0
    if n_elements(probe) eq 0 then probe = 'x'
    if n_elements(local_root) eq 0 then local_root = join_path([default_local_root(),'data','polar','orbit'])
    if n_elements(remote_root) eq 0 then remote_root = 'https://cdaweb.sci.gsfc.nasa.gov/pub/data/polar/orbit'
    if n_elements(version) eq 0 then version = 'v[0-9]{2}'

;---Init settings.
    type_dispatch = hash()
    index_file = 'SHA1SUM'
    ; Predicted orbit.
    base_name = 'po_or_pre_%Y%m%d_'+version+'.cdf'
    local_path = [local_root,'pre_or','%Y']
    remote_path = [remote_root,'pre_or','%Y']
    valid_range = ['1996-02-27','2008-06-15']
    type_dispatch['or_pre'] = dictionary($
        'pattern', dictionary($
            'local_file', join_path([local_path,base_name]), $
            'local_index_file', join_path([local_path,index_file]), $
            'remote_file', join_path([remote_path,base_name]), $
            'remote_index_file', join_path([remote_path,index_file])), $
        'sync_threshold', sync_threshold, $
        'valid_range', time_double(valid_range), $
        'cadence', 'day', $
        'extension', fgetext(base_name), $
        'var_list', list($
            dictionary($
                'in_vars', ['GSM_POS','EDMLT_TIME','L_SHELL','MAG_LATITUDE'], $
                'time_var_name', 'Epoch', $
                'time_var_type', 'epoch')))
    ; Definitive orbit.
    base_name = 'po_or_def_%Y%m%d_'+version+'.cdf'
    local_path = [local_root,'def_or','%Y']
    remote_path = [remote_root,'def_or','%Y']
    valid_range = ['1996-02-27','1997-07-16']
    type_dispatch['or_def'] = dictionary($
        'pattern', dictionary($
            'local_file', join_path([local_path,base_name]), $
            'local_index_file', join_path([local_path,index_file]), $
            'remote_file', join_path([remote_path,base_name]), $
            'remote_index_file', join_path([remote_path,index_file])), $
        'sync_threshold', sync_threshold, $
        'valid_range', time_double(valid_range), $
        'cadence', 'day', $
        'extension', fgetext(base_name), $
        'var_list', list($
            dictionary($
                'in_vars', ['GSM_POS','EDMLT_TIME','L_SHELL','MAG_LATITUDE'], $
                'time_var_name', 'Epoch', $
                'time_var_type', 'epoch')))
    ; Predicted attitude.
    base_name = 'po_at_pre_%Y%m%d_'+version+'.cdf'
    local_path = [local_root,'pre_at','%Y']
    remote_path = [remote_root,'pre_at','%Y']
    valid_range = ['1996-03-08','2008-06-15']
    type_dispatch['at_pre'] = dictionary($
        'pattern', dictionary($
            'local_file', join_path([local_path,base_name]), $
            'local_index_file', join_path([local_path,index_file]), $
            'remote_file', join_path([remote_path,base_name]), $
            'remote_index_file', join_path([remote_path,index_file])), $
        'sync_threshold', sync_threshold, $
        'valid_range', time_double(valid_range), $
        'cadence', 'day', $
        'extension', fgetext(base_name), $
        'var_list', list($
            dictionary($
                'in_vars', ['GCI_R_ASCENSION','GCI_DECLINATION'], $
                'time_var_name', 'Epoch', $
                'time_var_type', 'epoch')))
    ; Definitive attitude.
    base_name = 'po_at_def_%Y%m%d_'+version+'.cdf'
    local_path = [local_root,'def_at','%Y']
    remote_path = [remote_root,'def_at','%Y']
    valid_range = ['1996-02-24','1997-07-16']
    type_dispatch['at_def'] = dictionary($
        'pattern', dictionary($
            'local_file', join_path([local_path,base_name]), $
            'local_index_file', join_path([local_path,index_file]), $
            'remote_file', join_path([remote_path,base_name]), $
            'remote_index_file', join_path([remote_path,index_file])), $
        'sync_threshold', sync_threshold, $
        'valid_range', time_double(valid_range), $
        'cadence', 'day', $
        'extension', fgetext(base_name), $
        'var_list', list($
            dictionary($
                'in_vars', ['GCI_R_ASCENSION','GCI_DECLINATION'], $
                'time_var_name', 'Epoch', $
                'time_var_type', 'epoch')))
    ; Platform attitude.
    base_name = 'po_pa_def_%Y%m%d_'+version+'.cdf'
    local_path = [local_root,'def_pa','%Y']
    remote_path = [remote_root,'def_pa','%Y']
    valid_range = ['1996-03-15','2008-04-29']
    type_dispatch['pa'] = dictionary($
        'pattern', dictionary($
            'local_file', join_path([local_path,base_name]), $
            'local_index_file', join_path([local_path,index_file]), $
            'remote_file', join_path([remote_path,base_name]), $
            'remote_index_file', join_path([remote_path,index_file])), $
        'sync_threshold', sync_threshold, $
        'valid_range', time_double(valid_range), $
        'cadence', 'day', $
        'extension', fgetext(base_name), $
        'var_list', list($
            dictionary($
                'in_vars', ['DSP_ANGLE'], $
                'time_var_name', 'Epoch', $
                'time_var_type', 'epoch')))
    ; Spin phase.
    base_name = 'po_k0_spha_%Y%m%d_'+version+'.cdf'
    local_path = [local_root,'spha_k0','%Y']
    remote_path = [remote_root,'spha_k0','%Y']
    valid_range = ['1996-01-25','2008-04-29']
    type_dispatch['spha'] = dictionary($
        'pattern', dictionary($
            'local_file', join_path([local_path,base_name]), $
            'local_index_file', join_path([local_path,index_file]), $
            'remote_file', join_path([remote_path,base_name]), $
            'remote_index_file', join_path([remote_path,index_file])), $
        'sync_threshold', sync_threshold, $
        'valid_range', time_double(valid_range), $
        'cadence', 'day', $
        'extension', fgetext(base_name), $
        'var_list', list($
            dictionary($
                'in_vars', ['SPIN_PHASE','AVG_SPIN_RATE','STNDEV_SPIN_RATE'], $
                'time_var_name', 'Epoch', $
                'time_var_type', 'epoch')))

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
    if n_elements(in_vars) ne 0 then begin
        var_list = request.var_list[0]
        var_list.in_vars = in_vars
        if n_elements(out_vars) eq n_elements(in_vars) then var_list.out_vars = out_vars
        request.var_list = list(var_list)
    endif
    files = prepare_files(request=request, errmsg=errmsg, local_files=files, $
        file_times=file_times, time=time, nonexist_files=nonexist_files)

;---Read data from files and save to memory.
    read_files, time, files=files, request=request, errmsg=errmsg

end

utr0 = time_double(['2007-09-23','2007-09-24'])
foreach id, ['or_def','or_pre','at_def','at_pre','pa','spha'] do begin
    polar_read_ssc, utr0, id=id, errmsg=errmsg
    stop
endforeach

end
