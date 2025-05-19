;+
; Test to allow r_mgse, v_mgse to shift in time.
;
; Doesn't really change much.
;-

function shift_t, vec0, times, dtime

    vec = vec0
    vec = sinterpol(vec0, times+dtime, times, quadratic=1)
    return, vec

end


time_range = time_double(['2012','2015'])
;time_range = time_double(['2014','2015'])

probe = 'b'
prefix = 'rbsp'+probe+'_'

    var = prefix+'emod_mgse'
    if check_if_update(var, time_range) then begin
        rbsp_efw_phasef_read_e_fit_var, time_range, probe=probe
    endif

    e_mgse = get_var_data(prefix+'e_mgse', limits=lim)

    var = prefix+'e1_mgse'
    dif_data, prefix+'e_mgse', prefix+'emod_mgse', newname=var
    get_data, var, times, e1_mgse
    e1_mgse[*,0] = 0
    store_data, var, times, e1_mgse, limits=lim
    xyz = constant('xyz')
    vars = var+'_'+xyz
    stplot_split, var, newnames=vars
    ylim, vars[1:2], [-1,1]*6
    options, vars, 'ytitle', 'RBSP-'+strupcase(probe)+'!C(mV/m)'

    v_mgse = get_var_data(prefix+'v_mgse')
    r_mgse = get_var_data(prefix+'r_mgse')
    b_mgse = get_var_data(prefix+'b_mgse')
    omega_mgse = get_var_data(prefix+'omega_mgse')
    vcoro_mgse = get_var_data(prefix+'vcoro_mgse')

    ntime = n_elements(times)
    ndim = 3

    dalpha = 2
    alpha_range = [-1,1]*10
    alphas = smkarthm(alpha_range[0], alpha_range[1], dalpha, 'dx')
    nalpha = n_elements(alphas)
    errs = fltarr(nalpha)

    b1_mgse = b_mgse
    foreach alpha, alphas, alpha_id do begin
        r1_mgse = shift_t(r_mgse, times, alpha)
        v1_mgse = shift_t(v_mgse, times, alpha)
        u1_mgse = v1_mgse-vec_cross(omega_mgse,r1_mgse)*constant('re')

        e1_mgse = e_mgse-vec_cross(u1_mgse,b1_mgse)*1e-3
        err = stddev(snorm(e1_mgse[*,1:2]),/nan)
        errs[alpha_id] = err
        print, alpha, err
    endforeach

    min_err = min(errs, index)
    min_alpha = alphas[index]
    print, min_alpha, min_err

    r1_mgse = shift_t(r_mgse, times, min_alpha)
    v1_mgse = shift_t(v_mgse, times, min_alpha)
    u1_mgse = v1_mgse-vec_cross(omega_mgse,r1_mgse)*constant('re')
    b1_mgse = b_mgse

    e1_mgse = e_mgse-vec_cross(u1_mgse,b1_mgse)*1e-3
    e1_mgse[*,0] = 0
    store_data, prefix+'e2_mgse', times, e1_mgse, limits={$
        ytitle: 'alpha (deg): '+strmid(string(min_alpha*constant('deg'),format='(F10.3)'),2)}
    ylim, prefix+'e?_mgse', [-1,1]*6

    vars = prefix+['e1','e2']+'_mgse'
    foreach var, vars do begin
        stplot_split, var, newnames=var+'_'+xyz, labels=xyz
        ylim, var+'_'+xyz, [-1,1]*6
    endforeach
    vars = prefix+['e1_mgse_'+xyz[1:2]]
    options, prefix+['e1_mgse_'+xyz[1:2]], 'ytitle', 'E-E_mod!C(mV/m)'

    vars = prefix+['e2_mgse_'+xyz[1:2]]
    options, prefix+['e2_mgse_'+xyz[1:2]], 'ytitle', 'E1-E_mod!C(mV/m)'

    vars = prefix+['e1_mgse_'+xyz[1:2],'e2_mgse_'+xyz[1:2]]
    tplot, vars, trange=time_range
    stop

end
