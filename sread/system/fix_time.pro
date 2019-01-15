;+
; Convert the times for given variables to ut time.
; 
; vars. A string or an array of variables.
; type_type. A string specifies the time type of vars.
; 
; It is assumed that all variables share the same times.
;-
pro fix_time, vars, time_type

    nvar = n_elements(vars)
    if nvar eq 0 then message, 'No variable ...'
    
    vars = tnames(vars)
    nvar = n_elements(vars)
    get_data, vars[0], times
    times = convert_time(times, from=time_type, to='unix')
    
    for i=0, nvar-1 do begin
        get_data, vars[i], tmp, dat
        store_data, vars[i], times, dat
    endfor

end