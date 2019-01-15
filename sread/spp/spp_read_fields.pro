;+
;-
;

pro spp_read_fields, time, datatype, probe, level=level, $
    print_datatype=print_datatype, errmsg=errmsg, $
    variable=vars, files=files, version=version, id=id
    
    compile_opt idl2
    on_error, 0
    errmsg = 0
    
    
    nfile = n_elements(files)
    if n_elements(time) eq 0 and nfile eq 0 then begin
        message, 'no time or file is given ...', /continue
        if not keyword_set(print_datatype) then return
    endif
    if keyword_set(print_datatype) then probe = 'x'
    
    
    loc_root = join_path([sdiskdir('Research'),'data','spp','fields'])
    if file_test(loc_root) eq 0 then loc_root = join_path([shomedir(),'data','spp','fields'])
    rem_root = 'http://spfuser:s0larPr0be@sprg.ssl.berkeley.edu/data/spp/data/sci/fields'
    version = (n_elements(version) eq 0)? 'v[0-9]{2}': version
    spp = 'spp'
    
    type_dispatch = []
;---Waveform
    dvars = ['time_unix','wf_pkt_data','wf_pkt_data_v']
    dtypes = 'dfb_wf'+string(findgen(12)+1,format='(I02)')
    foreach dtype, dtypes do $
        type_dispatch = [type_dispatch, $
        {id: 'l1%'+dtype, $
        base_pattern: 'spp_fld_l1_'+dtype+'_%Y%m%d_'+version+'.cdf', $
        remote_pattern: join_path([rem_root,'l1',dtype,'%Y','%m']), $
        local_pattern: join_path([loc_root,'l1',dtype,'%Y','%m']), $
        variable: ptr_new(dvars), $
        time_var: 'time_unix', $
        time_type: 'unix'}]
;---DC magnetic field.
    type_dispatch = [type_dispatch, $
        {id: 'l1%magi_survey', $
        base_pattern: 'spp_fld_l1_magi_survey_%Y%m%d_'+version+'.cdf', $
        remote_pattern: join_path([rem_root,'l1','magi_survey','%Y','%m']), $
        local_pattern: join_path([loc_root,'l1','magi_survey','%Y','%m']), $
        variable: ptr_new(['time_unix','mag_bx_2d','mag_by_2d','mag_bz_2d']), $
        time_var: 'time_unix', $
        time_type: 'unix'}]
    type_dispatch = [type_dispatch, $
        {id: 'l1%mago_survey', $
        base_pattern: 'spp_fld_l1_mago_survey_%Y%m%d_'+version+'.cdf', $
        remote_pattern: join_path([rem_root,'l1','mago_survey','%Y','%m']), $
        local_pattern: join_path([loc_root,'l1','mago_survey','%Y','%m']), $
        variable: ptr_new(['time_unix','mag_bx_2d','mag_by_2d','mag_bz_2d']), $
        time_var: 'time_unix', $
        time_type: 'unix'}]
    type_dispatch = [type_dispatch, $
        {id: 'l1%magi_hk', $
        base_pattern: 'spp_fld_l1_magi_hk_%Y%m%d_'+version+'.cdf', $
        remote_pattern: join_path([rem_root,'l1','magi_hk','%Y','%m']), $
        local_pattern: join_path([loc_root,'l1','magi_hk','%Y','%m']), $
        variable: ptr_new(['time_unix','mag_xtest_raw','mag_ytest_raw','mag_ztest_raw']), $
        time_var: 'time_unix', $
        time_type: 'unix'}]
    type_dispatch = [type_dispatch, $
        {id: 'l1%mago_hk', $
        base_pattern: 'spp_fld_l1_mago_hk_%Y%m%d_'+version+'.cdf', $
        remote_pattern: join_path([rem_root,'l1','mago_hk','%Y','%m']), $
        local_pattern: join_path([loc_root,'l1','mago_hk','%Y','%m']), $
        variable: ptr_new(['time_unix','mag_xtest_raw','mag_ytest_raw','mag_ztest_raw']), $
        time_var: 'time_unix', $
        time_type: 'unix'}]
;---Positions.
    dvars = ['time_unix','position']
    dtype = 'ephem_eclipj2000'
    type_dispatch = [type_dispatch, $
        {id: 'l1%'+dtype, $
        base_pattern: 'spp_fld_l1_'+dtype+'_%Y%m%d_'+version+'.cdf', $
        remote_pattern: join_path([rem_root,'l1',dtype,'%Y','%m']), $
        local_pattern: join_path([loc_root,'l1',dtype,'%Y','%m']), $
        variable: ptr_new(dvars), $
        time_var: 'time_unix', $
        time_type: 'unix'}]
    dtype = 'ephem_spp_rtn'
    type_dispatch = [type_dispatch, $
        {id: 'l1%'+dtype, $
        base_pattern: 'spp_fld_l1_'+dtype+'_%Y%m%d_'+version+'.cdf', $
        remote_pattern: join_path([rem_root,'l1',dtype,'%Y','%m']), $
        local_pattern: join_path([loc_root,'l1',dtype,'%Y','%m']), $
        variable: ptr_new(dvars), $
        time_var: 'time_unix', $
        time_type: 'unix'}]
    dtype = 'ephem_spp_vso'
    type_dispatch = [type_dispatch, $
        {id: 'l1%'+dtype, $
        base_pattern: 'spp_fld_l1_'+dtype+'_%Y%m%d_'+version+'.cdf', $
        remote_pattern: join_path([rem_root,'l1',dtype,'%Y','%m']), $
        local_pattern: join_path([loc_root,'l1',dtype,'%Y','%m']), $
        variable: ptr_new(dvars), $
        time_var: 'time_unix', $
        time_type: 'unix'}]
        
        
    if keyword_set(print_datatype) then begin
        print, 'Suported data type: '
        ids = type_dispatch.id
        foreach id, ids do print, '  * '+id
        return
    endif
    
    
    ; dispatch patterns.
    if n_elements(id) eq 0 then id = strjoin([level,datatype],'%')
    ids = type_dispatch.id
    idx = where(ids eq id, cnt)
    if cnt eq 0 then message, 'Do not support type '+id+' yet ...'
    myinfo = type_dispatch[idx[0]]
    
    ; find files to be read.
    file_cadence = 86400.
    if nfile eq 0 then begin
        update_t_threshold = 0  ; avoid checking remote.
        index_file = 'remote-index.html'
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
    idx = where(vars ne time_var)
    foreach var, vars[idx] do treat_fillval, var
    if time_type ne 'unix' then fix_time, vars, time_type
    
    
end

utr0 = time_double(['2018-09-19','2018-09-21'])
spp_read_fields, utr0, 'dfb_wf02', level='l1'
end