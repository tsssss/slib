
pro test_raw_perigee_correction_with_q_restored, time_range, probe=probe


;---Settings.
    common_time_step = 10.


;---Derived quantities.
    prefix = 'rbsp'+probe+'_'
    common_times = make_bins(time_range, common_time_step)
    xyz = constant('xyz')
    uvw = constant('uvw')
    
    
;---Load E_uvw.
    timespan, time_range[0], total(time_range*[-1,1]), /seconds
    rbsp_load_efw_waveform, probe=probe, datatype='esvy', type='cal', coord='uvw', /noclean, trange=time_range
    
    ; Preprocess: remove Ew, remove DC offsets.
    evar_old = prefix+'efw_esvy'
    dt = 1/16d
    uniform_time, evar_old, dt
    e_uvw = get_var_data(evar_old, times=times)
    e_uvw[*,2] = 0
    spin_period = 11d
    width = spin_period/dt
    for ii=0,1 do begin
        offset1 = smooth(e_uvw[*,ii], width, /nan, /edge_zero)
        offset2 = smooth(offset1, width, /nan, /edge_zero)
        e_uvw[*,ii] -= offset2
    endfor
    store_data, prefix+'e_uvw', times, e_uvw
    add_setting, prefix+'e_uvw', /smart, dictionary($
        'display_type', 'vector', $
        'unit', 'mV/m', $
        'short_name', 'E', $
        'coord', 'UVW', $
        'coord_labels', uvw)
    
;    rbsp_load_efw_waveform, probe=probe, datatype='esvy', type='raw', coord='uvw', /noclean, trange=time_range
;    get_data, evar_old, uts, esvy
;    esvy[*,2] = 0
;    store_data, evar_old, uts, esvy
;    stop


;---Calculate E-E_coro-E_vxb.
    rbsp_read_q_uvw2gse, time_range, probe=probe
    ;rbsp_read_quaternion, time_range, probe=probe
    ;rbsp_fix_q_uvw2gse, time_range, probe=probe, restore_eclipse=1
    rbsp_efw_phasef_read_wobble_free_var, time_range, probe=probe

    vcoro_var = prefix+'vcoro_mgse'
    vcoro_mgse = calc_vcoro(r_var=prefix+'r_mgse', probe=probe)
    store_data, vcoro_var, common_times, vcoro_mgse
    add_setting, vcoro_var, /smart, dictionary($
        'display_type', 'vector', $
        'unit', 'km/s', $
        'short_name', 'Coro V', $
        'coord', 'MGSE', $
        'coord_labels', xyz)

    b_mgse = get_var_data(prefix+'b_mgse')
    v_mgse = get_var_data(prefix+'v_mgse')*1e-3
    vcoro_mgse = get_var_data(prefix+'vcoro_mgse')*1e-3
    u_mgse = v_mgse-vcoro_mgse
    emod_mgse = vec_cross(u_mgse,b_mgse)
    store_data, prefix+'emod_mgse', common_times, emod_mgse
    add_setting, prefix+'emod_mgse', /smart, dictionary($
        'display_type', 'vector', $
        'unit', 'mV/m', $
        'short_name', 'E!S!Ucoro+vxb!N!R', $
        'coord', 'MGSE', $
        'coord_labels', xyz)
    store_data, prefix+'evxb_mgse', common_times, vec_cross(v_mgse,b_mgse)
    add_setting, prefix+'evxb_mgse', /smart, dictionary($
        'display_type', 'vector', $
        'unit', 'mV/m', $
        'short_name', 'E!S!Uvxb!N!R', $
        'coord', 'MGSE', $
        'coord_labels', xyz)
    store_data, prefix+'ecoro_mgse', common_times, -vec_cross(u_mgse,b_mgse)
    add_setting, prefix+'ecoro_mgse', /smart, dictionary($
        'display_type', 'vector', $
        'unit', 'mV/m', $
        'short_name', 'E!S!Ucoro!N!R', $
        'coord', 'MGSE', $
        'coord_labels', xyz)
        
        
    e_mgse = get_var_data(prefix+'e_mgse')
    de_mgse = e_mgse-emod_mgse
    ; Some modifications.
    de_mgse[*,0] = 0
;    dis = snorm(get_var_data(prefix+'r_mgse'))
;    index = where(dis ge 2)
;    de_mgse[index,*] = !values.f_nan
    de_var = prefix+'de_mgse'
    store_data, de_var, common_times, de_mgse
    add_setting, de_var, /smart, dictionary($
        'display_type', 'vector', $
        'unit', 'mV/m', $
        'short_name', 'Raw dE', $
        'coord', 'MGSE', $
        'coord_labels', xyz)


;;---Remove eclipse.
;    rbsp_read_eclipse_flag, time_range, probe=probe
;    flag_var = prefix+'eclipse_flag'
;    flags = get_var_data(flag_var, times=times)
;    index = where(flags eq 1, count)
;    fillval = !values.f_nan
;    if count ne 0 then begin
;        e_mgse = get_var_data(prefix+'de_mgse')
;        the_time_step = total(times[0:1]*[-1,1])
;        time_ranges = time_to_range(times[index], time_step=the_time_step, pad_time=the_time_step)
;        ntime_range = n_elements(time_ranges)*0.5
;        for ii=0,ntime_range-1 do begin
;            index = where_pro(common_times,'[]',time_ranges[ii,*], count=count)
;            if count eq 0 then continue
;            e_mgse[index,*] = fillval
;        endfor
;        store_data, prefix+'de_mgse', common_times, e_mgse
;    endif

    de_mgse = get_var_data(prefix+'de_mgse')
    store_data, prefix+'dey_mgse', common_times, de_mgse[*,1]
    add_setting, prefix+'dey_mgse', /smart, dictionary($
        'display_type', 'scalar', $
        'unit', 'mV/m', $
        'short_name', 'Raw dEy', $
        'yrange', [-1,1]*10, $
        'ystyle', 1 )
    store_data, prefix+'dez_mgse', common_times, de_mgse[*,2]
    add_setting, prefix+'dez_mgse', /smart, dictionary($
        'display_type', 'scalar', $
        'unit', 'mV/m', $
        'short_name', 'Raw dEz', $
        'yrange', [-1,1]*10, $
        'ystyle', 1 )

        
    emod = get_var_data(prefix+'emod_mgse')
    e = get_var_data(prefix+'e_mgse')
    angle = sang(emod[*,1:2], e[*,1:2], /deg)
    store_data, prefix+'angle', common_times, angle
    add_setting, prefix+'angle', /smart, dictionary($
        'yrange', [-10,190], $
        'short_name', 'Angle', $
        'display_type', 'scalar', $
        'unit', 'deg' )
        
        
    stplot_split, prefix+'emod_mgse'
    stplot_split, prefix+'e_mgse'
    black = sgcolor('black')
    options, prefix+'emod_mgse_comp?', 'colors', black
    options, prefix+'e_mgse_comp?', 'colors', black
    stop

end


time_range = time_double(['2014-06-14','2014-06-16'])
time_range = time_double(['2014-06-17','2014-06-19'])
time_range = time_double(['2014-06-16','2014-06-18'])
time_range = time_double(['2014-06-13','2014-06-14'])
time_range = time_double(['2014-06-14','2014-06-19'])

probe = 'b'
test_raw_perigee_correction_with_q_restored, time_range, probe=probe
end
