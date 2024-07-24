function delete_var_from_memory_per_var, var, errmsg=errmsg

    del_data, var
    return, 1

end

function delete_var_from_memory, var_info, errmsg=errmsg

    errmsg = ''

    var_type = size(var_info, type=1)
    ;print, var_info
    ;print, var_type

    if var_type eq 7 then begin
        ; string or strarr.
        foreach var, var_info do begin
            tmp = delete_var_from_memory_per_var(var, errmsg=errmsg)
        endforeach
    endif else if var_type eq 11 then begin
        ; list or dict.
        foreach var, var_info do begin
            tmp = delete_var_from_memory_per_var(var, errmsg=errmsg)
        endforeach
    endif else if var_type eq 8 then begin
        ; struct.
        foreach var, dictionary(var_info) do begin
            tmp = delete_var_from_memory_per_var(var, errmsg=errmsg)
        endforeach
    endif
    
    return, 1

end