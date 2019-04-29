;+
; Return data for a variable.
; 
; var. A string for tplot name.
; at. Set it to load the data at the given time.
; raw. A boolean. By default, the program shrinks unnecessary dimensions. Set raw to preserve all dimensions.
;-
;
function get_var_data, var, at=time, raw=raw

    if tnames(var) eq '' then return, !null
    
    get_data, var, tmp, dat
    
    if keyword_set(time) ne 0 then begin
        if n_elements(time) eq 1 then begin
            index = where(tmp eq time[0], count)
            if count eq 0 then dat = sinterpol(dat, tmp, time) else dat = dat[index,*,*,*,*,*,*,*]
        endif else begin
            dat = sinterpol(dat, tmp, time)
        endelse
    endif
    
    if keyword_set(raw) then return, dat
    
    ; Shrink [1] to scalar.
    if n_elements(dat) eq 1 then return, dat[0]
    
    ; Shrink any useless dimension.
    return, reform(dat)
    
end