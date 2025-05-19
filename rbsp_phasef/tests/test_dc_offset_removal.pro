;+
; Test different methods to remove DC offset in Eu and Ev.
;-


time_range = time_double(['2012-11-01','2012-11-02'])
plot_time_range = time_double('2012-11-01/05:55')+[0,40]
probe = 'a'

prefix = 'rbsp'+probe+'_'
xyz = constant('xyz')
uvw = constant('uvw')
rgb = constant('rgb')
ndim = 3

;---Load data. Save rbspx_efw_esvy_[16,32].
    timespan, time_range[0], total(time_range*[-1,1]), /seconds
    rbsp_efw_read_l1, time_range, probe=probe, datatype='esvy'
    rbsp_efw_read_l1, time_range, probe=probe, datatype='vsvy'
    store_data, prefix+'efw_esvy', dlim={data_att:{units:'mV/m'}}
    store_data, prefix+'efw_vsvy', dlim={data_att:{units:'V'}}
    rbsp_efw_cal_waveform, probe=probe, datatype='esvy', trange=time_range
    rbsp_efw_cal_waveform, probe=probe, datatype='vsvy', trange=time_range

    cp0 = rbsp_efw_get_cal_params(time_range[0])
    cp = (probe eq 'a')? cp0.a: cp0.b
    boom_length = cp.boom_length

    get_data, prefix+'efw_vsvy', times, vsvy
    boom_len = [100,100,10]
    eu = (vsvy[*,0]-vsvy[*,1])/boom_length[0]*1e3
    ev = (vsvy[*,2]-vsvy[*,3])/boom_length[1]*1e3
    ew = (vsvy[*,4]-vsvy[*,5])/boom_length[2]*1e3
    store_data, prefix+'efw_esvy_16', times, [[eu],[ev],[ew]]

    copy_data, prefix+'efw_esvy', prefix+'efw_esvy_32'
    get_data, prefix+'efw_esvy_32', common_times
    ntime = n_elements(common_times)
    resolutions = ['16','32']
    evars = prefix+'efw_esvy_'+resolutions


;---Method 1. Smoothing.
;---Method 2. Median.
    window = 11.
    foreach res, resolutions do begin
        var = prefix+'efw_esvy_'+res
        get_data, var, times, e_uvw
        time_step = sdatarate(times)
        width = window/time_step

    ;---Smoothing.
        eu = e_uvw[*,0]
        ev = e_uvw[*,1]
        store_data, prefix+'eu_'+res, times, eu
        store_data, prefix+'ev_'+res, times, ev

        eu_bg1 = smooth(eu, width, /nan)
        ev_bg1 = smooth(ev, width, /nan)
        store_data, prefix+'eu_bg1_'+res, times, eu_bg1
        store_data, prefix+'ev_bg1_'+res, times, eu_bg1
        store_data, prefix+'eu1_'+res, times, eu-eu_bg1
        store_data, prefix+'ev1_'+res, times, ev-ev_bg1
        store_data, prefix+'euv1_'+res, times, sqrt((eu-eu_bg1)^2+(ev-ev_bg1)^2)


        eu_bg2 = smooth(eu_bg1, width, /nan)
        ev_bg2 = smooth(ev_bg1, width, /nan)
        store_data, prefix+'eu_bg2_'+res, times, eu_bg2
        store_data, prefix+'ev_bg2_'+res, times, ev_bg2
        store_data, prefix+'eu2_'+res, times, eu-eu_bg2
        store_data, prefix+'ev2_'+res, times, ev-ev_bg2
        store_data, prefix+'euv2_'+res, times, sqrt((eu-eu_bg2)^2+(ev-ev_bg2)^2)


        eu_bg3 = smooth(eu_bg2, width, /nan)
        ev_bg3 = smooth(ev_bg2, width, /nan)
        store_data, prefix+'eu_bg3_'+res, times, eu_bg3
        store_data, prefix+'ev_bg3_'+res, times, ev_bg3
        store_data, prefix+'eu3_'+res, times, eu-eu_bg3
        store_data, prefix+'ev3_'+res, times, ev-ev_bg3
        store_data, prefix+'euv3_'+res, times, sqrt((eu-eu_bg3)^2+(ev-ev_bg3)^2)



    ;---Median.
        time_step_median = 10.
        min_count = 0.6*window/time_step
        median_times = make_bins(time_range, time_step_median)
        ntime = n_elements(median_times)
        eu_bg = fltarr(ntime)+!values.f_nan
        ev_bg = fltarr(ntime)+!values.f_nan
        for time_id=0,ntime-1 do begin
            sec_time = median_times[time_id]+[-1,1]*window*0.5
            time_index = where_pro(times, '[]', sec_time, count=count)
            if count lt min_count then continue
            eu_bg[time_id] = median(eu[time_index])
            ev_bg[time_id] = median(ev[time_index])
        endfor
        store_data, prefix+'eu_bgm_'+res, median_times, eu_bg
        store_data, prefix+'ev_bgm_'+res, median_times, ev_bg


        sgopen, 0, xsize=5, ysize=5
        vars = prefix+['eu_','eu_bg'+['1','2','3']+'_','euv'+['1','2','3']+'_']+res
        nvar = n_elements(vars)
        tpos = sgcalcpos(nvar, margin=[15,4,4,2])

        tplot_options, 'version', 1
        tplot, vars, trange=plot_time_range, position=tpos

        stop
    endforeach



end
