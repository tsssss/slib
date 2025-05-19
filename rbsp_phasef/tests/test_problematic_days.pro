;+
; Test RBSP-B, 2014-06-14 to 15.
;-

probe = 'b'
; Bad on 06-15, 06-16, 06-17.
time_range = time_double(['2014-06-14','2014-06-16'])
time_range = time_double(['2014-06-14','2014-06-19'])

common_time_step = 10
common_times = make_bins(time_range, common_time_step)
xyz = constant('xyz')
prefix = 'rbsp'+probe+'_'


;rbsp_read_q_uvw2gse, time_range, probe=probe
rbsp_read_quaternion, time_range, probe=probe
rbsp_read_orbit, time_range, probe=probe

;---Load position and get model B field.
    r_gsm_var = prefix+'r_gsm'
    r_gse_var = prefix+'r_gse'
    rbsp_read_orbit, time_range, probe=probe
    r_gse = get_var_data(r_gse_var, times=orbit_times)
    r_gsm = cotran(r_gse, orbit_times, 'gse2gsm')
    store_data, r_gsm_var, orbit_times, r_gsm
    add_setting, r_gsm_var, /smart, dictionary($
        'display_type', 'vector', $
        'short_name', 'R', $
        'unit', 'Re', $
        'coord', 'GSM', $
        'coord_labels', xyz )

    par = 2.
    bmod_gsm_var = prefix+'bmod_gsm'
    r_gsm = get_var_data(r_gsm_var, at=orbit_times)
    bmod_gsm = float(r_gsm)
    foreach time, orbit_times, ii do begin
        tilt = geopack_recalc(time)
        rx = r_gsm[ii,0]
        ry = r_gsm[ii,1]
        rz = r_gsm[ii,2]
        ; in-situ B field.
        geopack_igrf_gsm, rx,ry,rz, bx,by,bz
        geopack_t89, par, rx,ry,rz, dbx,dby,dbz
        bmod_gsm[ii,*] = [bx,by,bz]+[dbx,dby,dbz]
    endforeach
    bmod_gsm = sinterpol(bmod_gsm, orbit_times, common_times, /quadratic)
    store_data, bmod_gsm_var, common_times, bmod_gsm
    add_setting, bmod_gsm_var, /smart, dictionary($
        'display_type', 'vector', $
        'short_name', 'T89 B', $
        'unit', 'nT', $
        'coord', 'GSM', $
        'coord_labels', xyz )

;---Read B field.
    b_gsm_var = prefix+'b_gsm'
    b_uvw_var = prefix+'b_uvw'
    rbsp_read_emfisis, time_range, probe=probe, id='l2%magnetometer'
    b_uvw = get_var_data(b_uvw_var, times=times)
    index = where(b_uvw[*,2] le -99999, count)
    if count ne 0 then begin
        b_uvw[index,*] = !values.f_nan
        store_data, b_uvw_var, times, b_uvw
    endif
    interp_time, b_uvw_var, common_times
    b_uvw = get_var_data(b_uvw_var)
    b_gsm = cotran(b_uvw, common_times, 'uvw2gsm', probe=probe)
    store_data, b_gsm_var, common_times, b_gsm
    add_setting, b_gsm_var, /smart, dictionary($
        'display_type', 'vector', $
        'short_name', 'B', $
        'unit', 'nT', $
        'coord', 'GSM', $
        'coord_labels', xyz )


;---Calculate E model.
    rbsp_calc_emodel, r_var=r_gsm_var, b_var=b_gsm_var, probe=probe
    
    
    foreach var, prefix+['r','b','emod'] do begin
        in_var = var+'_gsm'
        get_data, in_var, times, vec, limits=lim
        vec = cotran(vec, times, 'gsm2mgse', probe=probe)
        lim.coord = 'MGSE'
        out_var = var+'_mgse'
        store_data, out_var, times, vec
        add_setting, out_var, /smart, lim
    endforeach
    
    
;---Compare |E| in UV.
    e_uvw = get_var_data(prefix+'e_uvw', at=common_times)
    e_mgse = cotran(e_uvw, common_times, 'uvw2mgse', probe=probe)
    e_mgse[*,0] = 0
    bad_time = time_double(['2014-06-18/05:00','2014-06-18/09:00'])
    index = where_pro(mmon_times, '[]', bad_time)
    e_mgse[index,*] = !values.f_nan
    store_data, prefix+'e_mgse', common_times, e_mgse
    add_setting, prefix+'e_mgse', /smart, dictionary($
        'display_type', 'vector', $
        'short_name', 'E', $
        'unit', 'mV/m', $
        'coord', 'MGSE', $
        'coord_labels', xyz )
    interp_time, prefix+'emod_mgse', common_times
    
    foreach var, prefix+['emod','e'] do begin
        in_var = var+'_mgse'
        vec = get_var_data(in_var, times=times)
        out_var = var+'_mag'
        store_data, out_var, times, snorm(vec[*,1:2])
    endforeach
    
    
    stplot_merge, prefix+['emod','e']+'_mag', $
        colors=sgcolor(['red','blue']), labels=['|Model E|','|E|'], newname=prefix+'emag'
    store_data, prefix+'de_mgse', common_times, $
        get_var_data(prefix+'e_mgse', limits=lim)-get_var_data(prefix+'emod_mgse'), limits=lim
    options, prefix+'de_mgse', 'labels', 'MGSE dE!D'+xyz+'!N'
        
    tplot_options, 'labflag', -1
    sgopen, 0, xsize=8, ysize=8
    tplot, prefix+['bmod_gsm','b_gsm','emod_mgse','e_mgse','emag','de_mgse']


;    get_data, prefix+'q_uvw2gse', times, q_uvw2gse
;    m_uvw2gse = qtom(q_uvw2gse)
;    store_data, prefix+'w_gse', times, m_uvw2gse[*,*,2], limits={colors:constant('rgb'),labels:constant('xyz')}
;    u_gse = m_uvw2gse[*,*,0]
;    v_gse = m_uvw2gse[*,*,1]
;    rbsp_read_spin_phase, time_range, probe=probe, times=times
;    spin_phase = get_var_data(prefix+'spin_phase')*constant('rad')
;    cost = cos(spin_phase)
;    sint = sin(spin_phase)
;    x_gse = u_gse
;    for ii=0,2 do x_gse[*,ii] = u_gse[*,ii]*cost-v_gse[*,ii]*sint
;    store_data, prefix+'x_gse', times, x_gse, limits={colors:constant('rgb'),labels:constant('xyz')}
;    
;    e_uvw = get_var_data(prefix+'e_uvw', times=times)
;    rbsp_read_spin_phase, time_range, probe=probe, times=times
;    spin_phase = get_var_data(prefix+'spin_phase')*constant('rad')
;    cost = cos(spin_phase)
;    sint = sin(spin_phase)
;    eu = e_uvw[*,0]
;    ev = e_uvw[*,1]
;    ex = eu*cost-ev*sint
;    store_data, prefix+'ex', times, ex
    
end
