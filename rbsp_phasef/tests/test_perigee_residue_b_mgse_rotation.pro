;+
; Test to allow b_mgse to rotate.
;-

function rot_x, vec0, angle

    vec = vec0
    vec[*,1] += angle*vec[*,2]
    vec[*,2] -= angle*vec[*,1]
    return, vec

end

time_range = time_double(['2012-09','2019-09'])
probes = ['a','b']
b_angle_list = list()

foreach probe, probes do begin
    prefix = 'rbsp'+probe+'_'

    var = prefix+'emod_mgse'
    if check_if_update(var) then begin
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
    u_mgse = v_mgse-vcoro_mgse

    ntime = n_elements(times)
    ndim = 3

    dalpha = 0.001
    alpha_range = [0.007,0.017]
    alphas = smkarthm(alpha_range[0], alpha_range[1], dalpha, 'dx')
    errs = fltarr(n_elements(alphas))

    u1_mgse = u_mgse
    foreach alpha, alphas, alpha_id do begin
        b1_mgse = rot_x(b_mgse, alpha)

        e1_mgse = e_mgse-vec_cross(u1_mgse,b1_mgse)*1e-3
        err = stddev(snorm(e1_mgse[*,1:2]),/nan)
        errs[alpha_id] = err
        print, err, alpha
    endforeach

    min_err = min(errs, index)
    min_alpha = alphas[index]
    print, min_err, min_alpha

    u1 = u_mgse
    b1_mgse = rot_x(b_mgse, min_alpha)

    e1_mgse = e_mgse-vec_cross(u1_mgse,b1_mgse)*1e-3
    e1_mgse[*,0] = 0
    store_data, prefix+'e2_mgse', times, e1_mgse, limits={$
        ytitle: '(mV/m)', b_angle: min_alpha}
    ylim, prefix+'e?_mgse', [-1,1]*6

    vars = prefix+['e1','e2']+'_mgse'
    msg = strmid(string(min_alpha*constant('deg'),format='(F10.3)'),2)+' (deg)'
    foreach var, vars do begin
        stplot_split, var, newnames=var+'_'+xyz, labels=xyz
        ylim, var+'_'+xyz, [-1,1]*6
        foreach label, xyz do begin
            the_var = var+'_'+label
            get_data, the_var, times, data
            err = stddev(data,/nan)
            tmp = 'mGSE E'+label+'!C  '+tex2str('sigma')+'='+strtrim(string(err,format='(F10.3)'),2)
            options, the_var, 'labels', tmp
        endforeach
    endforeach
    vars = prefix+['e1_mgse_'+xyz[1:2]]
    options, prefix+['e1_mgse_'+xyz[1:2]], 'ytitle', 'RBSP-'+strupcase(probe)+'!CE-E_mod!C(mV/m)'

    vars = prefix+['e2_mgse_'+xyz[1:2]]
    options, prefix+['e2_mgse_'+xyz[1:2]], 'ytitle', 'E-E_mod!C(mV/m)!CB_angle!C'+msg


    vars = prefix+['e1_mgse_'+xyz[1:2],'e2_mgse_'+xyz[1:2]]
    tplot, vars, trange=time_range

    b_angle_list.add, min_alpha
endforeach

print, b_angle_list

ofn = 0
sgopen, ofn, xsize=6, ysize=8
margins = [10,4,8,2]
poss = sgcalcpos(4*2, margins=margins)

foreach probe, probes do begin
    prefix = 'rbsp'+probe+'_'
    vars = prefix+['e1_mgse_'+xyz[1:2],'e2_mgse_'+xyz[1:2]]
    tpos = (probe eq 'a')? poss[*,[0,1,2,3]]: poss[*,[4,5,6,7]]
    nouttick = (probe eq 'a')? 1: 0
    tplot, vars, trange=time_range, position=tpos, noerase=1, nouttick=nouttick
endforeach

end
