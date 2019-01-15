;+
; Read RBSP spice products, including orbit and quaternion.
; c.f. rbsp_gen_spice_product if data for given times do not exist.
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
pro rbsp_read_spice, time, datatype, probe=probe, level=level, $
    print_datatype=print_datatype, errmsg=errmsg, $
    variable=vars, files=files, version=version, id=id
    
    compile_opt idl2
    on_error, 0
    errmsg = ''
    
    
    nfile = n_elements(files)
    if n_elements(time) eq 0 and nfile eq 0 then begin
        errmsg = 'No time or file is given ...'
        if not keyword_set(print_datatype) then return else errmsg = ''
    endif
    if keyword_set(print_datatype) then probe = 'x'
    
    loc_root = join_path([sdiskdir('Research'),'sdata','rbsp'])
    version = 'v01'
    rbspx = 'rbsp'+probe

    type_dispatch = []
    ; orbit variables.
    type_dispatch = [type_dispatch, $
        {id: 'orbit', $
        base_pattern: rbspx+'_spice_products_%Y_%m%d_'+version+'.cdf', $
        local_pattern: join_path([loc_root,rbspx,'spice_product','%Y']), $
        remote_pattern: '', $
        variable: ['ut_pos','pos_gsm'], $
        time_var: 'ut_pos', $
        time_type: 'unix'}]
    ; quaternion.
    type_dispatch = [type_dispatch, $
        {id:'quaternion', $
        base_pattern: rbspx+'_spice_products_%Y_%m%d_'+version+'.cdf', $
        local_pattern: join_path([loc_root,rbspx,'spice_product','%Y']), $
        remote_pattern: '', $
        variable: ['ut_cotran','q_uvw2gsm'], $
        time_var: 'ut_cotran', $
        time_type: 'unix'}]
    if keyword_set(print_datatype) then begin
        print, 'Suported data type: '
        ids = type_dispatch.id
        foreach id, ids do print, '  * '+id
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
        times = break_down_times(time, file_cadence)
        base_names = apply_time_to_pattern(myinfo.base_pattern, times)
        local_paths = apply_time_to_pattern(myinfo.local_pattern, times)
        files = local_paths+path_sep()+base_names
    endif

    ; no file is found.
    if n_elements(files) eq 1 and files[0] eq '' then begin
        errmsg = 'No file is found ...'
        return
    endif
    
    ; read variables from file.
    if n_elements(vars) eq 0 then vars = myinfo.variable
    times = make_time_range(time, file_cadence)
    time_type = myinfo.time_type
    time_var = myinfo.time_var
    times = convert_time(times, from='unix', to=time_type)
    read_data_time, files, vars, prefix='', time_var=time_var, times=times
    if time_type ne 'unix' then fix_time, vars, time_type

end

time = time_double(['2013-06-07/04:45','2013-06-07/05:15'])
rbsp_read_spice, time, 'orbit', 'b'
end
