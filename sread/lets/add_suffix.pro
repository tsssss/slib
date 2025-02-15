
function add_suffix, input_var_info, suffix, errmsg=errmsg

    errmsg = ''
    if n_elements(suffix) eq 0 then suffix = ''
    if suffix eq '' then return, input_var_info

    var_type = size(input_var_info, type=1)

    if var_type eq 7 then begin
        ; string or strarr.
        var_info = input_var_info+suffix
        return, var_info
    endif
    
    if isa(input_var_info,'list') then begin
        var_info = list()
        foreach var, input_var_info do begin
            var_info.add, var+suffix
        endforeach
        return, var_info
    endif

    if isa(input_var_info,'dictionary') then begin
        var_info = dictionary()
        foreach key, input_var_info.keys() do begin
            var_info[key] = input_var_info[key]+suffix
        endforeach
        return, var_info
    endif

    if var_type eq 8 then begin
        var_info = add_suffix(dictionary(input_var_info),suffix)
        return, var_info.tostruct()
    endif

    errmsg = 'Unkown type of var_info ...'
    return, !null

end