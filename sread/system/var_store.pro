;+
; Save var to the system.
; 
; var.
; data.
; times.
; values.
; settings=.
; id=.
;-

function var_store, var0, data, times, values, settings=settings, id=id

    retval = !null

    var = var0[0]
    if n_elements(data) eq 0 then return, retval
    if n_elements(times) eq 0 then begin
        store_data, var, 0, data
    endif else if n_elements(values) eq 0 then begin
        store_data, var, times, data
    endif else begin
        store_data, var, times, data, values
    endelse

    add_setting, var, smart=1, settings, id=id
    return, var

end