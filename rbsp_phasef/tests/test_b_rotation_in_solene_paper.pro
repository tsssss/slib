;+
; Test to rotate B field in MGSE.
;-

;---Input.
    date = time_double('2013-07-19')
    probe = 'a'

    secofday = constant('secofday')
    time_range = date+[0,secofday]
    prefix = 'rbsp'+probe+'_'
    rgb = constant('rgb')
    xyz = constant('xyz')


;---Load data.
    if check_if_update(prefix+'b_gsm', time_range) then $
        pflux_grant_read_level1_data, time_range, probe=probe, id='bfield'
    if check_if_update(prefix+'e_uv', time_range) then $
        pflux_grant_read_level1_data, time_range, probe=probe, id='efield'
    if check_if_update(prefix+'r_gsm', time_range) then $
        rbsp_read_orbit, time_range, probe=probe
    if check_if_update(prefix+'v_gsm', time_range) then $
        rbsp_read_sc_vel, time_range, probe=probe
    if check_if_update(prefix+'q_uvw2gsm', time_range) then $
        rbsp_read_quaternion, time_range, probe=probe

    if check_if_update(prefix+'e_gsm', time_range) then begin
        e_uv = get_var_data(prefix+'e_uv', times=times)
        e_uvw = [[e_uv[*,0]],[e_uv[*,1]],[fltarr(n_elements(times))]]
        store_data, prefix+'e_uvw', times, e_uvw
        add_setting, prefix+'e_uvw', /smart, dictionary($
            'display_type', 'vector', $
            'unit', 'mV/m', $
            'short_name', 'E', $
            'coord', 'GSM', $
            'coord_labels', constant('uvw') )
        rbsp_uvw2gsm, prefix+'e_uvw', prefix+'e_gsm', probe=probe
    endif


;---Convert vectors to MGSE.
    vars = prefix+['b','bmod','r','v','e']
    foreach var, vars do begin
        if ~check_if_update(var+'_mgse', time_range) then continue
        vec = get_var_data(var+'_gsm', times=times)
        vec = cotran(vec, times, 'gsm2mgse', probe=probe)
        store_data, var+'_mgse', times, vec, limits={colors:rgb, labels:xyz}
    endforeach


;---Prepare data to common_times.
    get_data, prefix+'b_gsm', common_times
    ncommon_time = n_elements(common_times)
    common_time_step = total(common_times[0:1]*[-1,1])
    foreach var, prefix+['r','v'] do begin
        vec = get_var_data(var+'_mgse', times=times)
        if n_elements(times) eq ncommon_time then continue
        vec = sinterpol(vec, times, common_times, /quadratic)
        store_data, var+'_mgse', common_times, vec
    endforeach


;---Calculate E_vxb.
    evxb_var = prefix+'evxb_mgse'
    if check_if_update(evxb_var, time_range) then begin
        v_mgse = get_var_data(prefix+'v_mgse')
        b_mgse = get_var_data(prefix+'b_mgse')
        evxb_mgse = vec_cross(v_mgse, b_mgse)*1e-3
        store_data, evxb_var, common_times, evxb_mgse
        add_setting, evxb_var, /smart, {$
            display_type: 'vector', $
            unit: 'mV/m', $
            short_name: 'VxB E', $
            coord: 'MGSE', $
            coord_labels: xyz }
    endif


;---Calculate E_coro.
    ecoro_var = prefix+'ecoro_mgse'
    if check_if_update(ecoro_var, time_range) then begin
        omega = (2*!dpi)/86400d  ;Earth's rotation angular frequency
        r_gsm = get_var_data(prefix+'r_gsm', times=times)
        r_gei = cotran(r_gsm, times, 'gsm2gei')
        vcoro_gei = r_gei
        vcoro_gei[*,0] = -r_gei[*,1]*omega
        vcoro_gei[*,1] =  r_gei[*,0]*omega
        vcoro_gei[*,2] = 0.0
        vcoro_mgse = cotran(vcoro_gei, times, 'gei2mgse', probe=probe)
        vcoro_mgse = sinterpol(vcoro_mgse, times, common_times, /quadratic)
        b_mgse = get_var_data(prefix+'b_mgse')
        ecoro_mgse = scross(vcoro_mgse, b_mgse)
        store_data, ecoro_var, common_times, ecoro_mgse
        add_setting, ecoro_var, /smart, {$
            display_type: 'vector', $
            unit: 'mV/m', $
            short_name: 'Coro E', $
            coord: 'MGSE', $
            coord_labels: xyz }
    endif


    spin_period = 12.
    ndim = 3
    spin_width = spin_period/common_time_step


    ecoro_mgse = get_var_data(prefix+'ecoro_mgse')
    evxb_mgse = get_var_data(prefix+'evxb_mgse')
    e_mgse = get_var_data(prefix+'e_mgse')
    e0_mgse = e_mgse-ecoro_mgse
    e0_mgse[*,0] = 0
    for ii=1,ndim-1 do e0_mgse[*,ii] = smooth(e0_mgse[*,ii],spin_width,/nan,/edge_truncate)
    store_data, prefix+'e0_mgse', common_times, e0_mgse
    add_setting, prefix+'e0_mgse', /smart, {$
        display_type: 'vector', $
        unit: 'mV/m', $
        short_name: 'E0', $
        coord: 'MGSE', $
        coord_labels: xyz }
    
    ; The residue.
    e1_mgse = e_mgse-ecoro_mgse-evxb_mgse
    e1_mgse[*,0] = 0
    store_data, prefix+'e1_mgse', common_times, e1_mgse
    add_setting, prefix+'e1_mgse', /smart, {$
        display_type: 'vector', $
        unit: 'mV/m', $
        short_name: 'E1', $
        coord: 'MGSE', $
        coord_labels: xyz }
    e1_offset = e1_mgse
    for ii=1,ndim-1 do e1_offset[*,ii] = smooth(e1_mgse[*,ii],spin_width,/nan,/edge_truncate)
    
    ; The "actual" E_vxb.
    e0_mgse += e1_offset
    store_data, prefix+'e0_mgse', common_times, e0_mgse
    ; The "oscilation" due to spinning.
    e1_mgse = e1_mgse-e1_offset
    store_data, prefix+'e1_mgse', common_times, e1_mgse
    
    deg = constant('deg')
    dey = e1_mgse[*,1]
    deymag = sqrt(dey^2+(shift(dey,spin_width*0.25))^2)
    dez = e1_mgse[*,2]
    dezmag = sqrt(dez^2+(shift(dez,spin_width*0.25))^2)
    ey_angle = atan(deymag/(e0_mgse[*,1]))*deg
    ez_angle = atan(dezmag/(e0_mgse[*,2]))*deg
    store_data, prefix+'ey_angle', common_times, ey_angle
    store_data, prefix+'ez_angle', common_times, ez_angle
    
    
    

    ;    b_mgse = get_var_data(prefix+'b_mgse')
    ;    ex = -vec_dot(e_mgse, b_mgse)/b_mgse[*,0]
    ;    index = where(abs(b_mgse[*,0]/snorm(b_mgse)) le 0.15)
    ;    ex[index] = !values.f_nan
    ;    store_data, prefix+'ex_mgse', common_times, ex

    stop
    
stop

end
