;+
; Test to reduce residue of the perigee E field.
; To show now offset removal works.
;-


pro test_perigee_correction_new_e_offset, test_time, probe=probe


test = 1

;---Constant.
    secofday = constant('secofday')
    xyz = constant('xyz')
    ndim = 3

;---Settings.
    prefix = 'rbsp'+probe+'_'
    perigee_shell = 4.  ; Re.
    time_range = (n_elements(test_time) eq 1)? test_time+[0,secofday]: test_time
    plot_dir = join_path([googledir(),'works','rbsp_phase_f','plot','test_perigee_new_e_offset'])


;---Load basic data.
    rbsp_read_efield, time_range, probe=probe, resolution='hires'
    rbsp_read_orbit, time_range, probe=probe
    rbsp_read_sc_vel, time_range, probe=probe
    rbsp_read_quaternion, time_range, probe=probe

    ; Magnetic field.
    rbsp_read_bfield, time_range, probe=probe
;    dt = 1d/16
;    rbsp_read_emfisis, time_range, id='l2%magnetometer', probe=probe
;    uniform_time, prefix+'b_uvw', dt
;    rbsp_emfisis_remove_perigee_spike, prefix+'b_uvw'
;    b_uvw = get_var_data(prefix+'b_uvw', times=times)
;    spin_period = 11d
;    width = spin_period/dt
;    for ii=0,1 do begin
;        offset1 = smooth(b_uvw[*,ii], width, /nan, /edge_zero)
;        offset2 = smooth(offset1, width, /nan, /edge_zero)
;        b_uvw[*,ii] -= offset2
;    endfor
;    store_data, prefix+'b_uvw', times, b_uvw
;    add_setting, prefix+'b_uvw', /smart, dictionary($
;        'display_type', 'vector', $
;        'unit', 'nT', $
;        'short_name', 'B', $
;        'coord', 'UVW', $
;        'coord_labels', ['u','v','w'] )
;    rbsp_uvw2gsm, prefix+'b_uvw', prefix+'b_gsm', probe=probe


;---Prepare data on common times.
    common_time_step = 1
    common_times = make_bins(time_range, common_time_step)
    ncommon_time = n_elements(common_times)

    tplot_options, 'ynozero', 1
    tplot_options, 'labflag', -1


    foreach var, prefix+['v','r'] do begin
        var_in = var+'_gse'
        get_data, var_in, times, data, limits=limits
        data = sinterpol(data, times, common_times, quadratic=1)
        var_out = var+'_mgse'
        data = cotran(data, common_times, 'gse2mgse', probe=probe)
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
    index = where(finite(snorm(b_mgse)))
    b_mgse = sinterpol(b_mgse[index,*], times[index], times)
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
    coefs = fltarr(nperigee_time_range, ndim, ndim)
    for id=1,nperigee_time_range-2 do begin
        the_time_range = reform(perigee_time_ranges[id,*])
        ;the_time_range = time_double(['2013-03-01/08:15','2013-03-01/08:16'])


    ;---Get u_mgse = v_mgse-vcoro_mgse.
        v_mgse = get_var_data(prefix+'v_mgse', in=the_time_range, times=times)*1e-3
        vcoro_mgse = get_var_data(prefix+'vcoro_mgse', in=the_time_range)*1e-3
        u_mgse = (v_mgse-vcoro_mgse)   ; to get mV/m directly when xB.
        e_mgse = get_var_data(prefix+'e_mgse', in=the_time_range)
        b_mgse = get_var_data(prefix+'b_mgse', in=the_time_range)
        ;pflux_grant_read_level1_data, time_range, probe=probe, id='bfield'
        ;bmod_gsm = get_var_data(prefix+'bmod_gsm', at=times)
        ;b_mgse = cotran(bmod_gsm, times, 'gsm2mgse', probe=probe)
        de_mgse = e_mgse-vec_cross(u_mgse,b_mgse)


        ntime = n_elements(times)
        xxs = fltarr(ndim,ntime,ndim)
    ;---Rotation on Vsc.
;        ; For Ey.
;        xxs[0,*,1] = -v_mgse[*,1]*b_mgse[*,0]
;        xxs[1,*,1] =  v_mgse[*,0]*b_mgse[*,0]+v_mgse[*,2]*b_mgse[*,2]
;        xxs[2,*,1] = -v_mgse[*,1]*b_mgse[*,2]
;        ; For Ez.
;        xxs[0,*,2] = -v_mgse[*,2]*b_mgse[*,0]
;        xxs[1,*,2] = -v_mgse[*,2]*b_mgse[*,1]
;        xxs[2,*,2] =  v_mgse[*,0]*b_mgse[*,0]+v_mgse[*,1]*b_mgse[*,1]

    ;---Rotation on B.
        ; For Ey.
        xxs[0,*,1] =  u_mgse[*,0]*b_mgse[*,1]
        xxs[1,*,1] = -u_mgse[*,0]*b_mgse[*,0]-u_mgse[*,2]*b_mgse[*,2]
        xxs[2,*,1] =  u_mgse[*,2]*b_mgse[*,1]
        ; For Ez.
        xxs[0,*,2] =  u_mgse[*,0]*b_mgse[*,2]
        xxs[1,*,2] =  u_mgse[*,1]*b_mgse[*,0]
        xxs[2,*,2] = -u_mgse[*,0]*b_mgse[*,0]-u_mgse[*,1]*b_mgse[*,1]


        foreach ii, fit_index do begin
            xx = xxs[*,*,ii]
            yy = de_mgse[*,ii]
            res = regress(xx,yy, sigma=sigma, const=const, measure_errors=measure_errors)
            coefs[id,*,ii] = res

            res = (ii eq 1)? [0.0111,-0.025,0.088]: [-0.012,-0.008,-0.008]

            var = prefix+'de'+xyz[ii]
            yfit = reform(xx ## res)+const
            store_data, var, times, [[yy],[yfit]], limits={$
                ytitle:'(mV/m)', labels:['E'+xyz[ii],'Regression'], colors:sgcolor(['blue','red'])}

            var = prefix+'e'+xyz[ii]
            store_data, var, times, yy-yfit, limits={ytitle:'(mV/m)', labels:'dE'+xyz[ii]}
        endforeach

        plot_file = join_path([plot_dir,'fig_test_regression_'+prefix+strjoin(time_string(the_time_range,tformat='YYYY_MMDD_hhmm'),'_')+'_v01.pdf'])
        if keyword_set(test) then plot_file = test
        sgopen, plot_file, xsize=6, ysize=6, /inch, xchsz=xchsz, ychsz=ychsz
        tplot_options, 'yticklen', -0.015
        tplot_options, 'xticklen', -0.03
        tplot, prefix+['de'+xyz[fit_index],'e'+xyz[fit_index]], $
            trange=the_time_range, window=plot_file, $
            get_plot_position=poss
        foreach ii, fit_index do begin
            res = coefs[id,*,ii]

            tpos = poss[*,ii-1]
            tx = tpos[0]+xchsz*0.5
            ty = tpos[3]-ychsz*1
            msg = 'Coefs: '+strjoin(string(res,format='(F8.4)'),',')
            xyouts, tx,ty,/normal, msg, charsize=0.8
        endforeach

        if keyword_set(test) then stop
        sgclose
    endfor

    store_data, prefix+'regression_coef', 0, coefs

end


;probes = ['a','b']
;years = ['2013','2014','2015','2016','2017']
;months = ['03','06','09','12']
;dates = []
;foreach year, years do foreach month, months do dates = [dates, year+'-'+month+'-01']
;test_times = time_double(dates)
;foreach probe, probes do foreach test_time, test_times do test_perigee_correction_new_e_offset, test_time, probe=probe

probe = 'a'
dates = ['2013-07-15','2013-07-26']
dates = ['2013-07-15','2013-07-17']
dates = ['2013-06-01','2013-06-03']
test_times = time_double(dates)
test_perigee_correction_new_e_offset, test_times, probe=probe
end
