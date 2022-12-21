;+
; Rename a variable.
; 
; old_name. A string of old name.
; output=new_name. A string of new name.
;-
function rename_var, old_name, output=new_name

    if tnames(new_name) ne '' then store_data, new_name, /delete
    store_data, old_name, newname=new_name
    return, new_name
;    get_data, old_name, data=dd, limit=lim, dlimit=dlim
;    store_data, new_name, data=dd, limit=lim, dlimit=dlim
;    del_data, old_name

end