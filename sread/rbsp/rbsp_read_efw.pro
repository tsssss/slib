;+
; Read RBSP EFW data.
;
; time. A time or a time range in ut time. Set time to find files
;   automatically, or set files to read data in them directly.
; datatype. A string set which set of variable to read. Use
;   print_datatype to see supported types.
; probe. A string set the probe to read data for.
; level. A string set the level of data, e.g., 'l1'.
; variable. An array of variables to read. Users can omit this keyword
;   unless want to fine tune the behaviour.
; files. A string or an array of N full file names. Set this keyword
;   will set files directly.
; version. A string sets the version of data. Default behaviour is to read
;   the highest version. Set this keyword to read specific version.
;
;-
pro rbsp_read_efw, time, datatype, probe=probe, print_datatype=print_datatype, $
    variable=vars, files=files, level=level, version=version, id=id

    nfile = n_elements(files)
    if n_elements(time) eq 0 and nfile eq 0 then begin
        message, 'no time or file is given ...', /continue
        if not keyword_set(print_datatype) then return
    endif
    if keyword_set(print_datatype) then probe = 'x'
    
    loc_root = join_path([data_root_dir(),'data','rbsp'])
    rem_root = 'https://cdaweb.sci.gsfc.nasa.gov/pub/data/rbsp'
    version = (n_elements(version) eq 0)? 'v[0-9]{2}': version
    rbspx = 'rbsp'+probe
    
    type_dispatch = []
    type_dispatch = [type_dispatch, $
        {id: 'l1%vb1', $
        base_pattern: rbspx+'_l1_vb1_%Y%m%d_'+version+'.cdf', $
        remote_pattern: join_path([rem_root,rbspx,'l1','efw','vb1','%Y']), $
        local_pattern: join_path([loc_root,rbspx,'efw','l1','vb1','%Y']), $
        variable: ptr_new(['epoch','vb1']), $
        time_var: 'epoch', $
        time_type: 'epoch16'}]
    type_dispatch = [type_dispatch, $
        {id: 'l1%mscb1', $
        base_pattern: rbspx+'_l1_mscb1_%Y%m%d_'+version+'.cdf', $
        remote_pattern: join_path([rem_root,rbspx,'l1','efw','mscb1','%Y']), $
        local_pattern: join_path([loc_root,rbspx,'efw','l1','mscb1','%Y']), $
        variable: ptr_new(['epoch','mscb1']), $
        time_var: 'epoch', $
        time_type: 'epoch16'}]
    type_dispatch = [type_dispatch, $
        {id: 'l2%euvw', $
        base_pattern: rbspx+'_efw-l2_e-hires-uvw_%Y%m%d_'+version+'.cdf', $
        remote_pattern: join_path([rem_root,rbspx,'l2','efw','e-highres-uvw','%Y']), $
        local_pattern: join_path([loc_root,rbspx,'efw','l2','e-highres-uvw','%Y']), $
        variable: ptr_new(['epoch','e_hires_uvw']), $
        time_var: 'epoch', $
        time_type: 'epoch16'}]
    type_dispatch = [type_dispatch, $
        {id: 'l2%vsvy-highres', $
        base_pattern: rbspx+'_efw-l2_vsvy-hires_%Y%m%d_'+version+'.cdf', $
        remote_pattern: join_path([rem_root,rbspx,'l2','efw','vsvy-highres','%Y']), $
        local_pattern: join_path([loc_root,rbspx,'efw','l2','vsvy-highres','%Y']), $
        variable: ptr_new(['epoch','vsvy']), $
        time_var: 'epoch', $
        time_type: 'epoch16'}]
    type_dispatch = [type_dispatch, $
        {id: 'l3%efw', $
        base_pattern: rbspx+'_efw-l3_%Y%m%d_'+version+'.cdf', $
        remote_pattern: join_path([rem_root,rbspx,'l3','efw','%Y']), $
        local_pattern: join_path([loc_root,rbspx,'efw','l3','%Y']), $
        variable: ptr_new(['epoch','efield_inertial_frame_mgse']), $
        time_var: 'epoch', $
        time_type: 'epoch16'}]
    if keyword_set(print_datatype) then begin
        print, 'Suported data type: '
        ids = type_dispatch.id
        foreach id, ids do print, '  * '+id
        return
    endif

    ; dispatch patterns.
    id = strjoin([level,datatype],'%')
    ids = type_dispatch.id
    idx = where(ids eq id, cnt)
    if cnt eq 0 then message, 'Do not support type '+id+' yet ...'
    myinfo = type_dispatch[idx[0]]
    
    ; find files to be read.
    file_cadence = 86400.
    if nfile eq 0 then begin
        update_t_threshold = 365.25d*86400  ; 1 year.
        index_file = 'remote-index.html'
        times = break_down_times(time, file_cadence)
        patterns = [myinfo.base_pattern, myinfo.local_pattern, myinfo.remote_pattern]
        files = find_data_file(time, patterns, index_file, $
            file_cadence=file_cadence, threshold=update_t_threshold)
    endif

    ; read variables from file.
    if n_elements(vars) eq 0 then vars = *myinfo.variable
    times = make_time_range(time, file_cadence)
    time_type = myinfo.time_type
    time_var = myinfo.time_var
    times = convert_time(times, from='unix', to=time_type)
    read_data_time, files, vars, prefix='', time_var=time_var, times=times
    if time_type ne 'unix' then fix_time, vars, time_type
end


rbsp_read_efw, /print_datatype
utr0 = time_double(['2013-06-07/04:52','2013-06-07/05:02'])
rbsp_read_efw, utr0, 'efw', level='l3', 'b'
end
