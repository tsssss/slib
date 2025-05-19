

function get_var_value, var, in=time_range, limits=lim

    retval = !null
    if n_elements(var) ne 1 then message, 'Invalid input var ...'   ; want to stop instead of return.
    if tnames(var) eq '' then return, retval

    get_data, var, times, data, vals, limits=lim

    ndim = size(vals, n_dimension=1)
    if ndim eq 2 then begin
        if n_elements(time_range) eq 2 then begin
            index = where_pro(times, time_range, count=count)
            if count eq 0 then return, retval
            vals = vals[index,*]
        endif
    endif

    return, vals

end