function interp_var_to_time_per_var, var, times, errmsg=errmsg

    errmsg = ''
    interp_time, var, times, errmsg=errmsg
    if errmsg ne '' then return, 1 else return, 0

end

function interp_var_to_time, var_info, times, time_var=time_var, errmsg=errmsg

    errmsg = ''

    var_type = size(var_info, type=1)
    ;print, var_info
    ;print, var_type

    if n_elements(time_var) ne 0 then times = get_var_data(time_var)
    if n_elements(times) le 1 then begin
        errmsg = 'Invalid times ...'
        return, 0
    endif

    if var_type eq 7 then begin
        ; string or strarr.
        foreach var, var_info do begin
            tmp = interp_var_to_time_per_var(var, times, errmsg=errmsg)
        endforeach
    endif else if var_type eq 11 then begin
        ; list or dict.
        foreach var, var_info do begin
            tmp = interp_var_to_time_per_var(var, times, errmsg=errmsg)
        endforeach
    endif else if var_type eq 8 then begin
        ; struct.
        foreach var, dictionary(var_info) do begin
            tmp = interp_var_to_time_per_var(var, times, errmsg=errmsg)
        endforeach
    endif
    
    return, 1


end