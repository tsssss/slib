;+
; Read GOES position in GSM. Save as 'gxx_r_gsm'
; 
; utr0. A time or a time range in ut sec.
; probe. A string sets the probe, e.g., '13','15'.
; 
; Need spedas to run.
;-
;

pro goes_read_orbit_internal, time, probe=probe, errmsg=errmsg, $
    files=files, id=id
    
    compile_opt idl2
    on_error, 0
    errmsg = ''
    
    nfile = n_elements(files)
    if n_elements(time) eq 0 and nfile eq 0 and ~keyword_set(print_datatype) then begin
        errmsg = handle_error('No time or file is given ...')
        return
    endif
    if keyword_set(print_datatype) then probe = 'x'

    loc_root = join_path([data_root_dir(),'sdata','goes'])
    version = 'v01'
    pre0 = 'g'+probe
    
    type_dispatch = []
    type_dispatch = [type_dispatch, $
        {id: 'orbit', $
        base_pattern: pre0+'_orbit_%Y_%m%d_'+version+'.cdf', $
        local_pattern: join_path([loc_root, pre0, 'orbit', '%Y']), $
        remote_pattern: '', $
        variable: ['ut_pos','pos_gsm'], $
        time_var: 'ut_pos', $
        time_type: 'unix'}]
    if keyword_set(print_datatype) then begin
        print, 'Suported data type: '
        ids = type_dispatch.id
        foreach id, ids do print, '  * '+id
        return
    endif
    
    ; dispatch patterns.
    if n_elements(id) eq 0 then id = 'orbit'
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
    
    nfile = n_elements(files)
    for i=0, nfile-1 do begin
        if file_test(files[i]) eq 0 then begin
            date = times[0]
            goes_gen_orbit_data, date, probe=probe, file=files[i]
        endif
    endfor
    
    ; no file is found.
    if n_elements(files) eq 1 and files[0] eq '' then begin
        errmsg = handle_error('No file is found ...')
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

pro goes_read_orbit, utr0, probe=probe, errmsg=errmsg

    if n_elements(probe) eq 0 then begin
        errmsg = handle_error('No input probe ...')
        return
    endif
    
    re = 6378d
    re1 = 1d/re
    goes_read_orbit_internal, utr0, probe=probe, errmsg=errmsg
    if errmsg ne '' then return
    
    pre0 = 'g'+probe+'_'
    var = pre0+'r_gsm'
    rename_var, 'pos_gsm', to=var
    settings = { $
        display_type: 'vector', $
        unit: 'Re', $
        short_name: 'R', $
        coord: 'GSM', $
        coord_labels: ['x','y','z'], $
        colors: [6,4,2]}
    add_setting, var, settings, /smart
    

end


utr0 = time_double(['2014-08-28/05:00','2014-08-28/06:00'])
goes_read_orbit, utr0, '13'
end
