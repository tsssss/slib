;+
; Return time for a variable.
;
; var. A string for tplot name.
; in=time_range. Set it to load the data at the given time range.
; limits=. A structure of options.
;-

function get_var_time, var, in=time_range, limits=lim

    retval = !null
    if n_elements(var) ne 1 then message, 'Invalid input var ...'   ; want to stop instead of return.
    if tnames(var) eq '' then return, retval

    get_data, var, times, limits=lim

    if n_elements(time_range) eq 2 then begin
        index = where_pro(times, time_range, count=count)
        if count eq 0 then return, retval
        times = times[index]
    endif

    return, times

end