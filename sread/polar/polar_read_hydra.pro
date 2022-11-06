;+
; Read Polar Hydra moment data.
; 
; datatype. A string set which set of variable to read. Use
;   print_datatye to see supported types.
; species. A string 'ion' or 'ele'.
; 'v', in cm/s, 3d.
; 't', in K, 1d.
; 'n', in 'cc', 1d.
; 'tpar', in K, 1d.
; 'tperp
;-

pro polar_read_hydra, time, datatype, print_datatype=print_datatype, $
    variable=vars, files=files, level=level, version=version, species=species, vars=mom_vars
 
    nfile = n_elements(files)
    if n_elements(time) eq 0 and nfile eq 0 then begin
        message, 'no time or file is given ...', /continue
        if not keyword_set(print_datatype) then return
    endif
    
    if n_elements(species) eq 0 then message, 'no species ...'
    
    loc_root = join_path([sdiskdir('Research'),'sdata','opt_hydra'])
    version = (n_elements(version) eq 0)? 'v[0-9.]*': version
    pre0 = 'po_'

    if n_elements(mom_vars) eq 0 then mom_vars = ['epoch','n','t']
    
    type_dispatch = []
    type_dispatch = [type_dispatch, $
        {id: 'ele%moment', $
        base_pattern: '%Y%m%d_hyd_mom_'+version+'.cdf', $
        local_pattern: join_path([loc_root,'moment_data']), $
        variable: ptr_new(mom_vars), $
        time_var: 'epoch', $
        time_type: 'epoch'}]
    type_dispatch = [type_dispatch, $
        {id: 'ion%moment', $
        base_pattern: '%Y%m%d_hyd_momi_'+version+'.cdf', $
        local_pattern: join_path([loc_root,'moment_data']), $
        variable: ptr_new(mom_vars), $
        time_var: 'epoch', $
        time_type: 'epoch'}]

    ; dispatch patterns.
    id = strjoin([species,datatype],'%')
    ids = type_dispatch.id
    idx = where(ids eq id, cnt)
    if cnt eq 0 then message, 'Do not support type '+id+' yet ...'
    myinfo = type_dispatch[idx[0]]
    
    ; find files to be read.
    file_cadence = 86400d
    if nfile eq 0 then begin
        times = break_down_times(time, file_cadence)
        base_names = apply_time_to_pattern(myinfo.base_pattern, times)
        local_paths = apply_time_to_pattern(myinfo.local_pattern, times)
        files = local_paths+path_sep()+base_names
        nfile = n_elements(files)
        for i=0, nfile-1 do files[i] = (file_search(files[i]))[-1]
    endif

    ; read variables from file.
    if n_elements(vars) eq 0 then vars = *myinfo.variable
    times = make_time_range(time, file_cadence)
    time_type = myinfo.time_type
    time_var = myinfo.time_var
    times = convert_time(times, from='unix', to=time_type)
    read_data_time, files, vars, prefix='', time_var=time_var, times=times, /dum
    if time_type ne 'unix' then fix_time, vars, time_type
    
    ; fix variable name.
    pre1 = (species eq 'ion')? pre0+'ion_': pre0+'ele_'
    idx = where(vars ne time_var)
    foreach i, idx do rename_var, vars[i], to=pre1+vars[i]

end


utr = time_double(['1998-09-25/05:00','1998-09-26/06:00'])
polar_read_hydra, utr, 'moment', species='ion'
polar_read_hydra, utr, 'moment', species='ele'

end
