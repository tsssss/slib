function check_if_update_memory_per_var, var, time_range

    return, check_if_update(var, time_range)

end

function check_if_update_memory, var_info, time_range

    var_type = size(var_info, type=1)
    ;print, var_info
    ;print, var_type

    if var_type eq 7 then begin
        ; string or strarr.
        foreach var, var_info do begin
            if ~check_if_update_memory_per_var(var, time_range) then continue
            return, 1
        endforeach
    endif else if var_type eq 11 then begin
        ; list or dict.
        foreach var, var_info do begin
            if ~check_if_update_memory_per_var(var, time_range) then continue
            return, 1
        endforeach
    endif else if var_type eq 8 then begin
        ; struct.
        foreach var, dictionary(var_info) do begin
            if ~check_if_update_memory_per_var(var, time_range) then continue
            return, 1
        endforeach
    endif
    
    return, 0

end


print, check_if_update_memory('a')
print, check_if_update_memory(['a','b'])
print, check_if_update_memory(list(['a','b'],extract=1))
print, check_if_update_memory(dictionary('var1','a','var2','b'))
print, check_if_update_memory({var1:'a',var2:'b'})
end