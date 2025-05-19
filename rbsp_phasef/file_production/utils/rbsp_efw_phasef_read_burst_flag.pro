;+
; Save rbspx_burst[1,2]_avail.
; Adopted from rbsp_get_burst_times_rates_list.
;-

pro rbsp_efw_phasef_read_burst1_flag, time_range, probe=probe

    ; d0 and d1 are the start and end times.
    root_dir = srootdir()
    file = join_path([root_dir,'burst1_times_rates_RBSP'+probe+'.sav'])
    if file_test(file) eq 0 then message, 'No input data ...'
    restore, file
    time_ranges = time_double([[d0],[d1]])
    
    time_step = 1.
    common_times = make_bins(time_range, time_step)
    ncommon_time = n_elements(common_times)
    flags = fltarr(ncommon_time)
    
    index = where(time_ranges[*,1] ge time_range[0] and time_ranges[*,0] le time_range[1], nsection)
    if nsection ne 0 then begin
        time_ranges = time_ranges[index,*]
        for ii=0,nsection-1 do begin
            index = where_pro(common_times, '[]', time_ranges[ii,*], count=count)
            if count eq 0 then continue
            flags[index] = 1
        endfor
    endif
    
    prefix = 'rbsp'+probe+'_'
    store_data, prefix+'burst1_avail', common_times, flags

end

pro rbsp_efw_phasef_read_burst2_flag, time_range, probe=probe

    ; d0 and d1 are the start and end times.
    root_dir = srootdir()
    file = join_path([root_dir,'burst2_times_RBSP'+probe+'.sav'])
    if file_test(file) eq 0 then message, 'No input data ...'
    restore, file
    time_ranges = time_double([[d0],[d1]])

    time_step = 1.
    common_times = make_bins(time_range, time_step)
    ncommon_time = n_elements(common_times)
    flags = fltarr(ncommon_time)
    
    index = where(time_ranges[*,1] ge time_range[0] and time_ranges[*,0] le time_range[1], nsection)
    if nsection ne 0 then begin
        pad_time = 6.
        time_ranges = time_ranges[index,*]
        for ii=0,nsection-1 do begin
            index = where_pro(common_times, '[]', time_ranges[ii,*]+[-1,1]*pad_time, count=count)
            if count eq 0 then continue
            flags[index] = 1
        endfor
    endif

    prefix = 'rbsp'+probe+'_'
    store_data, prefix+'burst2_avail', common_times, flags

end



pro rbsp_efw_phasef_read_burst_flag, time_range, probe=probe

    rbsp_efw_phasef_read_burst1_flag, time_range, probe=probe
    rbsp_efw_phasef_read_burst2_flag, time_range, probe=probe
    vars = 'rbsp'+probe+'_burst'+['1','2']+'_avail'
    options, vars, 'yrange', [-0.2,1.2]

end

time_range = time_double(['2013-06-07','2013-06-08'])
time_range = time_double(['2015-12-14','2015-12-15'])
probe = 'b'
rbsp_efw_phasef_read_burst_flag, time_range, probe=probe
end