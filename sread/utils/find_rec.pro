;+
; Find the record information for given time and time_var.
; 
; file. A string of full file name.
; time_var. The time_var to be examined.
; times. A time or a time range in the format of time_var.
; 
; return. A record for a time, or a record range for a time range.
;=
function find_rec, file, time_var, times

    ntime = n_elements(times)
    if ntime le 0 then message, 'No time is given ...'
    is_time_range = ntime eq 2
    
    dat0 = scdfread(file, time_var)
    time = *dat0[0].value
    if size(time,/type) eq 9 then begin
        times = real_part(times)
        time = real_part(time)
    endif
    if is_time_range then begin
        rec = where(time ge times[0] and time le times[1], cnt)
        return, [rec[0],rec[cnt-1]]
    endif else begin
        tmp = min(time-times[0], rec, /absolute)
        return, rec
    endelse
    
end