;+
; Expand the given flag by the amount of pad_time.
;-
function expand_flag, flags, times, pad_time=pad_time

    if n_elements(pad_time) eq 0 then return, flags

    index = where(flags eq 1, count)
    if count eq 0 then return, flags

    time_step = sdatarate(times)
    ntime = n_elements(flags)
    drec = pad_time/(time_step)
    flag_ranges = time_to_range(index, time_step=1)
    flag_ranges[*,0] -= drec
    flag_ranges[*,1] += drec
    flag_ranges[*,0] >= 0
    flag_ranges[*,1] <= (ntime-1)
    nflag_range = n_elements(flag_ranges[*,0])
    for ii=0,nflag_range-1 do begin
        i0 = flag_ranges[ii,0]
        i1 = flag_ranges[ii,1]
        flags[i0:i1] = 1
    endfor

    return, flags

end