function save_setting_to_memory_per_var, var, settings, errmsg=errmsg, _extra=ex

    errmsg = ''
    add_setting, var, settings, errmsg=errmsg, _extra=ex
    if errmsg eq '' then return, 1 else return, 0

end


function save_setting_to_memory, var_info, settings, errmsg=errmsg, _extra=ex

    errmsg = ''

    var_type = size(var_info, type=1)
    ;print, var_info
    ;print, var_type

    if var_type eq 7 then begin
        ; string or strarr.
        foreach var, var_info do begin
            tmp = save_setting_to_memory_per_var(var, settings, errmsg=errmsg, _extra=ex)
        endforeach
    endif else if var_type eq 11 then begin
        ; list or dict.
        foreach var, var_info do begin
            tmp = save_setting_to_memory_per_var(var, settings, errmsg=errmsg, _extra=ex)
        endforeach
    endif else if var_type eq 8 then begin
        ; struct.
        foreach var, dictionary(var_info) do begin
            tmp = save_setting_to_memory_per_var(var, settings, errmsg=errmsg, _extra=ex)
        endforeach
    endif
    
    if errmsg ne '' then return, 0 else return, 1


end