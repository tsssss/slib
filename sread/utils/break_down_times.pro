;+
; Break a time range into a list of ut times.
; 
; time. A ut time or a time range.
; cadence. The time resolution of data files (usually a day, or 86400 sec).
;   Or a string sets the cadence to 'month' or 'year' or 'hour'.
; return. An array of ut times.
;-

function break_down_times, time, cadence, errmsg=errmsg
    
    ntime = n_elements(time)
    if ntime eq 1 then return, [time]
    if ntime ne 2 then message, 'Invalid # of input time ...'
    
    format = ''
    if size(cadence,/type) eq 7 then begin
        case strlowcase(cadence) of
            'year': begin
                format = '%Y'
                dt = 86400d
                end
            'month': begin
                format = '%Y%m'
                dt = 86400d
                end
            'day': begin
                format = '%Y%m%d'
                dt = 86400d
                end
            'hour': begin
                format = '%Y%m%d%H'
                dt = 3600d
                end
            'minute': begin
                format = '%Y%m%d%H%M'
                dt = 60d
                end
            'second': begin
                format = '%Y%m%d%H%M%S'
                dt = 1d
                end
            else: begin
                errmsg = handle_error('Do not support '+cadence+' yet ...')
                return, !null
                end
        endcase
    endif else dt = (n_elements(cadence) eq 0)? 86400d: cadence
    
    ; time is a time range.
    t0 = time[0]
    t1 = time[1]
    
    t0 = t0-(t0 mod dt)
    t1 = t1-(t1 mod dt)
    if t1 eq time[1] then t1 -= dt ; 2013-06-07 to 2013-06-08 is 1 day of data.
    if t1 lt t0 then t1 = t0
    
    ntime = (t1-t0)/dt
    if ntime eq 0 then return, [t0]
    
    times = smkarthm(t0,t1, ntime+1, 'n')
    if format ne '' then begin
        dates = convert_time(times, from='unix', to=format)
        idx = uniq(dates)
        times = times[idx]
    end

    return, times

end

print, break_down_times(1)
print, break_down_times([1d,86401])
print, break_down_times([1d,3]*86400)
print, break_down_times([1d,3]*86400+[0,1])
print, break_down_times([1d,31]*86400+[0,1], 'month')

end
