;+
; Find times when L1 vsvy is at 16 S/s and 32 S/s.
; Then see if the time tag is off accordingly.
;-

probes = ['a','b']
log_file = join_path([srootdir(),'test_esvy_16_32_sec_time_tag.log'])
if file_test(log_file) eq 0 then ftouch, log_file

secofday = constant('secofday')
tab = '    '

foreach probe, probes do begin
    prefix = 'rbsp'+probe+'_'
    full_time_range = rbsp_efw_phasef_get_valid_range('vsvy_l1', probe=probe)
    days = make_bins(full_time_range+[0,-1]*secofday, secofday)

    foreach day, days do begin
        time_range = day+[0,secofday]
        print, time_string(day)
        rbsp_efw_read_l1, time_range, probe=probe, datatype='esvy'
        var = prefix+'efw_esvy'
        get_data, var, times, vsvy
        time_step = sdatarate(times)
        dtimes = times[1:-1]-times[0:-2]
        all_ss = sort_uniq(round(1d/dtimes))
        index = where(all_ss gt 1, count)
        if count eq 0 then all_ss = 0 else all_ss = all_ss[index]

        msg = 'RBSP-'+strupcase(probe)+tab+$
            time_string(day,tformat='YYYY-MM-DD')+tab+$
            strjoin(string(all_ss,format='(I4)'),'  ')
        lprmsg, msg, log_file
    endforeach
endforeach



end
