function delete_var_from_file_per_var, var, file=data_file, errmsg=errmsg

    cdf_del_var, var, filename=data_file, errmsg=errmsg
    return, 1

end

function delete_var_from_file, var_info, file=data_file, errmsg=errmsg

    errmsg = ''

    if n_elements(data_file) eq 0 then begin
        errmsg = 'No input file ...'
        return, 0
    endif
    
    if file_test(data_file) eq 0 then begin
        errmsg = 'File does not exist: '+data_file+' ...'
        return, 0
    endif

    var_type = size(var_info, type=1)
    ;print, var_info
    ;print, var_type

    if var_type eq 7 then begin
        ; string or strarr.
        foreach var, var_info do begin
            tmp = delete_var_from_file_per_var(var, file=data_file, errmsg=errmsg)
        endforeach
    endif else if var_type eq 11 then begin
        ; list or dict.
        foreach var, var_info do begin
            tmp = delete_var_from_file_per_var(var, file=data_file, errmsg=errmsg)
        endforeach
    endif else if var_type eq 8 then begin
        ; struct.
        foreach var, dictionary(var_info) do begin
            tmp = delete_var_from_file_per_var(var, file=data_file, errmsg=errmsg)
        endforeach
    endif
    
    if errmsg ne '' then return, 0 else return, 1

end