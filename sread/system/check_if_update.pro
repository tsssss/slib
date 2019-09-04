;+
; Check if a variable needs to be updated.
; Update if it does not exist or if it is out of the given time range.
;-

function check_if_update, var, time_range

    if n_elements(var) eq 0 then return, 1
    if tnames(var) eq '' then return, 1
    if n_elements(time_range) ne 2 then return, 0
    get_data, var, times
    index = lazy_where(times, time_range, count=count)
    if count le 1 then return, 1 else return, 0

end
