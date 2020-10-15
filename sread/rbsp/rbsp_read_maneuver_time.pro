;+
; Return the times of maneuver within the given time range.
; Merge thruster 1 and 2, merge adjacent maneuvers,
; but essentially a wrapper of rbsp_load_maneuver_times.
;
; time. The time range in unix time.
; probe=probe. The probe, 'a' or 'b'.
;-

function rbsp_read_maneuver_time, time, probe=probe, $
    local_files=files, file_times=file_times, version=version, $
    local_root=local_root, remote_root=remote_root

    compile_opt idl2
    on_error, 0
    errmsg = ''
    retval = !null

    ntime =  n_elements(time)
    case ntime of
        1: timespan, time, 1, /day
        2: timespan, time[0], time[1]-time[0], /seconds
        else: return, retval
    endcase

    info = rbsp_load_maneuver_times(probe)
    if n_elements(info) eq 0 then return, retval

    time_ranges = [[info.estart],[info.eend]]
    ntime_range = n_elements(time_ranges)*0.5
    for ii=0,ntime_range-1 do begin
        for jj=ii+1,ntime_range-1 do begin
            if time_ranges[jj,0]-time_ranges[ii,1] gt 120 then continue
            the_time_ranges = minmax(time_ranges[[ii,jj],*])
            time_ranges[ii,*] = the_time_ranges
            time_ranges[jj,*] = the_time_ranges
        endfor
    endfor

    index = uniq(time_ranges[*,0],sort(time_ranges[*,0]))
    maneuver_time_ranges = time_ranges[index,*]

    return, maneuver_time_ranges



;    ; Check time (in day) between maneuvers.
;    plot, (maneuver_time_ranges[1:-1,1]-maneuver_time_ranges[0:-2,0])/86400, /ynozero
;
;    ; Check duration (in hour).
;    plot, (maneuver_time_ranges[*,1]-maneuver_time_ranges[*,0])/3600, /ynozero
;
;    ; Save to tplot.
;    store_data, 'test', maneuver_time_ranges[1:-1,0], (maneuver_time_ranges[1:-1,1]-maneuver_time_ranges[0:-2,0])/86400
;    tplot, 'test'

end

time_range = time_double(['2012','2020'])
probe = 'a'
times = rbsp_read_maneuver_time(time_range, probe=probe)
end
