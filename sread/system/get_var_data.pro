;+
; Return data for a variable.
;-
;
function get_var_data, var, raw=raw

    get_data, var, tmp, dat
    
    if keyword_set(raw) then return, dat
    
    ; Shrink [1] to scalar.
    if n_elements(dat) eq 1 then return, dat[0]
    
    ; Shrink any useless dimension.
    return, reform(dat)
    
end