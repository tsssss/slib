;+
; Duplicate a variable.
; 
; old_name. A string of old name.
; output=new_name. A string of new name.
;-
function duplicate_var, old_name, output=new_name, errmsg=errmsg

    errmsg = ''

    if tnames(old_name) eq '' then begin
        errmsg = 'No input new_name ...'
        return, ''
    endif

    get_data, old_name, data=data, limit=limit, dlimit=dlim
    store_data, new_name, data=data, limit=limit, dlimit=dlim
    return, new_name

end