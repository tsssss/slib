;+
; Load fixed quantities and calc the perigee residue, then fit.
; Read basic quantities directly from the saved CDF.
;-


pro test_perigee_residue_correction_save_file, day, probe=probe

    prefix = 'rbsp'+probe+'_'
    secofday = constant('secofday')
    time_range = time_double(day)+[0,secofday]
    xyz = constant('xyz')


;---Prepare low-level quantities.
    rbsp_efw_phasef_read_wobble_free_var, time_range, probe=probe, id='quaternion'
    rbsp_efw_phasef_read_wobble_free_var, time_range, probe=probe

;---Common times.
    common_time_step = 10.
    common_times = make_bins(time_range, common_time_step)


;---Calculate E-E_coro-E_vxb.
    vcoro_mgse = calc_vcoro(r_var=prefix+'r_mgse', probe=probe)
    vcoro_var = prefix+'vcoro_mgse'
    store_data, vcoro_var, common_times, vcoro_mgse
    add_setting, vcoro_var, /smart, dictionary($
        'display_type', 'vector', $
        'unit', 'km/s', $
        'short_name', 'Coro V', $
        'coord', 'MGSE', $
        'coord_labels', xyz)


;---Select a perigee.
    perigee_shell = 3.
    r_var = prefix+'r_mgse'
    dis = snorm(get_var_data(r_var))
    store_data, prefix+'dis', common_times, dis
    add_setting, prefix+'dis', /smart, dictionary($
        'display_type', 'scalar', $
        'unit', 'Re', $
        'yrange', [1,6], $
        'yticks', 5, $
        'yminor', 2, $
        'short_name', '|R|' )
    perigee_index = where(dis le perigee_shell)
    perigee_times = common_times[perigee_index]
    perigee_time_ranges = time_to_range(perigee_times, time_step=common_time_step)
    nperigee_time_range = n_elements(perigee_time_ranges)*0.5
    if nperigee_time_range lt 1 then return
    perigee_time_range = reform(perigee_time_ranges[1,*])
    perigee_time_range = time_range


;---Remove eclipse.
    rbsp_read_eclipse_flag, time_range, probe=probe
    flag_var = prefix+'eclipse_flag'
    flags = get_var_data(flag_var, times=times)
    index = where(flags eq 1, count)
    fillval = !values.f_nan
    if count ne 0 then begin
        e_mgse = get_var_data(prefix+'e_mgse')
        the_time_step = total(times[0:1]*[-1,1])
        time_ranges = time_to_range(times[index], time_step=the_time_step, pad_time=the_time_step)
        ntime_range = n_elements(time_ranges)*0.5
        for ii=0,ntime_range-1 do begin
            index = where_pro(common_times,'[]',time_ranges[ii,*], count=count)
            if count eq 0 then continue
            e_mgse[index,*] = fillval
        endfor
        store_data, prefix+'e_mgse', common_times, e_mgse
    endif
    
    
    rbsp_efw_read_boom_flag, time_range, probe=probe
    flag_var = prefix+'boom_flag'
    flags = total(get_var_data(flag_var, times=times),2)
    index = where(flags ne 4, count)
    if count ne 0 then begin
        e_mgse = get_var_data(prefix+'e_mgse')
        the_time_step = total(times[0:1]*[-1,1])
        time_ranges = time_to_range(times[index], time_step=the_time_step, pad_time=the_time_step)
        ntime_range = n_elements(time_ranges)*0.5
        for ii=0,ntime_range-1 do begin
            index = where_pro(common_times,'[]',time_ranges[ii,*], count=count)
            if count eq 0 then continue
            e_mgse[index,*] = fillval
        endfor
        store_data, prefix+'e_mgse', common_times, e_mgse
    endif


;---Some quantities to be saved.
    b_mgse = get_var_data(prefix+'b_mgse')
    v_mgse = get_var_data(prefix+'v_mgse')*1e-3
    evxb_mgse = vec_cross(v_mgse,b_mgse)
    evxb_var = prefix+'evxb_mgse'
    store_data, evxb_var, common_times, evxb_mgse
    add_setting, evxb_var, /smart, dictionary($
        'display_type', 'vector', $
        'unit', 'mV/m', $
        'short_name', 'VxB E', $
        'coord', 'MGSE', $
        'coord_labels', xyz)

    vcoro_mgse = get_var_data(prefix+'vcoro_mgse', in=perigee_time_range)*1e-3
    ecoro_mgse = -vec_cross(vcoro_mgse,b_mgse)
    ecoro_var = prefix+'ecoro_mgse'
    store_data, ecoro_var, common_times, ecoro_mgse
    add_setting, ecoro_var, /smart, dictionary($
        'display_type', 'vector', $
        'unit', 'mV/m', $
        'short_name', 'Coro E', $
        'coord', 'MGSE', $
        'coord_labels', xyz)

    emod_mgse = evxb_mgse+ecoro_mgse
    emod_raw_var = prefix+'emod_raw_mgse'
    store_data, emod_raw_var, common_times, emod_mgse
    add_setting, emod_raw_var, /smart, dictionary($
        'display_type', 'vector', $
        'unit', 'mV/m', $
        'short_name', 'VxB+Coro E', $
        'coord', 'MGSE', $
        'coord_labels', xyz )

    e_mgse_var = prefix+'e_mgse'
    e_mgse = get_var_data(e_mgse_var)
    de_mgse = e_mgse-emod_mgse
    de_mgse[*,0] = 0
    de_mgse_var = prefix+'de_mgse'
    store_data, de_mgse_var, common_times, de_mgse
    add_setting, de_mgse_var, /smart, dictionary($
        'display_type', 'vector', $
        'unit', 'mV/m', $
        'short_name', 'dE', $
        'yrange', [-1,1]*10, $
        'yticks', 2, $
        'yminor', 5, $
        'coord', 'MGSE', $
        'coord_labels', xyz )

    fit_index = [1,2]
    foreach ii, fit_index do begin
        the_var = prefix+'de'+xyz[ii]
        store_data, the_var, common_times, de_mgse[*,ii]
        add_setting, the_var, /smart, dictionary($
            'display_type', 'scalar', $
            'constant', 0, $
            'yrange', [-1,1]*12, $
            'yticks', 6, $
            'yminor', 5, $
            'unit', 'mV/m', $
            'short_name', 'MGSE dE'+xyz[ii] )
    endforeach


;---Fit.
    ndim = 3
    ntime = n_elements(perigee_times)
    ncommon_time = n_elements(common_times)
    xxs = fltarr(ndim,ncommon_time,ndim)
    u_mgse = v_mgse-vcoro_mgse
;    u_mgse = u_mgse[perigee_index,*]
;    b_mgse = b_mgse[perigee_index,*]
;    de_mgse = de_mgse[perigee_index,*]

    ; Rotation on B.
    ; For Ey.
    xxs[0,*,1] =  u_mgse[*,0]*b_mgse[*,1]
    xxs[1,*,1] = -u_mgse[*,0]*b_mgse[*,0]-u_mgse[*,2]*b_mgse[*,2]
    xxs[2,*,1] =  u_mgse[*,2]*b_mgse[*,1]
    ; For Ez.
    xxs[0,*,2] =  u_mgse[*,0]*b_mgse[*,2]
    xxs[1,*,2] =  u_mgse[*,1]*b_mgse[*,0]
    xxs[2,*,2] = -u_mgse[*,0]*b_mgse[*,0]-u_mgse[*,1]*b_mgse[*,1]


    ; Coef.
    ; RBSP-A.
    ; Ey: [-0.010,-0.006,-0.010]
    ; Ez: [-0.018,-0.020,-0.032]
    ; RBSP-B.
    ; Ey: [ 0.004,-0.010, 0.010]
    ; Ez: [-0.020,-0.010,-0.020]
    efit_mgse = fltarr(ncommon_time,ndim)
;    foreach ii, fit_index do begin
;        xx = xxs[*,perigee_index,ii]
;        yy = de_mgse[perigee_index,ii]
;        index = where(finite(yy), count)
;        if count eq 0 then break
;        res = regress(xx[*,index],yy[index], sigma=sigma, const=const, measure_errors=measure_errors)
;
;        case probe of
;            'a': res = (ii eq 1)? [-0.000,-0.000,-0.000]: [-0.018,-0.020,-0.032]
;            'b': res = (ii eq 1)? [ 0.004,-0.010, 0.010]: [-0.020,-0.010,-0.020]
;        endcase
;
;        var = prefix+'de'+xyz[ii]
;        yfit = reform(xxs[*,*,ii] ## res);+const
;        efit_mgse[*,ii] = yfit
;        store_data, var, common_times, [[de_mgse[*,ii]],[yfit]], limits={$
;            ytitle:'(mV/m)', $
;            labels:['E'+xyz[ii],'Regression'], $
;            colors:sgcolor(['blue','red']), $
;            yticks: 2, $
;            yrange: [-1,1]*10, $
;            ystyle: 1, $
;            yminor: 5, $
;            fit_coef: res }
;
;        var = prefix+'e'+xyz[ii]
;        store_data, var, common_times, de_mgse[*,ii]-yfit, limits={$
;            ytitle:'(mV/m)', $
;            labels:'dE'+xyz[ii], $
;            yticks: 2, $
;            yrange: [-1,1]*4, $
;            ystyle: 1, $
;            yminor: 4 }
;    endforeach


    efit_mgse_var = prefix+'efit_mgse'
    store_data, efit_mgse_var, common_times, efit_mgse
    add_setting, efit_mgse_var, /smart, dictionary($
        'display_type', 'vector', $
        'unit', 'mV/m', $
        'short_name', 'fit dE', $
        'yrange', [-1,1]*10, $
        'yticks', 2, $
        'yminor', 5, $
        'coord', 'MGSE', $
        'coord_labels', xyz )


    de_var = prefix+'de_mgse'
    de_mgse = e_mgse-ecoro_mgse-evxb_mgse-efit_mgse
    de_mgse[*,0] = 0
    store_data, de_var, common_times, de_mgse
    add_setting, de_var, /smart, dictionary($
        'display_type', 'vector', $
        'unit', 'mV/m', $
        'short_name', 'dE', $
        'yticks', 2, $
        'yrange', [-1,1]*4, $
        'ystyle', 1, $
        'yminor', 4, $
        'coord', 'MGSE', $
        'coord_labels', xyz )

    save_vars = list()
;    save_vars.add, prefix+['e','b','r','v']+'_mgse', /extract
    save_vars.add, prefix+['e']+'_mgse', /extract
    save_vars.add, prefix+['ecoro','evxb','e_fit','de']+'_mgse', /extract
    save_vars = save_vars.toarray()

    base_name = prefix+'test_perigee_correction_'+time_string(time_range[0],tformat='YYYY_MMDD')+'_v01'
    ;tplot_file = join_path([googledir(),'works','rbsp_phase_f','data','wygant_maneuver',base_name+'.tplot'])
    ;tplot_save, save_vars, filename=tplot_file

    cdf_file = join_path([googledir(),'works','rbsp_phase_f','data','rbsp'+probe,$
        time_string(time_range[0],tformat='YYYY'),base_name+'.cdf'])
    epochs = stoepoch(common_times,'unix')
    time_var = 'Epoch'
    cdf_save_var, time_var, value=epochs, filename=cdf_file
    cdf_save_setting, varname=time_var, filename=cdf_file, dictionary($
        'FIELDNAM', 'Epoch', $
        'UNITS', 'ms', $
        'VAR_TYPE', 'support_data' )

    foreach var, save_vars do begin
        data = get_var_data(var, limits=lims)
        settings = dictionary()
        settings['DEPEND_0'] = time_var
        settings['VAR_TYPE'] = 'data'
        settings['FIELDNAM'] = var
        settings['UNITS'] = lims.unit
        cdf_save_var, var, value=data, filename=cdf_file
        cdf_save_setting, varname=var, filename=cdf_file, settings
    endforeach

    ;tplot, prefix+['dey','dez','ey','ez'], trange=time_range
    ;stop


;;---Plot.
;test = 1
;    plot_dir = join_path([googledir(),'works','rbsp_phase_f','plot','test_perigee_residue_removal_fit'])
;    plot_file = join_path([plot_dir,'fig_test_perigee_residue_removal_fit_'+prefix+strjoin(time_string(perigee_time_range,tformat='YYYY_MMDD_hhmm'),'_')+'_v01.pdf'])
;    plot_file = join_path([plot_dir,'fig_test_perigee_residue_removal_fit_'+prefix+time_string(time_range[0],tformat='YYYY_MMDD')+'_v01.pdf'])
;    if keyword_set(test) then plot_file = 0
;    sgopen, plot_file, xsize=6, ysize=6, /inch, xchsz=xchsz, ychsz=ychsz
;    tplot_options, 'yticklen', -0.015
;    tplot_options, 'xticklen', -0.03
;    tplot_options, 'labflag', -1
;    vars = prefix+'de'+xyz[fit_index]
;    options, vars, 'yrange', [-1,1]*10
;    vars = prefix+'e'+xyz[fit_index]
;    options, vars, 'yrange', [-1,1]*10
;    options, vars, 'constant', [-1,1]*2
;
;    tplot, prefix+['de'+xyz[fit_index],'e'+xyz[fit_index],'dis'], $
;        trange=perigee_time_range, window=plot_file, $
;        get_plot_position=poss
;
;    foreach ii, fit_index do begin
;        res = get_setting(prefix+'de'+xyz[ii], 'fit_coef')
;
;        tpos = poss[*,ii-1]
;        tx = tpos[0]+xchsz*0.5
;        ty = tpos[3]-ychsz*1
;        msg = 'Coefs: '+strjoin(string(res,format='(F8.4)'),',')
;        xyouts, tx,ty,/normal, msg, charsize=0.8
;    endforeach
;
;    if keyword_set(test) then stop
;    sgclose

end




;---Inputs.
;probes = ['a']
;days = make_bins(time_double(['2012-09-05','2019-10-15']), constant('secofday'))

probes = ['b']
days = make_bins(time_double(['2012-09-05','2019-07-17']), constant('secofday'))

;probes = ['b']
;days = make_bins(time_double(['2017-02-11','2017-02-13']), constant('secofday'))    ; V34 bad.
;days = make_bins(time_double(['2018-05-15','2018-05-19']), constant('secofday'))    ; V34 bad.
;days = make_bins(time_double(['2018-09-27','2018-09-28']), constant('secofday'))    ; wrong phase.
;
;probes = ['a']
;days = make_bins(time_double(['2015-12-29','2015-12-30']), constant('secofday'))

foreach probe, probes do begin
    foreach day, days do begin
        test_perigee_residue_correction_save_file, day, probe=probe
    endforeach
endforeach
end
