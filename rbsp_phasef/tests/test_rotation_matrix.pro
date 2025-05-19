;+
; Test to fix B uvw.
;-

;---Input.
    probe = 'b'
    day = time_double('2013-01-18')
    day = time_double('2013-01-13')
    ;probe = 'a'
    day = time_double('2013-07-16')
    day = time_double('2013-07-19')
    day = time_double('2013-07-20')
    day = time_double('2013-06-07')
    ;day = time_double('2012-10-02')


;---Settings.
    secofday = constant('secofday')
    time_range = day+[0,secofday]
    prefix = 'rbsp'+probe+'_'
    common_time_step = 1d/16
    common_times = make_bins(time_range, common_time_step)
    xyz = constant('xyz')
    uvw = constant('uvw')


;---Load quaternion and spin phase.
    if check_if_update(prefix+'q_uvw2gse', time_range) then begin
        rbsp_read_quaternion, time_range, probe=probe
        rbsp_fix_q_uvw2gse, time_range, probe=probe
    endif
stop


    rbsp_read_spice, time_range, probe=probe, id='spin_phase'
    spin_phase = get_var_data(prefix+'spin_phase', times=times)
    for ii=1, n_elements(times)-1 do begin
        if spin_phase[ii] ge spin_phase[ii-1] then continue
        spin_phase[ii:*] += 360
    endfor
    spin_phase = interpol(spin_phase, times, common_times)
    store_data, prefix+'spin_phase', common_times, spin_phase


;---Load B_uvw.
    if check_if_update(prefix+'b_mgse', time_range) then begin
        b_uvw_var = prefix+'b_uvw'
        rbsp_read_emfisis, time_range, probe=probe, id='l2%magnetometer'
        interp_time, b_uvw_var, common_times
        add_setting, b_uvw_var, /smart, dictionary($
            'display_type', 'vector', $
            'unit', 'nT', $
            'short_name', 'B', $
            'coord', 'UVW', $
            'coord_labels', uvw )

        ; Convert to DSC and fix wobble.
        rad = constant('rad')
        b_uvw = get_var_data(b_uvw_var)
        spin_phase = get_var_data(prefix+'spin_phase')*rad
        cost = cos(spin_phase)
        sint = sin(spin_phase)
        bx = b_uvw[*,0]*cost-b_uvw[*,1]*sint
        by = b_uvw[*,0]*sint+b_uvw[*,1]*cost
        spin_period = 11d
        width = spin_period/common_time_step
        bx_fix = smooth(bx, width, /nan, /edge_zero)
        by_fix = smooth(by, width, /nan, /edge_zero)
        store_data, prefix+'bx', common_times, [[bx],[bx_fix]], $
            limits={colors:sgcolor(['black','red']), labels:'DSC '+['Bx','Bx fix'], ytitle:'(nT)'}
        store_data, prefix+'by', common_times, [[by],[by_fix]], $
            limits={colors:sgcolor(['black','red']), labels:'DSC '+['By','By fix'], ytitle:'(nT)'}
        bu = bx_fix*cost+by_fix*sint
        bv =-bx_fix*sint+by_fix*cost
        bz_fix = smooth(b_uvw[*,2], width*2, /nan, /edge_zero)
        bw = bz_fix
        store_data, prefix+'bz', common_times, [[b_uvw[*,2]],[bz_fix]], $
            limits={colors:sgcolor(['black','red']), labels:'DSC '+['Bz','Bz fix'], ytitle:'(nT)'}
        b_uvw = [[bu],[bv],[bw]]
        b_mgse = cotran(b_uvw, common_times, 'uvw2mgse', probe=probe)
        b_mgse_var = prefix+'b_mgse'
        store_data, b_mgse_var, common_times, b_mgse
        add_setting, b_mgse_var, /smart, dictionary($
            'display_type', 'vector', $
            'unit', 'nT', $
            'short_name', 'B', $
            'coord', 'MGSE', $
            'coord_labels', xyz )
    endif


;---Load E field and position/velocity.
    rbsp_read_efield, time_range, probe=probe, resolution='hires'
    rbsp_read_orbit, time_range, probe=probe
    rbsp_read_sc_vel, time_range, probe=probe
    foreach var, prefix+['v','r','e'] do begin
        var_in = var+'_gse'
        get_data, var_in, times, data, limits=limits
        data = sinterpol(data, times, common_times, quadratic=1)
        var_out = var+'_mgse'
        data = cotran(data, common_times, 'gse2mgse', probe=probe)
        store_data, var_out, common_times, data
        limits.coord = 'MGSE'
        add_setting, var_out, /smart, limits
    endforeach


;---Check dE residue.
;    e_mgse_var = prefix+'e_mgse'
;    rbsp_remove_efield_bg, e_var=e_mgse_var, b_var=b_mgse_var, $
;        v_var=prefix+'v_mgse', r_var=prefix+'r_mgse', save_to=prefix+'de_mgse', probe=probe
;    get_data, prefix+'de_mgse', times, de_mgse
;    de_mgse[*,0] = 0
;    store_data, prefix+'de_mgse', times, de_mgse
;    stop


    r_var = prefix+'r_mgse'
    dis = snorm(get_var_data(r_var))
    perigee_shell = 4.  ; Re.
    perigee_times = common_times[where(dis le perigee_shell)]
    perigee_time_ranges = time_to_range(perigee_times, time_step=common_time_step)
    nperigee_time_range = n_elements(perigee_time_ranges)*0.5
    the_time_range = reform(perigee_time_ranges[1,*])
the_time_range = time_range

    vcoro_mgse = calc_vcoro(r_var=prefix+'r_mgse', probe=probe)
    store_data, prefix+'vcoro_mgse', common_times, vcoro_mgse


    v_mgse = get_var_data(prefix+'v_mgse', in=the_time_range, times=times)*1e-3
    vcoro_mgse = get_var_data(prefix+'vcoro_mgse', in=the_time_range)*1e-3
    u_mgse = (v_mgse-vcoro_mgse)   ; to get mV/m directly when xB.
    e_mgse = get_var_data(prefix+'e_mgse', in=the_time_range)
    b_mgse = get_var_data(prefix+'b_mgse', in=the_time_range)
    de_mgse = e_mgse-vec_cross(u_mgse,b_mgse)


    ndim = 3
    ntime = n_elements(times)
    xxs = fltarr(ndim,ntime,ndim)
    coefs = fltarr(ndim, ndim)

    ;---Rotation on Vsc.
            ; For Ey.
            xxs[0,*,1] = -v_mgse[*,1]*b_mgse[*,0]
            xxs[1,*,1] =  v_mgse[*,0]*b_mgse[*,0]+v_mgse[*,2]*b_mgse[*,2]
            xxs[2,*,1] = -v_mgse[*,1]*b_mgse[*,2]
            ; For Ez.
            xxs[0,*,2] = -v_mgse[*,2]*b_mgse[*,0]
            xxs[1,*,2] = -v_mgse[*,2]*b_mgse[*,1]
            xxs[2,*,2] =  v_mgse[*,0]*b_mgse[*,0]+v_mgse[*,1]*b_mgse[*,1]

        ;---Rotation on U.
            ; For Ey.
            xxs[0,*,1] = -u_mgse[*,1]*b_mgse[*,0]
            xxs[1,*,1] =  u_mgse[*,0]*b_mgse[*,0]+u_mgse[*,2]*b_mgse[*,2]
            xxs[2,*,1] = -u_mgse[*,1]*b_mgse[*,2]
            ; For Ez.
            xxs[0,*,2] = -u_mgse[*,2]*b_mgse[*,0]
            xxs[1,*,2] = -u_mgse[*,2]*b_mgse[*,1]
            xxs[2,*,2] =  u_mgse[*,0]*b_mgse[*,0]+u_mgse[*,1]*b_mgse[*,1]

    ;---Rotation on B.
    ; For Ey.
    xxs[0,*,1] =  u_mgse[*,0]*b_mgse[*,1]
    xxs[1,*,1] = -u_mgse[*,0]*b_mgse[*,0]-u_mgse[*,2]*b_mgse[*,2]
    xxs[2,*,1] =  u_mgse[*,2]*b_mgse[*,1]
    ; For Ez.
    xxs[0,*,2] =  u_mgse[*,0]*b_mgse[*,2]
    xxs[1,*,2] =  u_mgse[*,1]*b_mgse[*,0]
    xxs[2,*,2] = -u_mgse[*,0]*b_mgse[*,0]-u_mgse[*,1]*b_mgse[*,1]


    xx = fltarr(ndim*ndim,ntime)
    for ii=0,ndim-1 do for jj=0,ndim-1 do xx[ii*ndim+jj,*] = u_mgse[*,ii]*b_mgse[*,jj]
    coefs = fltarr(ndim*ndim, ndim)


    fit_index = [1,2]   ; y,z.
    foreach ii, fit_index do begin
;xx = xxs[*,*,ii]
        yy = de_mgse[*,ii]
        res = regress(xx,yy, sigma=sigma, const=const, measure_errors=measure_errors)
        ;if ii eq 1 then res = coefs[*,2]
        coefs[*,ii] = res

        var = prefix+'de'+xyz[ii]
        yfit = reform(xx ## res)+const
        store_data, var, times, [[yy],[yfit]], limits={$
            ytitle:'(mV/m)', labels:['E'+xyz[ii],'Regression'], colors:sgcolor(['blue','red'])}

        var = prefix+'e'+xyz[ii]
        store_data, var, times, yy-yfit, limits={ytitle:'(mV/m)', labels:'dE'+xyz[ii]}
    endforeach

;    plot_dir = join_path([googledir(),'works','rbsp_phase_f','plot','test_perigee_new_b_correction'])
;    plot_file = join_path([plot_dir,'fig_test_regression_'+prefix+strjoin(time_string(the_time_range,tformat='YYYY_MMDD_hhmm'),'_')+'_v01.pdf'])
    test = 1
    if keyword_set(test) then plot_file = test
    sgopen, plot_file, xsize=8, ysize=8, /inch, xchsz=xchsz, ychsz=ychsz
    tplot_options, 'yticklen', -0.015
    tplot_options, 'xticklen', -0.03
    tplot_options, 'labflag', -1
    vars = prefix+['de'+xyz[fit_index],'e'+xyz[fit_index]]
    options, vars, 'yrange', [-1,1]*5
    tplot, vars, $
        trange=the_time_range, window=plot_file, $
        get_plot_position=poss
    foreach ii, fit_index do begin
        res = coefs[*,ii]

        tpos = poss[*,ii-1]
        tx = tpos[0]+xchsz*0.5
        ty = tpos[3]-ychsz*1
        msg = 'Coefs: '+strjoin(string(res,format='(F8.4)'),',')
        xyouts, tx,ty,/normal, msg, charsize=1
    endforeach

    if keyword_set(test) then stop
    sgclose


end
