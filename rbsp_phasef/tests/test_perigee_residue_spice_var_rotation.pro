;+
; Test to allow r_mgse, v_mgse, and b_mgse to rotate.
;-

time_range = time_double(['2012','2014'])
probe = 'a'
prefix = 'rbsp'+probe+'_'

    ;rbsp_efw_phasef_read_e_fit_var, time_range, probe=probe

    e_mgse = get_var_data(prefix+'edotb_mgse', limits=lim)
    emod_mgse = get_var_data(prefix+'emod_mgse', times=times)
    store_data, prefix+'e_emod_angle', times, sang(e_mgse,emod_mgse,/deg)

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
    coef1 = [$
        [v_mgse[*,0]*b_mgse[*,2]],$
        [v_mgse[*,1]*b_mgse[*,2]], $
        [total(v_mgse[*,0:1]*b_mgse[*,0:1],2)]]
    coef1 *= 1e-3
    coef2 = vec_cross(r_mgse, b_mgse)
    for ii=0,ndim-1 do coef2[*,ii] *= omega_mgse[*,2]
    coef3 = [$
        [-b_mgse[*,1]],$
        [b_mgse[*,0]],$
        [fltarr(ntime)]]
    tmp = vec_dot(omega_mgse, r_mgse)*constant('re')*1e-3
    for ii=0,ndim-1 do coef3[*,ii] *= tmp
    coef4 = [$
        [u_mgse[*,2]*b_mgse[*,0]],$
        [u_mgse[*,2]*b_mgse[*,1]],$
        [total(u_mgse[*,0:1]*b_mgse[*,0:1],2)]]
    coef4 *= 1e-3
    coef_w1 = coef1+coef2+coef3
    coef_w2 = coef4

    comp = 1
    yy_y = e1_mgse[*,comp]
    xx_y = [$
        [coef_w1[*,comp]],$
        [coef_w2[*,comp]]]

    comp = 2
    yy_z = e1_mgse[*,comp]
    xx_z = [$
        [coef_w1[*,comp]],$
        [coef_w2[*,comp]]]

    yy = yy_y
    xx = transpose(xx_y)
    nfit = n_elements(xx)/ntime
    index = where(finite(total(xx,1)) and finite(yy))
    res = regress(xx[*,index],yy[index], sigma=sigma, const=const)
    print, res, const

    yy = yy_z
    xx = transpose(xx_z)
    index = where(finite(total(xx,1)) and finite(yy))
    res = regress(xx[*,index],yy[index], sigma=sigma, const=const)
    print, res, const





end
