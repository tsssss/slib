;+
; Read Themis FGM data.
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
;-

pro themis_read_fgm, time, datatype, probe=probe, level=level, $
    print_datatype=print_datatype, errmsg=errmsg, $
    variable=vars, files=files, version=version, id=id

    compile_opt idl2
    on_error, 0
    errmsg = ''
    

    nfile = n_elements(files)
    if n_elements(time) eq 0 and nfile eq 0 then begin
        message, 'no time or file is given ...', /continue
        if not keyword_set(print_datatype) then return
    endif
    if keyword_set(print_datatype) then probe = 'x'

    loc_root = join_path([sdiskdir('Research'),'data','themis'])
    rem_root = 'https://cdaweb.sci.gsfc.nasa.gov/pub/data/themis'
    version = (n_elements(version) eq 0)? 'v[0-9]{2}': version
    thx = 'th'+probe

    type_dispatch = []
    ; 3 sec resolution.
    type_dispatch = [type_dispatch, $
        {id: 'l2%fgs', $
        base_pattern: thx+'_l2_fgm_%Y%m%d_'+version+'.cdf', $
        remote_pattern: join_path([rem_root,thx,'l2','fgm','%Y']), $
        local_pattern: join_path([loc_root,thx,'l2','fgm','%Y']), $
        variable: ptr_new(['fgs_time','fgs_gsm']), $
        time_var: 'fgs_time', $
        time_type: 'unix'}]
    ; 0.008 sec resolution.
    type_dispatch = [type_dispatch, $
        {id: 'l2%fgl', $
        base_pattern: thx+'_l2_fgm_%Y%m%d_'+version+'.cdf', $
        remote_pattern: join_path([rem_root,thx,'l2','fgm','%Y']), $
        local_pattern: join_path([loc_root,thx,'l2','fgm','%Y']), $
        variable: ptr_new(['fgs_time','fgs_gsm']), $
        time_var: 'fgs_time', $
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
    read_data_time, files, vars, prefix=thx+'_', time_var=time_var, times=times
    if time_type ne 'unix' then fix_time, vars, time_type
end
    
themis_read_fgm, /print_datatype
utr0 = time_double(['2013-10-30/23:00','2013-10-31/06:00'])
themis_read_fgm, utr0, 'fgs', level='l2', 'd'
end
