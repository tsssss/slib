;+
; Check spikes around the day change.
;-

;---Settings.
    secofday = constant('secofday')
    time_range = time_double('2015-07-01/00:00:01.785919')+[-1,1]*10
    time_range = time_double('2015-06-12/10:39:24.615325')+[-1,1]*60
;    time_range = time_double('2017-01-01')+[-1,1]*10
;    time_range = time_double('2015-07-16/00:00:01.785919')+[-3,1]*secofday
    probe = 'b'


;---Derived quantities.
    prefix = 'rbsp'+probe+'_'
    common_time_step = 10.
    common_times = make_bins(time_range, common_time_step)
    xyz = constant('xyz')
    uvw = constant('uvw')
    the_time_range = mean(time_range)+[-1,1]*60
    rgb = constant('rgb')


;---Load data.
    ;rbsp_efw_phasef_read_wobble_free_var, time_range, probe=probe
    timespan, time_range[0], total(time_range*[-1,1]), /seconds
    rbsp_load_efw_waveform, probe=probe, datatype='esvy', type='raw', coord='uvw', /noclean, trange=time_range
    rbsp_read_emfisis, probe=probe, id='l2%magnetometer', time_range
    bvar = prefix+'b_uvw'
    options, bvar, 'colors', rgb
    evar_old = prefix+'efw_esvy'
    get_data, evar_old, times, data
    data[*,2] = !values.f_nan
    store_data, evar_old, times, data
    evar_new = prefix+'e_mgse'
    get_data, evar_new, times, data
    data[*,0] = !values.f_nan
    store_data, evar_new, times, data
    options, evar_old, 'colors', constant('rgb')
    tplot_options, 'labflag', -1
    sgopen, 0, xsize=8, ysize=5
    tplot, [evar_old,bvar], trange=time_range


end
