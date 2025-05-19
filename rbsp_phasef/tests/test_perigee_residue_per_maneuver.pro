;+
; Test to allow r_mgse, v_mgse, and b_mgse to rotate.
;-

function rot_z, vec0, angle

    vec = vec0
    vec[*,1] += angle*vec[*,2]
    vec[*,2] -= angle*vec[*,1]
    return, vec

end

;---Settings.
    probe = 'b'
    prefix = 'rbsp'+probe+'_'
    fit_times = rbsp_efw_phasef_read_e_fit_times(probe=probe)
    fit_info_list = list()
    nfit_period = n_elements(fit_times)-1
    for fit_id=0,nfit_period-1 do begin
        time_range = fit_times[fit_id:fit_id+1]

    ;---Load data.
        var = prefix+'emod_mgse'
        if check_if_update(var, time_range) then begin
            rbsp_efw_phasef_read_e_fit_var, time_range, probe=probe
        endif

    ;---Original perigee E field.
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

    ;---Calc new perigee E field.
        e_mgse = get_var_data(prefix+'e_mgse', times=times, in=time_range)
        v_mgse = get_var_data(prefix+'v_mgse', in=time_range)
        r_mgse = get_var_data(prefix+'r_mgse', in=time_range)
        b_mgse = get_var_data(prefix+'b_mgse', in=time_range)
        omega_mgse = get_var_data(prefix+'omega_mgse', in=time_range)
        vcoro_mgse = get_var_data(prefix+'vcoro_mgse', in=time_range)
        u_mgse = v_mgse-vcoro_mgse

        ntime = n_elements(times)
        ndim = 3

    ;---Angle for v and r.
        dalpha = 0.005
        alpha_range = [-1,1]*0.05
        alphas = smkarthm(alpha_range[0], alpha_range[1], dalpha, 'dx')
        nalpha = n_elements(alphas)

    ;---Angle for B.
        dbeta = 0.005
        beta_range = [-1,1]*0.05
        betas = smkarthm(beta_range[0], beta_range[1], dbeta, 'dx')
        nbeta = n_elements(betas)

        errs = fltarr(nalpha,nbeta)

        foreach beta, betas, beta_id do begin
            b1_mgse = rot_z(b_mgse, beta)
            foreach alpha, alphas, alpha_id do begin
                r1_mgse = rot_z(r_mgse, alpha)
                v1_mgse = rot_z(v_mgse, alpha)
                u1_mgse = v1_mgse-vec_cross(omega_mgse,r1_mgse)*constant('re')

                e1_mgse = e_mgse-vec_cross(u1_mgse,b1_mgse)*1e-3
                err = stddev(snorm(e1_mgse[*,1:2]),/nan)
                errs[alpha_id,beta_id] = err
                print, alpha, beta, err
            endforeach
        endforeach

        min_err = min(errs, tmp)
        index = array_indices(errs, tmp)
        min_alpha = alphas[index[0]]
        min_beta = betas[index[1]]
        print, min_err, min_alpha, min_beta

        r1_mgse = rot_z(r_mgse, min_alpha)
        v1_mgse = rot_z(v_mgse, min_alpha)
        u1_mgse = v1_mgse-vec_cross(omega_mgse,r1_mgse)*constant('re')
        b1_mgse = rot_z(b_mgse, min_beta)

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

        info = dictionary($
            'time_range', time_range, $
            'probe', probe, $
            'alpha', min_alpha, $
            'beta', min_beta, $
            'err', min_err )
        foreach type, ['1','2'] do begin
            key = 'stddev_'+type
            info[key] = stddev(snorm((get_var_data(prefix+'e'+type+'_mgse'))[*,1:2]),/nan)
        endforeach

        print, info
        fit_info_list.add, info
        
        deg = constant('deg')
        contour, errs, alphas*deg, betas*deg, nlevel=20, $
            xstyle=1, xtitle='Angle for SPICE (deg)', $
            ystyle=1, ytitle='Angle for B (deg)'
        stop
    endfor




end
