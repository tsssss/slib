;+
; Test to reduce residue of the perigee E field.
;-


pro test_perigee_correction_with_hires_spice_vel, test_time, probe=probe

    test = 0

;---Constant.
    secofday = constant('secofday')
    xyz = constant('xyz')

;---Settings.
    prefix = 'rbsp'+probe+'_'
    perigee_shell = 4.  ; Re.
    time_range = test_time+[0,secofday*1]
    plot_dir = join_path([googledir(),'works','rbsp_phase_f','plot','test_perigee_emgse_with_hires_spice_vel'])



;---Load data.
    ; Load electric and magnetic field.
    rbsp_read_efield, time_range, probe=probe, resolution='hires'
    rbsp_read_bfield, time_range, probe=probe
    rbsp_read_quaternion, time_range, probe=probe

    ; load spice kernels for all times.
    ; Load r_gsm, v_gsm.
    defsysv,'!rbsp_spice', exists=flag
    if flag eq 0 then rbsp_load_spice_kernel

    re = constant('re')
    orbit_time_step = 0.1
    orbit_times = make_bins(time_range, orbit_time_step)
    rbsp_load_spice_state, probe=probe, coord='gsm', times=orbit_times, /no_spice_load

    r_gsm = get_var_data(prefix+'state_pos_gsm')/re
    r_var = prefix+'r_gsm'
    store_data, r_var, orbit_times, r_gsm
    add_setting, r_var, /smart, {$
        display_type: 'vector', $
        unit: 'Re', $
        short_name: 'R', $
        coord: 'GSM', $
        coord_labels: xyz }

    v_gsm = get_var_data(prefix+'state_vel_gsm')
    v_var = prefix+'v_gsm'
    store_data, v_var, orbit_times, v_gsm
    add_setting, v_var, /smart, {$
        display_type: 'vector', $
        unit: 'km/s', $
        short_name: 'V', $
        coord: 'GSM', $
        coord_labels: xyz }


;---Prepare data on common times.
    common_time_step = 1
    common_times = make_bins(time_range, common_time_step)
    foreach var, prefix+['v','r','b','e'] do begin
        var_in = var+'_gsm'
        get_data, var_in, times, data
        data = sinterpol(data, times, common_times)
        var_out = var+'_gsm'
        store_data, var_out, common_times, data
    endforeach



;---Calculate the corrotation electric field.
    omega = (2*!dpi)/86400d  ;Earth's rotation angular frequency
    r_var = prefix+'r_gsm'
    r_gsm = get_var_data(r_var)
    r_gei = cotran(r_gsm, common_times, 'gsm2gei')
    vcoro_gei = r_gei
    vcoro_gei[*,0] = -r_gei[*,1]*omega
    vcoro_gei[*,1] =  r_gei[*,0]*omega
    vcoro_gei[*,2] = 0.0
    vcoro_gsm = cotran(vcoro_gei, common_times, 'gei2gsm')
    b_var = prefix+'b_gsm'
    b_gsm = get_var_data(b_var)
    ecoro_gsm = scross(vcoro_gsm, b_gsm)
    ecoro_var = prefix+'ecoro_gsm'
    store_data, ecoro_var, common_times, ecoro_gsm
    add_setting, ecoro_var, /smart, {$
        display_type: 'vector', $
        unit: 'mV/m', $
        short_name: 'Coro E', $
        coord: 'GSM', $
        coord_labels: xyz }



;---Convert to MGSE.
    foreach var, prefix+['b','r','v','e','ecoro'] do begin
        var_in = var+'_gsm'
        get_data, var_in, times, data
        data = cotran(data, common_times, 'gsm2mgse')
        var_out = var+'_mgse'
        unit = get_setting(var_in, 'unit')
        short_name = get_setting(var_in, 'short_name')
        coord_labels = get_setting(var_in, 'coord_labels')
        store_data, var_out, common_times, data
        add_setting, var_out, /smart, {$
            display_type: 'vector', $
            unit: unit, $
            short_name: short_name, $
            coord: 'MGSE', $
            coord_labels: coord_labels }
    endforeach




;---Evxb in MGSE.
    v_mgse = get_var_data(prefix+'v_mgse')
    b_mgse = get_var_data(prefix+'b_mgse')
    evxb_mgse = vec_cross(v_mgse, b_mgse)*1e-3
    evxb_mgse[*,0] = 0
    store_data, prefix+'evxb_mgse', common_times, evxb_mgse
    add_setting, prefix+'evxb_mgse', /smart, {$
        display_type: 'vector', $
        unit: 'mV/m', $
        short_name: 'E', $
        coord: 'MGSE', $
        coord_labels: constant('xyz') }


;---Calculate dE.
test_e = [0., 50, 100,  150, 200, 250, 300, 350]
test_c = [1., 1., 0.99,.985,.980,.975,.970,.970]

    e_mgse = get_var_data(prefix+'e_mgse')

    ecoro = get_var_data(prefix+'ecoro_mgse')
    ecoro[*,0] = 0
    de_mgse = e_mgse-ecoro

    evxb = get_var_data(prefix+'evxb_mgse')
    ;coef = interpol(test_c, test_e, snorm(de_mgse), /quadratic)
    ;for ii=0,ndim-1 do evxb[*,ii] *= coef
    evxb[*,0] = 0
    de_mgse = de_mgse-evxb

    de_var = prefix+'de_mgse'
    store_data, de_var, common_times, de_mgse
    add_setting, de_var, /smart, dictionary($
        'display_type', 'vector', $
        'unit', 'mV/m', $
        'short_name', 'dE', $
        'coord', 'MGSE', $
        'coord_labels', constant('xyz') )



;---Get perigee times.
    dis = snorm(get_var_data(r_var))
    perigee_times = common_times[where(dis le perigee_shell)]
    perigee_time_ranges = time_to_range(perigee_times, time_step=common_time_step)
    nperigee_time_range = n_elements(perigee_time_ranges)*0.5
    if nperigee_time_range lt 1 then return


;    for id=0,nperigee_time_range-1 do begin
    for id=1,1 do begin
        the_time_range = reform(perigee_time_ranges[id,*])



        plot_file = join_path([plot_dir,prefix+'emgse_perigee_'+$
            strjoin(time_string(the_time_range,tformat='YYYY_MMDD_hhmm'),'_')+'.pdf'])
        if keyword_set(test) then plot_file = test
    endfor

end


probes = ['a','b']
years = ['2013','2014','2015','2016','2017']
months = ['03','06','09','12']
dates = []
foreach year, years do foreach month, months do dates = [dates, year+'-'+month+'-01']
test_times = time_double(dates)
foreach probe, probes do foreach test_time, test_times do test_perigee_correction_with_hires_spice_vel, test_time, probe=probe
end
