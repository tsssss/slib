;+
; Rename a variable.
; 
; old_name. A string of old name.
; new_name. A string of new name.
;-
pro rename_var, old_name, to=new_name

    if tnames(new_name) ne '' then store_data, new_name, /delete
    store_data, old_name, newname=new_name

end