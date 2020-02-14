;+
; Append given time and data to a given var.
; time.
; data.
; limits=.
;-

pro append_data, var, times, data, limits=lim

    if n_elements(var) ne 1 then message, 'Invalid input var ...'
    if tnames(var) eq '' then begin
        store_data, var, times, data, limits=lim
    endif else begin
        get_data, var, old_times, old_data, old_value
        index = where(old_times lt times[0], count)
        if count eq 0 then begin
            old_times = times
            old_data = data
        endif else begin
            old_times = [temporary(old_times[index]),times]
            old_data = [temporary(old_data[index,*,*,*,*,*,*,*]),data]
        endelse
        store_data, var, old_times, old_data, limits=lim
    endelse
end