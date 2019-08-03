;+
; Read LANL SOPA/ESP/orbit data.
;
; time. A time or a time range in ut time. Set time to find files
;   automatically, or set files to read data in them directly.
; datatype. A string set which set of variable to read. Use
;   print_datatype to see supported types.
; probe. A string set the probe to read data for.
; level. A string of dummy variable.
; variable. An array of variables to read. Users can omit this keyword
;   unless want to fine tune the behaviour.
; files. A string or an array of N full file names. Set this keyword
;   will set files directly.
; version. A string sets the version of data. Default behaviour is to read
;   the highest version. Set this keyword to read specific version.
;-

pro lanl_read_data, time, id=datatype, probe=probe, $
    print_datatype=print_datatype, errmsg=errmsg, $
    in_vars=in_vars, out_vars=out_vars, files=files, version=version, $
    local_root=local_root, $
    time_var_name=time_var_name, time_var_type=time_var_type, generic_time=generic_time

    compile_opt idl2
    on_error, 0
    errmsg = ''


;---Check inputs.
    sync_threshold = 0
    nfile = n_elements(files)
    if n_elements(probe) eq 0 then probe = 'x'
    if n_elements(local_root) eq 0 then local_root = join_path([default_local_root(),'sdata','lanl'])
    if n_elements(version) eq 0 then version = 'v[0-9.]{5}'

;---Init settings.
    type_dispatch = hash()
    ; SOPA.
    base_name = '%Y%m%d_'+strupcase(probe)+'_SOPA_ESP_'+version+'.txt'
    local_path = [local_root,'%Y','%m']
    type_dispatch['sopa'] = dictionary($
        'pattern', dictionary('local_file', join_path([local_path,base_name])), $
        'cadence', 'day', $
        'extension', fgetext(base_name), $
        'var_list', list($
            dictionary($
            'in_vars', ['AVE_FLUX_SOPA_E','AVE_FLUX_I'], $
            'out_vars', ['e_flux','p_flux'], $
            'time_var_name', 'DateTime', $
            'time_var_type', 'unix'), $
            dictionary($
            'in_vars', ['SopaEEnergy','SopaPEnergy'], $
            'out_vars', ['e_energy','p_energy'], $
            'generic_time', 1)))
    ; Orbit.
    type_dispatch['orbit'] = dictionary($
        'pattern', dictionary('local_file', join_path([local_path,base_name])), $
        'cadence', 'day', $
        'extension', fgetext(base_name), $
        'var_list', list($
            dictionary($
            'in_vars', ['SC_GEO'], $
            'out_vars', ['r_geo'], $
            'time_var_name', 'DateTime', $
            'time_var_type', 'unix')))
    type_dispatch['orbit2'] = dictionary($
        'pattern', dictionary('local_file', join_path([local_path,base_name])), $
        'cadence', 'day', $
        'extension', fgetext(base_name), $
        'var_list', list($
            dictionary($
            'in_vars', ['SC_MLAT','SC_MLON','SC_MLT','SC_LAT','SC_LON'], $
            'out_vars', ['mlat','mlon','mlt','glat','glon'], $
            'time_var_name', 'DateTime', $
            'time_var_type', 'unix')))
    type_dispatch['esp'] = dictionary($
        'pattern', dictionary('local_file', join_path([local_path,base_name])), $
        'cadence', 'day', $
        'extension', fgetext(base_name), $
        'var_list', list($
            dictionary($
            'in_vars', ['AVE_FLUC_ESP_E'], $
            'out_vars', ['e_flux'], $
            'time_var_name', 'DateTime', $
            'time_var_type', 'unix')))

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
    files = prepare_files(request=request, errmsg=errmsg, local_files=files, $
        file_times=file_times, time=time, nonexist_files=nonexist_files)

;---Convert to CDF.
    foreach file, files, ii do begin
        lanl_convert_txt_to_cdf, file, errmsg=errmsg
        if errmsg ne '' then begin
            errmsg = handle_error('Error in converting to CDF ...')
            return
        endif
        pos = strpos(file, '.', /reverse_search)
        files[ii] = strmid(file,0,pos)+'.cdf'
    endforeach

;---Read data from files and save to memory.
    read_files, time, files=files, request=request


end


time = time_double(['2014-08-28/09:00','2014-08-28/11:00'])
probe = '1991-080'
datatype = 'sopa'
lanl_read_data, time, probe=probe, id=datatype
end
