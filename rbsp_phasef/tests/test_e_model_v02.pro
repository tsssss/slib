;+
; Test if e_model v02 works as desired.
; 
; Yes, it does.
;-

;---Settings.
    time_range = time_double(['2014-06-01','2015-01-01'])
    time_range = time_double(['2012-10-01','2013-01-01'])
    time_range = time_double(['2013-01-01','2013-06-01'])
    probes = ['a','b']


    ndim = 3
    rgb = constant('rgb')
    default_lim = {colors:rgb}
    yr = [-1,1]*5

;---Read data.
    foreach probe, probes do begin
        prefix = 'rbsp'+probe+'_'
        
        if check_if_update(prefix+'b_mgse', time_range) then begin
            rbsp_efw_phasef_read_wobble_free_var, time_range, probe=probe
        endif
        if check_if_update(prefix+'emod_mgse', time_range) then begin
            rbsp_read_e_model, time_range, probe=probe, id='e_model_related'
        endif
        if check_if_update(prefix+'e_spinfit_mgse_v12', time_range) then begin
            rbsp_efw_phasef_read_spinfit_efield, time_range, probe=probe
        endif
        
    ;---Check diff b/w e_model and e_spinfit_xx.
        bps = ['12','34','13','14','23','24']
        get_data, prefix+'e_spinfit_mgse_v'+bps[0], common_times
        emod_mgse = get_var_data(prefix+'emod_mgse', at=common_times)
        dis = snorm(get_var_data(prefix+'r_mgse', at=common_times))
        perigee_lshell = 2.5
        apogee_index = where(dis ge perigee_lshell)
        fillval = !values.f_nan
        foreach bp, bps do begin
            evar = prefix+'e_spinfit_mgse_v'+bp
            get_data, evar, times, e_mgse
            e_mgse[apogee_index,*] = fillval
            e_mgse[*,0] = 0
            store_data, prefix+'de_mgse_v'+bp, common_times, e_mgse, limits=default_lim
            ylim, prefix+'de_mgse_v'+bp, yr


            store_data, prefix+'demag_v'+bp, common_times, snorm(e_mgse[*,1:2])
        endforeach
    endforeach
    
    tplot, 'rbsp?_de_mgse_v'+['12','34']
stop
    


    

;---Prepare calc e_model.
    v_mgse = get_var_data(prefix+'v_mgse', times=times)*1e-3
    vcoro_mgse = get_var_data(prefix+'vcoro_mgse')*1e-3
    u_mgse = v_mgse-vcoro_mgse

    b_mgse = get_var_data(prefix+'b_mgse')
    emod2_mgse = vec_cross(u_mgse,b_mgse)
    store_data, prefix+'emod2_mgse', times, emod2_mgse, limits=default_lim
    store_data, prefix+'emod_mgse', limits=default_lim
    emod_mgse = get_var_data(prefix+'emod_mgse')
    
    demod_mgse = emod_mgse-emod2_mgse
    store_data, prefix+'demod_mgse', times, demod_mgse

end
