;+
; Try to remove spin tone and calculate the rotation matrix.
;-


;---Input.
    date = time_double('2013-05-01')
    probe = 'a'

;---Other settings.
    secofday = constant('secofday')
    xyz = constant('xyz')
    full_time_range = date+[0,secofday]
    prefix = 'rbsp'+probe+'_'
    spin_period = 12d

;---Find the second perigee.
    rbsp_read_orbit, full_time_range, probe=probe
    dis = snorm(get_var_data(prefix+'r_gsm', times=times))
    perigee_lshell = 1.9
    perigee_times = times[where(dis le perigee_lshell)]
    orbit_time_step = total(times[0:1]*[-1,1])
    perigee_time_ranges = time_to_range(perigee_times, time_step=orbit_time_step)
    time_range = reform(perigee_time_ranges[0,*])

;---Load data.
    data_time_range = time_range+spin_period*[-1,1]
    pflux_grant_read_level1_data, data_time_range, probe=probe, id='ebfield'
    rbsp_read_quaternion, data_time_range, probe=probe
    rbsp_read_sc_vel, data_time_range, probe=probe
    rbsp_read_orbit, data_time_range, probe=probe

    ; Get e_gsm.
    e_uv = get_var_data(prefix+'e_uv', times=times)
    ntime = n_elements(times)
    e_uvw = [[e_uv],[fltarr(ntime)]]
    
    timespan, data_time_range[0], total(data_time_range*[-1,1]), /seconds
    rbsp_load_efw_waveform, probe=probe, datatype='esvy', type='cal', coord='uvw', /noclean, trange=data_time_range
    e_uvw = get_var_data(prefix+'efw_esvy', at=times)
    store_data, prefix+'e_uvw', times, e_uvw
    add_setting, prefix+'e_uvw', /smart, dictionary($
        'display_type', 'vector', $
        'unit', 'mV/m', $
        'short_name', 'E', $
        'coord', 'UVW', $
        'coord_labels', constant('uvw') )
    rbsp_uvw2gsm, prefix+'e_uvw', prefix+'e_gsm'

    ; Convert to MGSE.
    short_names = ['B','T89 B','V','E']
    foreach var, prefix+['b','bmod','v','e'], ii do begin
        b_gsm = get_var_data(var+'_gsm', times=times)
        b_mgse = cotran(b_gsm, times, 'gsm2mgse', probe=probe)
        store_data, var+'_mgse', times, b_mgse
        short_name = short_names[ii]
        add_setting, var+'_mgse', /smart, dictionary($
            'display_type', 'vector', $
            'unit', 'nT', $
            'short_name', short_name, $
            'coord', 'MGSE', $
            'coord_labels', xyz )
    endforeach


    ; B0 and B1.
    b_mgse = get_var_data(prefix+'b_mgse', times=common_times)
    bmod_mgse = get_var_data(prefix+'bmod_mgse')
    db_mgse = b_mgse-bmod_mgse
    common_time_step = total(common_times[0:1]*[-1,1])
    smooth_width = spin_period/common_time_step
    b1_mgse = db_mgse
    for ii=0,2 do b1_mgse[*,ii] -= smooth(db_mgse[*,ii], smooth_width, /edge_truncate, /nan)
    store_data, prefix+'b1_mgse', common_times, b1_mgse
    add_setting, prefix+'b1_mgse', /smart, dictionary($
        'display_type', 'vector', $
        'unit', 'nT', $
        'short_name', 'B1', $
        'coord', 'MGSE', $
        'coord_labels', xyz )
    b0_mgse = db_mgse-b1_mgse+bmod_mgse
    store_data, prefix+'b0_mgse', common_times, b0_mgse
    add_setting, prefix+'b0_mgse', /smart, dictionary($
        'display_type', 'vector', $
        'unit', 'nT', $
        'short_name', 'B0', $
        'coord', 'MGSE', $
        'coord_labels', xyz )


    ; E0 and E1.
    v_mgse = sinterpol(get_var_data(prefix+'v_mgse', times=times), times, common_times, /quadratic)
    evxb_mgse = vec_cross(v_mgse, b0_mgse)*1e-3
    ;evxb_mgse[*,0] = 0
    store_data, prefix+'evxb_mgse', common_times, evxb_mgse
    add_setting, prefix+'evxb_mgse', /smart, dictionary($
        'display_type', 'vector', $
        'unit', 'mV/m', $
        'short_name', 'VxB E', $
        'coord', 'MGSE', $
        'coord_labels', xyz )
    r_gsm = get_var_data(prefix+'r_gsm', times=times)
    r_gei = cotran(r_gsm, times, 'gsm2gei')
    vcoro_gei = r_gei
    omega = (2*!dpi)/86400d  ;Earth's rotation angular frequency
    vcoro_gei[*,0] = -r_gei[*,1]*omega
    vcoro_gei[*,1] =  r_gei[*,0]*omega
    vcoro_gei[*,2] = 0.0
    vcoro_mgse = cotran(vcoro_gei, times, 'gei2mgse', probe=probe)
    vcoro_mgse = sinterpol(vcoro_mgse, times, common_times, /quadratic)
    b0_mgse = get_var_data(prefix+'b0_mgse')
    ecoro_mgse = vec_cross(vcoro_mgse, b0_mgse)
    store_data, prefix+'ecoro_mgse', common_times, ecoro_mgse
    add_setting, prefix+'ecoro_mgse', /smart, dictionary($
        'display_type', 'vector', $
        'unit', 'mV/m', $
        'short_name', 'Coro E', $
        'coord', 'MGSE', $
        'coord_labels', xyz )
    emod_mgse = evxb_mgse+ecoro_mgse
    store_data, prefix+'emod_mgse', common_times, emod_mgse
    add_setting, prefix+'emod_mgse', /smart, dictionary($
        'display_type', 'vector', $
        'unit', 'mV/m', $
        'short_name', 'Model E', $
        'coord', 'MGSE', $
        'coord_labels', xyz )

    ; Use emod_mgse and e_mgse to get e0_mgse.
    e0_mgse = emod_mgse
    e_mgse = get_var_data(prefix+'e_mgse')
    min_e = 10.
    for ii=0,2 do begin
        e0 = e_mgse[*,ii]
        e1 = emod_mgse[*,ii]
        yshift = min_e-min(e1)
        coef = (e0+yshift)/(e1+yshift)
        coef = smooth(coef, smooth_width, /edge_zero, /nan)
        e0_mgse[*,ii] = (e1+yshift)*coef-yshift
    endfor
    store_data, prefix+'e0_mgse', common_times, e0_mgse
    add_setting, prefix+'e0_mgse', /smart, dictionary($
        'display_type', 'vector', $
        'unit', 'mV/m', $
        'short_name', 'E0', $
        'coord', 'MGSE', $
        'coord_labels', xyz )
    e1_mgse = e_mgse-e0_mgse
    e1_mgse[*,0] = 0
    store_data, prefix+'e1_mgse', common_times, e1_mgse
    add_setting, prefix+'e1_mgse', /smart, dictionary($
        'display_type', 'vector', $
        'unit', 'mV/m', $
        'short_name', 'E1', $
        'coord', 'MGSE', $
        'coord_labels', xyz )


    ; Truncate in time.
    foreach var, prefix+['b0','b1','b','bmod','e0','e1','e','emod']+'_mgse' do begin
        get_data, var, times, b_mgse
        index = where_pro(times, '[]', time_range)
        store_data, var, times[index], b_mgse[index,*]
    endforeach


;---Solve for the rotation axis and angle.
    b0_mgse = get_var_data(prefix+'b0_mgse', times=common_times)
    b_mgse = get_var_data(prefix+'b_mgse')
    rotation_axis = sunitvec(vec_cross(b_mgse, b0_mgse))
    store_data, prefix+'rotation_axis', common_times, rotation_axis
    add_setting, prefix+'rotation_axis', /smart, dictionary($
        'display_type', 'vector', $
        'unit', '#', $
        'short_name', 'A', $
        'coord', 'MGSE', $
        'coord_labels', xyz )
    rotation_angle = sang(b0_mgse,b_mgse, /deg)
    store_data, prefix+'rotation_angle', common_times, rotation_angle
    add_setting, prefix+'rotation_angle', /smart, dictionary($
        'display_type', 'scalar', $
        'unit', 'deg', $
        'short_name', 'B' )


;---Solve for dE.
    e0_mgse = get_var_data(prefix+'e0_mgse', times=common_times)
    e_mgse = get_var_data(prefix+'e_mgse')
    emod_mgse = get_var_data(prefix+'emod_mgse')
    de_mgse = e_mgse-emod_mgse
;    de_mgse[*,0] = 0
    store_data, prefix+'de_mgse', common_times, de_mgse
    add_setting, prefix+'de_mgse', /smart, dictionary($
        'display_type', 'vector', $
        'unit', 'mV/m', $
        'short_name', 'dE', $
        'coord', 'MGSE', $
        'coord_labels', xyz )

    stop



end
