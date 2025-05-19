;+
; Check the spin tone along w in E and B.
;-

;---Input.
    date = time_double('2013-06-19')
    probe = 'b'

;---Other settings.
    secofday = constant('secofday')
    xyz = constant('xyz')
    full_time_range = date+[0,secofday]
    prefix = 'rbsp'+probe+'_'
    spin_period = 11d
    common_time_step = 1d/16
    smooth_width = spin_period/common_time_step

;---Find the perigee.
    rbsp_read_orbit, full_time_range, probe=probe
    dis = snorm(get_var_data(prefix+'r_gsm', times=times))
    perigee_lshell = 1.15
    perigee_times = times[where(dis le perigee_lshell)]
    orbit_time_step = total(times[0:1]*[-1,1])
    perigee_time_ranges = time_to_range(perigee_times, time_step=orbit_time_step)
    time_range = reform(perigee_time_ranges[1,*])
    common_times = make_bins(time_range, common_time_step)
    ncommon_time = n_elements(common_times)


    ; Load data in UVW.
    data_time_range = time_range
    timespan, data_time_range[0], total(data_time_range*[-1,1]), /seconds
    rbsp_load_efw_waveform, probe=probe, datatype='esvy', type='cal', coord='uvw', /noclean, trange=data_time_range
    rbsp_read_emfisis, probe=probe, time_range, id='l2%magnetometer'
    e_uvw = get_var_data(prefix+'b_uvw', at=common_times)
    lags = make_bins([-1,1]*0.5*smooth_width,1)
    coefs = c_correlate(e_uvw[*,0],e_uvw[*,1], lags)
    tmp = max(coefs, max_lag)
    shift_lag = max_lag-0.25*smooth_width
    e_uvw[*,0] = shift(e_uvw[*,0], -shift_lag)
    euv = snorm(e_uvw[*,0:1])
    ew = e_uvw[*,2]
    euv_bg = rbsp_remove_spintone(euv, common_times)
    ew_bg = rbsp_remove_spintone(ew, common_times)
    euv_fg = euv-euv_bg
    ew_fg = ew-ew_bg
    
    store_data, prefix+'ew_fg', common_times, ew_fg
    store_data, prefix+'ew_bg', common_times, ew_bg
    store_data, prefix+'euv_fg', common_times, euv_fg
    store_data, prefix+'euv_bg', common_times, euv_bg
    stop

end
