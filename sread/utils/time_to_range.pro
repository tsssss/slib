;+
; Convert a time series to ranges. Return time ranges in [m,2].
;
; times. An array of times, should be uniform on time_step.
; time_step=. A number in sec to set the time_step that times suppose to have.
; pad_times=. One or two numbers in sec to expand the found time ranges.
;-

function time_to_range, times, time_step=time_step, pad_times=input_pad_times

    errmsg = ''
    retval = !null

    ntime = n_elements(times)
    if ntime eq 0 then begin
        errmsg = handle_error('No input times ...')
        return, retval
    endif
    if n_elements(time_step) eq 0 then begin
        errmsg = handle_error('No input time_step ...')
        return, retval
    endif


    time_ranges = list()
    ; integer works better than float/double.
    xxs = round((times-times[0])/time_step)
    for ii=0, ntime-1 do begin
        for jj=ii+1, ntime-1 do begin
            if xxs[jj]-xxs[jj-1] eq 1 then continue
            break
        endfor
        time_ranges.add, times[[ii,jj-1]]
        ;if ii eq jj-1 then ii = jj-1 else ii = jj
        ii = jj-1
    endfor
    
    
;    i0 = 0
;    while i0 lt ntime-1 do begin
;        i1 = i0
;        while i1 lt ntime-1 do begin
;            if xxs[i1+1]-xxs[i1] ne 1 then break
;            i1 += 1
;        endwhile
;        time_ranges.add, times[[i0,i1]]
;        i0 = i1+1
;    endwhile

    ntime_range = n_elements(time_ranges)
    ; Should be in [n,2].
    time_ranges = time_ranges.toarray()

    case n_elements(input_pad_times) of
        1: pad_times = [-1,1]*abs(input_pad_times)
        2: pad_times = input_pad_times
        else: pad_times = [0,0]
    endcase
    if pad_times[0] ne 0 then time_ranges[*,0] += pad_times[0]
    if pad_times[1] ne 0 then time_ranges[*,1] += pad_times[1]

    return, time_ranges

end

time_ranges = time_to_range(good_triad_times, time_step=60)
end