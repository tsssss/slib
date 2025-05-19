;+
; Load fixed quantities and calc the perigee residue.
;-


pro test_perigee_residue_removal, day, probe=probe

    prefix = 'rbsp'+probe+'_'
    secofday = constant('secofday')
    time_range = time_double(day)+[0,secofday]
    xyz = constant('xyz')


;---Prepare low-level quantities.
    rbsp_efw_read_q_uvw2gse, time_range, probe=probe
    rbsp_efw_phasef_read_r_mgse, time_range, probe=probe
    rbsp_efw_phasef_read_v_mgse, time_range, probe=probe
    rbsp_efw_phasef_read_b_mgse, time_range, probe=probe
    rbsp_efw_read_e_mgse, time_range, probe=probe

;---Common times.
    common_time_step = 1.
    common_times = make_bins(time_range, common_time_step)
    vars = prefix+['r','v','b','e']+'_mgse'
    foreach var, vars do interp_time, var, common_times

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
    perigee_times = common_times[where(dis le perigee_shell)]
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



;---Calculate the residue.
    v_mgse = get_var_data(prefix+'v_mgse', in=perigee_time_range, times=perigee_times)*1e-3
    vcoro_mgse = get_var_data(prefix+'vcoro_mgse', in=perigee_time_range)*1e-3
    u_mgse = (v_mgse-vcoro_mgse)   ; to get mV/m directly when xB.
    e_mgse = get_var_data(prefix+'e_mgse', in=perigee_time_range)
    b_mgse = get_var_data(prefix+'b_mgse', in=perigee_time_range)
    de_mgse = e_mgse-vec_cross(u_mgse,b_mgse)
    de_mgse[*,0] = 0
    de_var = prefix+'de_mgse'
    store_data, de_var, perigee_times, de_mgse
    add_setting, de_var, /smart, dictionary($
        'display_type', 'vector', $
        'unit', 'mV/m', $
        'short_name', 'dE', $
        'coord', 'MGSE', $
        'coord_labels', xyz)

    fit_index = [1,2]
    foreach ii, fit_index do begin
        the_var = prefix+'de'+xyz[ii]
        store_data, the_var, perigee_times, de_mgse[*,ii]
        add_setting, the_var, /smart, dictionary($
            'display_type', 'scalar', $
            'constant', 0, $
            'yrange', [-1,1]*12, $
            'yticks', 6, $
            'yminor', 5, $
            'unit', 'mV/m', $
            'short_name', 'MGSE dE'+xyz[ii] )
    endforeach


test = 1
    plot_dir = join_path([googledir(),'works','rbsp_phase_f','plot','test_perigee_residue_removal'])
    plot_file = join_path([plot_dir,'fig_test_perigee_residue_removal_'+prefix+strjoin(time_string(perigee_time_range,tformat='YYYY_MMDD_hhmm'),'_')+'_v01.pdf'])
    plot_file = join_path([plot_dir,'fig_test_perigee_residue_removal_'+prefix+time_string(time_range[0],tformat='YYYY_MMDD')+'_v01.pdf'])
    if keyword_set(test) then plot_file = 0
    sgopen, plot_file, xsize=6, ysize=6, /inch, xchsz=xchsz, ychsz=ychsz
    tplot_options, 'yticklen', -0.015
    tplot_options, 'xticklen', -0.03
    tplot, prefix+['de'+xyz[fit_index],'dis'], $
        trange=perigee_time_range, $
        get_plot_position=poss
    if keyword_set(test) then stop
    sgclose

end



;---Inputs.
probes = ['a','b']
probes = ['b']
;days = make_bins(time_double(['2013-07-15','2013-07-16']), constant('secofday'))
;days = make_bins(time_double(['2013-07-18','2013-07-25']), constant('secofday'))
foreach probe, probes do begin
    foreach day, days do begin
        test_perigee_residue_removal, day, probe=probe
    endforeach
endforeach
end
