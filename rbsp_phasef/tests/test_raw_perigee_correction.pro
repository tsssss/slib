;+
; Test the "raw" correction, which only includes vxb, v_coro.
;-


pro test_raw_perigee_correction, time_range, probe=probe


;---Settings.
    common_time_step = 10.


;---Derived quantities.
    prefix = 'rbsp'+probe+'_'
    common_times = make_bins(time_range, common_time_step)
    xyz = constant('xyz')


;---Calculate E-E_coro-E_vxb.
    rbsp_efw_phasef_read_wobble_free_var, time_range, probe=probe, id='quaternion'
    rbsp_efw_phasef_read_wobble_free_var, time_range, probe=probe

    vcoro_var = prefix+'vcoro_mgse'
    if check_if_update(vcoro_var, time_range) then begin
        vcoro_mgse = calc_vcoro(r_var=prefix+'r_mgse', probe=probe)
        store_data, vcoro_var, common_times, vcoro_mgse
        add_setting, vcoro_var, /smart, dictionary($
            'display_type', 'vector', $
            'unit', 'km/s', $
            'short_name', 'Coro V', $
            'coord', 'MGSE', $
            'coord_labels', xyz)
    endif

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
    

;---Remove eclipse.
    rbsp_read_eclipse_flag, time_range, probe=probe
    flag_var = prefix+'eclipse_flag'
    flags = get_var_data(flag_var, times=times)
    index = where(flags eq 1, count)
    fillval = !values.f_nan
    if count ne 0 then begin
        e_mgse = get_var_data(prefix+'de_mgse')
        the_time_step = total(times[0:1]*[-1,1])
        time_ranges = time_to_range(times[index], time_step=the_time_step, pad_time=the_time_step)
        ntime_range = n_elements(time_ranges)*0.5
        for ii=0,ntime_range-1 do begin
            index = where_pro(common_times,'[]',time_ranges[ii,*], count=count)
            if count eq 0 then continue
            e_mgse[index,*] = fillval
        endfor
        store_data, prefix+'de_mgse', common_times, e_mgse
    endif
    
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


    root_dir = join_path([googledir(),'works','rbsp_phase_f','data','raw_perigee_residue'])
    base_name = prefix+'raw_perigee_residue_'+time_string(time_range[0],tformat='YYYY')+'.cdf'
    cdf_file = join_path([root_dir, base_name])
    if file_test(cdf_file) then file_delete, cdf_file
    vars = prefix+['emod','e','de'+['y','z']]+'_mgse'
    stplot2cdf, vars, time_var='Epoch', istp=1, filename=cdf_file
    
end


years = string(make_bins([2013,2019],1),format='(I4)')
nyear = n_elements(years)-1
for ii=0,nyear-1 do begin
    time_range = time_double(years[ii:ii+1]+'-01-01')
    foreach probe, ['a','b'] do test_raw_perigee_correction, time_range, probe=probe
endfor
end
