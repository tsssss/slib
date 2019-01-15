;+
; Read Polar orbit, attitude, platform attitude, spin phase.
;-

pro polar_read_ssc, time, datatype, print_datatype=print_datatype, $
    variable=vars, files=files, level=level, version=version, id=id, errmsg=errmsg
    
    compile_opt idl2
    on_error, 0
    errmsg = ''
    
    nfile = n_elements(files)
    if n_elements(time) eq 0 and nfile eq 0 then begin
        message, 'no time or file is given ...', /continue
        if not keyword_set(print_datatype) then return
    endif

    loc_root = join_path([sdiskdir('Research'),'data','polar','orbit'])
    rem_root = 'https://cdaweb.sci.gsfc.nasa.gov/pub/data/polar/orbit'
    version = (n_elements(version) eq 0)? 'v[0-9]{2}': version

    type_dispatch = []
    type_dispatch = [type_dispatch, $
        {id: 'or_pre', $
        base_pattern: 'po_or_pre_%Y%m%d_'+version+'.cdf', $
        remote_pattern: join_path([rem_root,'pre_or','%Y']), $
        local_pattern: join_path([loc_root,'pre_or','%Y']), $
        variable: ptr_new(['Epoch','GSE_POS','EDMLT_TIME','L_SHELL']), $
        time_var: 'Epoch', $
        time_type: 'epoch'}]
    type_dispatch = [type_dispatch, $
        {id: 'or_def', $
        base_pattern: 'po_or_def_%Y%m%d_'+version+'.cdf', $
        remote_pattern: join_path([rem_root,'def_or','%Y']), $
        local_pattern: join_path([loc_root,'def_or','%Y']), $
        variable: ptr_new(['Epoch','GSE_POS','EDMLT_TIME','L_SHELL']), $
        time_var: 'Epoch', $
        time_type: 'epoch'}]
    type_dispatch = [type_dispatch, $
        {id:'at_pre', $
        base_pattern: 'po_at_pre_%Y%m%d_'+version+'.cdf', $
        remote_pattern: join_path([rem_root,'pre_at','%Y']), $
        local_pattern: join_path([loc_root,'pre_at','%Y']), $
        variable: ptr_new(['Epoch','GCI_R_ASCENSION','GCI_DECLINATION']), $
        time_var: 'Epoch', $
        time_type: 'epoch'}]
    type_dispatch = [type_dispatch, $
        {id:'at_def', $
        base_pattern: 'po_at_def_%Y%m%d_'+version+'.cdf', $
        remote_pattern: join_path([rem_root,'def_at','%Y']), $
        local_pattern: join_path([loc_root,'def_at','%Y']), $
        variable: ptr_new(['Epoch','GCI_R_ASCENSION','GCI_DECLINATION']), $
        time_var: 'Epoch', $
        time_type: 'epoch'}]
    type_dispatch = [type_dispatch, $
        {id:'pa', $
        base_pattern: 'po_pa_def_%Y%m%d_'+version+'.cdf', $
        remote_pattern: join_path([rem_root,'def_pa','%Y']), $
        local_pattern: join_path([loc_root,'def_pa','%Y']), $
        variable: ptr_new(['Epoch','DSP_ANGLE']), $
        time_var: 'Epoch', $
        time_type: 'epoch'}]
    type_dispatch = [type_dispatch, $
        {id:'spha', $
        base_pattern: 'po_k0_spha_%Y%m%d_'+version+'.cdf', $
        remote_pattern: join_path([rem_root,'spha_k0','%Y']), $
        local_pattern: join_path([loc_root,'spha_k0','%Y']), $
        variable: ptr_new(['Epoch','SPIN_PHASE','AVG_SPIN_RATE','STNDEV_SPIN_RATE']), $
        time_var: 'Epoch', $
        time_type: 'epoch'}]
    if keyword_set(print_datatype) then begin
        print, 'Suported data type: '
        ids = type_dispatch.id
        foreach tid, ids do print, '  * '+tid
        return
    endif

    ; dispatch patterns.
    if n_elements(id) eq 0 then id = strjoin([datatype],'%')
    ids = type_dispatch.id
    idx = where(ids eq id, cnt)
    if cnt eq 0 then message, 'Do not support type '+id+' yet ...'
    myinfo = type_dispatch[idx[0]]

    ; find files to be read.
    file_cadence = 86400.
    if nfile eq 0 then begin
        update_t_threshold = 365.25d*86400  ; 1 year.
        index_file = 'SHA1SUM'
        times = break_down_times(time, file_cadence)
        patterns = [myinfo.base_pattern, myinfo.local_pattern, myinfo.remote_pattern]
        files = find_data_file(time, patterns, index_file, $
            file_cadence=file_cadence, threshold=update_t_threshold)
    endif
    
    ; no file is found.
    if n_elements(files) eq 1 and files[0] eq '' then begin
        errmsg = 1
        return
    endif

    ; read variables from file.
    if n_elements(vars) eq 0 then vars = *myinfo.variable
    times = make_time_range(time, file_cadence)
    time_type = myinfo.time_type
    time_var = myinfo.time_var
    times = convert_time(times, from='unix', to=time_type)
    read_data_time, files, vars, prefix='', time_var=time_var, times=times, /dum
    if time_type ne 'unix' then fix_time, vars, time_type
end

utr0 = time_double(['2007-09-23','2007-09-24'])
polar_read_ssc, utr0, 'or_def', errmsg=errmsg
print, errmsg
polar_read_ssc, utr0, 'or_pre', errmsg=errmsg
print, errmsg
polar_read_ssc, utr0, 'at_def', errmsg=errmsg
print, errmsg
polar_read_ssc, utr0, 'at_pre', errmsg=errmsg
print, errmsg
polar_read_ssc, utr0, 'pa', errmsg=errmsg
print, errmsg
polar_read_ssc, utr0, 'spha', errmsg=errmsg
print, errmsg
end
