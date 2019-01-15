;+
; Return the value for a requested key for given variable.
; 
; var. A string of variable.
; key. A string of key.
; exist. A boolean, 1 indicates the key exists.
;-
function get_setting, var, key, exist

    get_data, var, limits=lims
    if size(lims,/type) ne 8 then begin
        exist = 0
        return, -1
    endif
    
    keys = strlowcase(tag_names(lims))
    idx = where(keys eq key, cnt)
    if cnt eq 0 then begin
        exist = 0
        return, -1
    endif
    
    exist = 1
    return, lims.(idx)
end