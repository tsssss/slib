;+
; Check if a variable needs to be updated.
; Update if it does not exist or if it is out of the given time range.
;-

function check_if_update, var, time_range

    if n_elements(var) eq 0 then return, 1
    if tnames(var) eq '' then return, 1
    if n_elements(time_range) ne 2 then return, 0
    get_data, var, times
    if n_elements(times) le 1 then return, 1
    dtime = times[1]-times[0]
    if (min(times)-min(time_range)) gt dtime then return, 1
    if (max(time_range)-max(times)) gt dtime then return, 1
    return, 0

end
