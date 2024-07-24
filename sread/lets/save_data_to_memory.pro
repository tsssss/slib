
function save_data_to_memory, var, v0,v1,v2, $
    time_var=time_var, value_var=value_var, $
    errmsg=errmsg, settings=settings, _extra=ex

    errmsg = ''

    if n_params() eq 4 then begin
        times = v0
        data = v1
        values = v2
    endif else if n_params() eq 3 then begin
        times = v0
        data = v1
        values = !null
    endif else if n_params() eq 2 then begin
        times = !null
        data = v0
        values = !null
    endif

    if n_elements(time_var) ne 0 then times = get_var_data(time_var)
    if n_elements(value_var) ne 0 then values = get_var_data(value_var)

    if n_elements(times) eq 0 then times = 0
    if n_elements(values) eq 0 then begin
        store_data, var, times, data
    endif else begin
        store_data, var, times, data, values
    endelse
    add_setting, var, smart=1, settings

    return, var

end