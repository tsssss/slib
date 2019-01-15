;+
; Read RBSP EMFISIS data.
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
; resolution. A string. Default is '4sec', can be '1sec','4sec','hires'.
;-
pro rbsp_read_emfisis, time, datatype, probe=probe, level=level, $
    print_datatype=print_datatype, errmsg=errmsg, $
    variable=vars, files=files, version=version, id=id, $
    resolution=resolution, coordinate=coord
    
    compile_opt idl2
    on_error, 0
    errmsg = 0
    

    nfile = n_elements(files)
    if n_elements(time) eq 0 and nfile eq 0 and ~keyword_set(print_datatype) then begin
        errmsg = handle_error('no time or file is given ...')
        return
    endif
    if keyword_set(print_datatype) then probe = 'x'
    
    loc_root = join_path([data_root_dir(),'sdata','rbsp'])
    rem_root = 'https://cdaweb.sci.gsfc.nasa.gov/pub/data/rbsp'
    version = (n_elements(version) eq 0)? 'v[0-9.]{5}': version
    rbspx = 'rbsp'+probe
    if n_elements(resolution) eq 0 then resolution = '4sec'
    if n_elements(coord) eq 0 then coord = 'gsm'

    type_dispatch = []
    type_dispatch = [type_dispatch, $
        {id: 'l2%magnetometer', $
        base_pattern: 'rbsp-'+probe+'_magnetometer_uvw_emfisis-l2_%Y%m%d_'+version+'.cdf', $
        remote_pattern: join_path([rem_root,rbspx,'l2','emfisis','magnetometer','uvw','%Y']), $
        local_pattern: join_path([loc_root,rbspx,'emfisis','%Y','l2','magnetometer','uvw']), $
        variable: ptr_new(['Epoch','Mag']), $
        time_var: 'Epoch', $
        time_type: 'tt2000'}]
    type_dispatch = [type_dispatch, $
        {id: 'l3%magnetometer', $
        base_pattern: 'rbsp-'+probe+'_magnetometer_'+resolution+'-'+coord+'_emfisis-l3_%Y%m%d_'+version+'.cdf', $
        remote_pattern: join_path([rem_root,rbspx,'l3','emfisis','magnetometer',resolution,coord,'%Y']), $
        local_pattern: join_path([loc_root,rbspx,'emfisis','%Y','l3','magnetometer',resolution,coord]), $
        variable: ptr_new(['Epoch','Mag']), $
        time_var: 'Epoch', $
        time_type: 'tt2000'}]
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
        update_t_threshold = 365.25d*86400  ; 1 year.
        index_file = 'remote-index.html'
        times = break_down_times(time, file_cadence)
        patterns = [myinfo.base_pattern, myinfo.local_pattern, myinfo.remote_pattern]
        files = find_data_file(time, patterns, index_file, $
            file_cadence=file_cadence, threshold=update_t_threshold)
    endif
    
    ; no file is found.
    if n_elements(files) eq 1 and files[0] eq '' then begin
        errmsg = handle_error('No file is found ...')
        return
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


rbsp_read_emfisis, /print_datatype
utr0 = time_double(['2013-06-07/04:52','2013-06-07/05:02'])
rbsp_read_emfisis, utr0, 'magnetometer', level='l3', 'b'
end
 
