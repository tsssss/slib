;+
; We know that the L1 esvy and vsvy data has time tag irregularities,
; which are jumps of 1 sec backward in time tag.
;
; Here, we want to check if the same issue exists in b1 data.
;-

pad_time = 60d
log_file = join_path([srootdir(),'check_l1_time_tag_irregularity_for_b1_data.log'])
if file_test(log_file) eq 1 then file_delete, log_file
ftouch, log_file

foreach probe, ['a','b'] do begin
    lprmsg, 'Checking B1 data for RBSP-'+strupcase(probe)+' ...', log_file

    prefix = 'rbsp'+probe+'_'
    rbsp_efw_read_l1_time_tag_irregularity, probe=probe
    get_data, prefix+'efw_l1_paired_jumps', tmp, paired_jumps
    get_data, prefix+'efw_l1_isolated_jumps', tmp, isolated_jumps
    start_times = [paired_jumps.section_start.previous_times,isolated_jumps.previous_times]
    end_times = [paired_jumps.section_end.current_times,isolated_jumps.current_times]

    ntime_range = n_elements(start_times)
    time_ranges = dblarr(ntime_range,2)
    time_ranges[*,0] = start_times
    time_ranges[*,1] = end_times

    b1_var = prefix+'vb1'
    for time_id=0,ntime_range-1 do begin
        the_time_range = reform(time_ranges[time_id,*]+[-1,1]*pad_time)
        lprmsg, 'Checking '+strjoin(time_string(the_time_range),' to ')+' ...', log_file
        del_data, b1_var
        rbsp_efw_phasef_read_b1_split, time_range, probe=probe, id='vb1'
        if tnames(b1_var) ne '' then begin
            get_data, b1_var, times
            dtime = times[1:-1]-times[0:-2]
            index = where(abs(round(dtime)) eq 1, count)
            if count ne 0 then begin
                lprmsg, 'Found a time tag irregularity in B1 ...', log_file
                lprmsg, time_string(times[index]), log_file
            endif
        endif
    endfor
endforeach


end
