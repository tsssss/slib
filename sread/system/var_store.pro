;+
; Save var to the system.
; 
; var.
; data.
; times.
; values.
; settings=.
;-

function var_store, var, data, times, values, settings=settings

    retval = !null

    if n_elements(data) eq 0 then return, retval
    if n_elements(times) eq 0 then begin
        store_data, var, data
        add_setting, var, smart=1, settings
        return, var
    endif

    if n_elements(values) eq 0 then begin
        store_data, var, times, data
        add_setting, var, smart=1, settings
        return, var
    endif

    store_data, var, times, data, values
    add_setting, var, smart=1, settings
    return, var

end