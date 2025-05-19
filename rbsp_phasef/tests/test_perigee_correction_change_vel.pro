;+
; Test to reduce residue of the perigee E field.
;-


pro test_perigee_correction_change_vel, test_time, probe=probe


test = 0

;---Constant.
    secofday = constant('secofday')
    xyz = constant('xyz')

;---Settings.
    prefix = 'rbsp'+probe+'_'
    perigee_shell = 4.  ; Re.
    time_range = test_time+[0,secofday*2]
    plot_dir = join_path([googledir(),'works','rbsp_phase_f','plot','test_perigee_emgse_change_vel'])


;---Load basic data.
    rbsp_read_efield, time_range, probe=probe, resolution='hires'
    rbsp_read_orbit, time_range, probe=probe
    rbsp_read_bfield, time_range, probe=probe
    rbsp_read_quaternion, time_range, probe=probe


;---Calculate velocity.
    r_var = prefix+'r_gsm'
    r_gsm = get_var_data(r_var, times=orbit_times)

    orbit_time_step = total(orbit_times[0:1]*[-1,1])
    re = constant('re')
    ndim = 3


;---Get perigee times.
    dis = snorm(get_var_data(r_var))
    perigee_times = orbit_times[where(dis le perigee_shell)]
    perigee_time_ranges = time_to_range(perigee_times, time_step=orbit_time_step)
    nperigee_time_range = n_elements(perigee_time_ranges)*0.5
    if nperigee_time_range lt 1 then return
    id = 1
    the_time_range = reform(perigee_time_ranges[id,*])


;---Correct v_gsm.
    v_gsm = r_gsm
    for ii=0, ndim-1 do v_gsm[*,ii] = deriv(r_gsm[*,ii])*(re/orbit_time_step)
    v_var = prefix+'v_gsm'
    store_data, v_var, orbit_times, v_gsm
    add_setting, v_var, /smart, {$
        display_type: 'vector', $
        unit: 'km/s', $
        short_name: 'V', $
        coord: 'GSM', $
        coord_labels: xyz }
    index = where_pro(orbit_times, '[]', the_time_range)
    ds = snorm(vec_cross(r_gsm,v_gsm))
    mean_ds = mean(ds[index])
    mean_ds = mean(ds)
    v_coef = mean_ds/ds
    for ii=0,ndim-1 do v_gsm[*,ii] *= v_coef
    store_data, prefix+'v_gsm', orbit_times, v_gsm


;---Prepare data on common times.
    common_time_step = 1
    common_times = make_bins(time_range, common_time_step)
    foreach var, prefix+['v','r','b','e'] do begin
        var_in = var+'_gsm'
        quadratic = (var_in eq prefix+'r_gsm' or var_in eq prefix+'v_gsm')? 1: 0
        get_data, var_in, times, data
        data = sinterpol(data, times, common_times, quadratic=quadratic)
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
    e_mgse = get_var_data(prefix+'e_mgse')

    ecoro = get_var_data(prefix+'ecoro_mgse')
    ecoro[*,0] = 0
    de_mgse = e_mgse-ecoro

    evxb = get_var_data(prefix+'evxb_mgse')
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


    plot_file = join_path([plot_dir,prefix+'emgse_perigee_'+$
        strjoin(time_string(the_time_range,tformat='YYYY_MMDD_hhmm'),'_')+'.pdf'])
    perigee_correction_plot1, the_time_range, probe=probe, plot_file=plot_file, test=test

end


probes = ['a','b']
years = ['2013','2014','2015','2016','2017']
months = ['03','06','09','12']
dates = []
foreach year, years do foreach month, months do dates = [dates, year+'-'+month+'-01']

test_times = time_double(dates)
foreach probe, probes do foreach test_time, test_times do test_perigee_correction_change_vel, test_time, probe=probe
end