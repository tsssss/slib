;+
; Test to reduce residue of the perigee E field.
; Use regression of 9 combinations.
;-


pro test_perigee_correction_regression2, test_time, probe=probe


test = 0

;---Constant.
    secofday = constant('secofday')
    xyz = constant('xyz')
    ndim = 3

;---Settings.
    prefix = 'rbsp'+probe+'_'
    perigee_shell = 4.  ; Re.
    time_range = (n_elements(test_time) eq 1)? test_time+[0,secofday]: test_time
    plot_dir = join_path([googledir(),'works','rbsp_phase_f','plot','test_perigee_emgse_regression'])


;---Load basic data.
    rbsp_read_efield, time_range, probe=probe, resolution='hires'
    rbsp_read_orbit, time_range, probe=probe
    rbsp_read_sc_vel, time_range, probe=probe
    rbsp_read_bfield, time_range, probe=probe
    rbsp_read_quaternion, time_range, probe=probe
    
    tplot_options, 'ynozero', 1
    tplot_options, 'labflag', -1


;---Prepare data on common times.
    common_time_step = 1
    common_times = make_bins(time_range, common_time_step)
    ncommon_time = n_elements(common_times)
    foreach var, prefix+['v','r'] do begin
        var_in = var+'_gsm'
        get_data, var_in, times, data, limits=limits
        data = sinterpol(data, times, common_times, quadratic=1)
        var_out = var+'_mgse'
        data = cotran(data, common_times, 'gsm2mgse', probe=probe)
        store_data, var_out, common_times, data
        limits.coord = 'MGSE'
        add_setting, var_out, /smart, limits
    endforeach

    foreach var, prefix+['b','e'] do begin
        var_in = var+'_gsm'
        get_data, var_in, times, data, limits=limits
        data = sinterpol(data, times, common_times, quadratic=0)
        var_out = var+'_mgse'
        data = cotran(data, common_times, 'gsm2mgse', probe=probe)
        store_data, var_out, common_times, data
        limits.coord = 'MGSE'
        add_setting, var_out, /smart, limits
    endforeach
    rbsp_emfisis_remove_perigee_spike, prefix+'b_mgse'
    get_data, prefix+'b_mgse', times, b_mgse
    b_mgse = rbsp_remove_spintone(b_mgse, times)
    store_data, prefix+'b_mgse', times, b_mgse
    
    foreach var, prefix+['r','v'] do begin
        the_var = var+'_mgse'
        get_data, the_var, times, vec
        vec = rbsp_remove_spintone(vec, times)
        store_data, the_var, times, vec
    endforeach

    vcoro_mgse = calc_vcoro(r_var=prefix+'r_mgse', probe=probe)
    store_data, prefix+'vcoro_mgse', common_times, vcoro_mgse


;---Get perigee times.
    r_var = prefix+'r_mgse'
    dis = snorm(get_var_data(r_var))
    perigee_times = common_times[where(dis le perigee_shell)]
    perigee_time_ranges = time_to_range(perigee_times, time_step=common_time_step)
    nperigee_time_range = n_elements(perigee_time_ranges)*0.5
    if nperigee_time_range lt 1 then return


    fit_index = [1,2]   ; y,z.
    nfit_index = n_elements(fit_index)
    coefs = fltarr(nperigee_time_range, ndim*ndim, ndim)
    for id=1,nperigee_time_range-2 do begin
        the_time_range = reform(perigee_time_ranges[id,*])
        ;the_time_range = time_double(['2013-03-01/08:15','2013-03-01/08:16'])


    ;---Get u_mgse = v_mgse-vcoro_mgse.
        v_mgse = get_var_data(prefix+'v_mgse', in=the_time_range, times=times)
        vcoro_mgse = get_var_data(prefix+'vcoro_mgse', in=the_time_range)
        u_mgse = (v_mgse-vcoro_mgse)*1e-3   ; to get mV/m directly when xB.
        e_mgse = get_var_data(prefix+'e_mgse', in=the_time_range)
        b_mgse = get_var_data(prefix+'b_mgse', in=the_time_range)
        de_mgse = e_mgse-vec_cross(u_mgse,b_mgse)
        
        
        ntime = n_elements(times)
        xx = fltarr(ndim*ndim,ntime)
        for ii=0,ndim-1 do for jj=0,ndim-1 do xx[ii*ndim+jj,*] = u_mgse[*,ii]*b_mgse[*,jj]
        foreach ii, fit_index do begin
            yy = de_mgse[*,ii]
            res = regress(xx,yy, sigma=sigma, const=const, measure_errors=measure_errors)
            coefs[id,*,ii] = res

            var = prefix+'de'+xyz[ii]
            yfit = reform(xx ## res)+const
            store_data, var, times, [[yy],[yfit]], limits={$
                ytitle:'(mV/m)', labels:['E'+xyz[ii],'Regression'], colors:sgcolor(['blue','red'])}

            var = prefix+'e'+xyz[ii]
            store_data, var, times, yy-yfit, limits={ytitle:'(mV/m)', labels:'dE'+xyz[ii]}
        endforeach

        plot_file = join_path([plot_dir,'fig_test_regression_'+prefix+strjoin(time_string(the_time_range,tformat='YYYY_MMDD_hhmm'),'_')+'_v01.pdf'])
        if keyword_set(test) then plot_file = test
        sgopen, plot_file, xsize=6, ysize=6, /inch
        tplot, prefix+['de'+xyz[fit_index],'e'+xyz[fit_index]], trange=the_time_range
        if keyword_set(test) then stop
        sgclose
    endfor

    store_data, prefix+'regression_coef', 0, coefs

end


probes = ['a','b']
years = ['2013','2014','2015','2016','2017']
months = ['03','06','09','12']
dates = []
foreach year, years do foreach month, months do dates = [dates, year+'-'+month+'-01']
test_times = time_double(dates)
foreach probe, probes do foreach test_time, test_times do test_perigee_correction_regression2, test_time, probe=probe

probes = ['a']
dates = ['2013-07-15','2013-07-26']
test_times = time_double(dates)
test_perigee_correction_regression2, test_times, probe=probe
end
