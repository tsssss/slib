;+
; Make an array of time ranges.
; 
; time. A ut time or a time range.
; cadence. The time resolution of data files (usually a day, or 86400 sec).
;   Or a string sets the cadence to 'month' or 'year' or 'hour'.
; month. A boolean overwrites cadence and set it to a month.
; return. An array in [N,2], where N is the number of time ranges.
;-
function make_time_range, time, cadence

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
        endcase
    endif else dt = (n_elements(cadence) eq 0)? 86400d: cadence

    ; time is a time range.
    t0 = time[0]
    t1 = time[1]
    
    t0 = t0-(t0 mod dt)
    t1 = t1-(t1 mod dt)+dt
    ntime = (t1-t0)/dt
    times = smkarthm(t0,t1,dt,'dx')
    if format ne '' then begin
        dates = convert_time(times, from='unix', to=format)
        idx = uniq(dates)
        times = convert_time(dates[idx], from=format, to='unix')
    end
    times = [times, time]
    times = times[uniq(times,sort(times))]
    times = times[where(times ge time[0] and times le time[1])]

    ; convert times to time ranges.
    ntime = n_elements(times)-1
    time_ranges = dblarr(ntime,2)
    for i=0, ntime-1 do time_ranges[i,*] = times[i:i+1]
    
    return, time_ranges
    
end

print, time_string(make_time_range(time_double(['2013-06-07/04:45','2013-06-07/05:15'])))
print, time_string(make_time_range(time_double(['2013-06-07','2013-06-07/05:15'])))
print, time_string(make_time_range(time_double(['2013-06-07','2013-06-08/05:15'])))
print, time_string(make_time_range(time_double(['2013-06-07','2013-06-09'])))
print, 'month'
print, time_string(make_time_range(time_double(['2013-06-07','2013-07-09']),'month'))
print, 'year'
print, time_string(make_time_range(time_double(['2013-06-07','2013-07-09']),'year'))
end

