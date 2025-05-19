;+
; Check if Solene's B field gives smaller residue E field.
;-

time_range = time_double(['2013-06-19/09:50','2013-06-19/10:20'])
time_range = time_double(['2013-06-19','2013-06-20'])
file = join_path([homedir(),'Downloads','B_ExBGSE_0andT_BGSE_SCPOT_XGSE_VGSE_130619.txt'])
date = strmid(file_basename(file),36,6)
probe = strlowcase(strmid(file_basename(file),0,1))
prefix = 'rbsp'+probe+'_'
xyz = constant('xyz')


;---Solene.
    data = (read_ascii(file)).(0)
    time0 = time_double(date,tformat='yyMMDD')
    times = reform(data[0,*])+time0
    ntime = n_elements(times)
    ndim = 3
    b_gse = fltarr(ntime,ndim)
    for ii=0,ndim-1 do b_gse[*,ii] = reform(data[7+ii,*])
    spin_period = 11.
    uts = make_bins(time0+[0,86400], spin_period)
    b_gse = sinterpol(b_gse, times, uts)
    index = where(times[1:-1]-times[0:-2] ge spin_period*1.1, count)
    for ii=0, count-1 do b_gse[where_pro(uts,'[]',times[index[ii]+[0,1]]),*] = !values.f_nan
    if times[0] gt uts[0] then b_gse[where_pro(uts,'[]',[uts[0],times[0]]),*] = !values.f_nan
    if times[-1] lt uts[-1] then b_gse[where_pro(uts,'[]',[times[-1],uts[-1]]),*] = !values.f_nan
    store_data, prefix+'b_solene_gse', uts, b_gse
    add_setting, prefix+'b_solene_gse', /smart, dictionary($
        'display_type', 'vector', $
        'unit', 'nT', $
        'short_name', 'B', $
        'coord', 'Solene GSE', $
        'coord_labels', xyz )
    store_data, prefix+'bmag_solene', uts, snorm(b_gse)
    b_solene_mgse = cotran(b_gse, uts, 'gse2mgse', probe=probe)
    store_data, prefix+'b_solene_mgse', uts, b_solene_mgse
    add_setting, prefix+'b_solene_mgse', /smart, dictionary($
        'display_type', 'vector', $
        'unit', 'nT', $
        'short_name', 'B', $
        'coord', 'Solene MGSE', $
        'coord_labels', xyz)
    bmag_solene = snorm(b_solene_mgse)
    store_data, prefix+'bmag_solene', uts, bmag_solene
    add_setting, prefix+'bmag_solene', /smart, dictionary($
        'display_type', 'scalar', $
        'unit', 'nT', $
        'short_name', 'Solene |B|' )


;---Load R, V, E, quaternion.
    rbsp_read_orbit, time_range, probe=probe
    rbsp_read_sc_vel, time_range, probe=probe
    rbsp_read_efield, time_range, probe=probe, resolution='hires'
    rbsp_read_quaternion, time_range, probe=probe
    rbsp_read_bfield, time_range, probe=probe

    
    uts = uts[where_pro(uts, '[]', time_range)]
    e_gsm = get_var_data(prefix+'e_gsm', at=uts)
    e_mgse = cotran(e_gsm, uts, 'gsm2mgse', probe=probe)
    store_data, prefix+'e_mgse', uts, e_mgse
    add_setting, prefix+'e_mgse', /smart, dictionary($
        'display_type', 'vector', $
        'unit', 'mV/m', $
        'short_name', 'E', $
        'coord', 'EFW MGSE', $
        'coord_labels', xyz)
    v_gsm = get_var_data(prefix+'v_gsm', at=uts)
    v_mgse = cotran(v_gsm, uts, 'gsm2mgse', probe=probe)
    store_data, prefix+'v_mgse', uts, v_mgse
    add_setting, prefix+'v_mgse', /smart, dictionary($
        'display_type', 'vector', $
        'unit', 'km/s', $
        'short_name', 'V', $
        'coord', 'MGSE', $
        'coord_labels', xyz)
    r_gsm = get_var_data(prefix+'r_gsm', at=uts)
    r_mgse = cotran(r_gsm, uts, 'gsm2mgse', probe=probe)
    store_data, prefix+'r_mgse', uts, r_mgse
    add_setting, prefix+'r_mgse', /smart, dictionary($
        'display_type', 'vector', $
        'unit', 'Re', $
        'short_name', 'R', $
        'coord', 'MGSE', $
        'coord_labels', xyz)

    omega = (2*!dpi)/86400d  ;Earth's rotation angular frequency
    re = constant('re')
    r_gei = cotran(r_gsm, uts, 'gsm2gei')
    vcoro_gei = r_gei
    vcoro_gei[*,0] = -r_gei[*,1]*omega
    vcoro_gei[*,1] =  r_gei[*,0]*omega
    vcoro_gei[*,2] = 0.0
    vcoro_mgse = cotran(vcoro_gei, uts, 'gei2mgse', probe=probe)*re


    b_mgse = get_var_data(prefix+'b_solene_mgse', at=uts)
    evxb_mgse = vec_cross(v_mgse, b_mgse)*1e-3
    store_data, prefix+'evxb_mgse', uts, evxb_mgse
    add_setting, prefix+'evxb_mgse', /smart, dictionary($
        'display_type', 'vector', $
        'unit', 'mV/m', $
        'short_name', 'E', $
        'coord', 'Solene MGSE', $
        'coord_labels', xyz)
        
    calc_ecoro, r_var=prefix+'r_mgse', b_var=prefix+'b_solene_mgse', probe=probe, save_to=prefix+'ecoro_solene_mgse'
    ecoro_mgse = get_var_data(prefix+'ecoro_solene_mgse', at=uts)
    add_setting, prefix+'ecoro_solene_mgse', /smart, dictionary($
        'display_type', 'vector', $
        'unit', 'mV/m', $
        'short_name', 'Coro E', $
        'coord', 'Solene MGSE', $
        'coord_labels', xyz)
    
    de_mgse = e_mgse-evxb_mgse-ecoro_mgse
    de_mgse[*,0] = 0
    store_data, prefix+'de_solene_mgse', uts, de_mgse
    add_setting, prefix+'de_solene_mgse', /smart, dictionary($
        'display_type', 'vector', $
        'unit', 'mV/m', $
        'short_name', 'dE', $
        'coord', 'Solene MGSE', $
        'coord_labels', xyz)


    b_gsm = get_var_data(prefix+'b_gsm', at=uts)
    b_mgse = cotran(b_gsm, uts, 'gsm2mgse', probe=probe)
    store_data, prefix+'b_mgse', uts, b_mgse
    add_setting, prefix+'b_mgse', /smart, dictionary($
        'display_type', 'vector', $
        'unit', 'nT', $
        'short_name', 'B', $
        'coord', 'MGSE', $
        'coord_labels', xyz)
    calc_evxb, b_var=prefix+'b_mgse', v_var=prefix+'v_mgse', save_to=prefix+'evxb_emfisis_mgse', probe=probe
    evxb_mgse = get_var_data(prefix+'evxb_emfisis_mgse')
    store_data, prefix+'evxb_emfisis_mgse', uts, evxb_mgse
    add_setting, prefix+'evxb_emfisis_mgse', /smart, dictionary($
        'display_type', 'vector', $
        'unit', 'mV/m', $
        'short_name', 'E', $
        'coord', 'Emfisis MGSE', $
        'coord_labels', xyz)

    calc_ecoro, r_var=prefix+'r_mgse', b_var=prefix+'b_mgse', probe=probe, save_to=prefix+'ecoro_emfisis_mgse'
    ecoro_mgse = get_var_data(prefix+'ecoro_emfisis_mgse', at=uts)
    add_setting, prefix+'ecoro_emfisis_mgse', /smart, dictionary($
        'display_type', 'vector', $
        'unit', 'mV/m', $
        'short_name', 'Coro E', $
        'coord', 'Emfisis MGSE', $
        'coord_labels', xyz)
    de_mgse = e_mgse-evxb_mgse-ecoro_mgse
    de_mgse[*,0] = 0
    store_data, prefix+'de_emfisis_mgse', uts, de_mgse
    add_setting, prefix+'de_emfisis_mgse', /smart, dictionary($
        'display_type', 'vector', $
        'unit', 'mV/m', $
        'short_name', 'dE', $
        'coord', 'Emfisis MGSE', $
        'coord_labels', xyz)


end
