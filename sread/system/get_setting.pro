;+
; Return the value for a requested key for given variable.
; 
; var. A string of variable.
; key. A string of key.
; exist. A boolean, 1 indicates the key exists.
;-
function get_setting, var, key, exist

    retval = !null
    
    get_data, var, limits=lims
    if size(lims,/type) ne 8 then begin
        exist = 0
        return, retval
    endif
    
    keys = strlowcase(tag_names(lims))
    idx = where(keys eq key, cnt)
    if cnt eq 0 then begin
        exist = 0
        return, retval
    endif
    
    exist = 1
    return, lims.(idx)
end