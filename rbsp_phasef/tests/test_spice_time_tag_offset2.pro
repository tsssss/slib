;+
; Check if the spice data (r, v, q) contain time tag offset.
;
; In this example, we shift r, v in time, not q.
;-


pro test_spice_time_tag_offset2, time_range, probe=probe, time_tag_offset=time_tag_offset

    ndim = 3
    rgb = constant('rgb')
    xyz = constant('xyz')
    default_lim = {colors:rgb}
    yr = [-1,1]*5
    prefix = 'rbsp'+probe+'_'


;---Load basic data.
    ; Read spice data with a time tag correction.
    rbsp_read_spice_var, time_range, probe=probe, time_tag_offset=time_tag_offset
    q_var = prefix+'q_uvw2gse'
    del_data, q_var

    ; Read E UVW with the desired time tag offset.
    if check_if_update(prefix+'e_mgse', time_range) then rbsp_efw_read_e_mgse, time_range, probe=probe
    if check_if_update(prefix+'b_mgse', time_range) then rbsp_efw_phasef_read_b_mgse, time_range, probe=probe


;---Select the 2nd perigee.
    dis = snorm(get_var_data(prefix+'r_gse', time=orbit_times))
    perigee_lshell = 2.5
    index = where(dis le perigee_lshell)
    perigee_times = orbit_times[time_to_range(index,time_step=1)]
    the_time_range = reform(perigee_times[1,*])
    common_times = orbit_times[where_pro(orbit_times,'[]',the_time_range)]
    ncommon_time = n_elements(common_times)
    common_time_step = sdatarate(common_times)


;---Get V and R in mGSE manually.
    foreach type, ['r','v'] do begin
        gse_var = prefix+type+'_gse'
        add_setting, gse_var, /smart, dictionary($
            'display_type', 'vector', $
            'short_name', strupcase(type), $
            'coord', 'GSE', $
            'coord_labels', xyz)
        vec_gse = get_var_data(gse_var, at=common_times)

        mgse_var = prefix+type+'_mgse'
        get_data, q_var, uts, q_uvw2gse
        q_uvw2gse = qslerp(q_uvw2gse, uts, common_times)
        m_uvw2gse = qtom(q_uvw2gse)
        wsc_gse = reform(m_uvw2gse[*,*,2])
        vec_mgse = gse2mgse(vec_gse, common_times, wsc=wsc_gse)
        store_data, mgse_var, common_times, vec_mgse, limits=default_lim
    endforeach


;---Get E and B in mGSE manually.
    foreach type, ['e','b'] do begin
        mgse_var = prefix+type+'_mgse'
        interp_time, mgse_var, common_times
    endforeach


;---Calc E model.
    ; Calculate E_coro. Use GSE to avoid interp quaternion.
    vcoro_mgse = calc_vcoro(r_var=prefix+'r_gse', probe=probe)
    vcoro_var = prefix+'vcoro_mgse'
    store_data, vcoro_var, orbit_times, vcoro_mgse
    interp_time, vcoro_var, common_times
    add_setting, vcoro_var, /smart, dictionary($
        'display_type', 'vector', $
        'unit', 'km/s', $
        'short_name', 'Coro V', $
        'coord', 'MGSE', $
        'coord_labels', xyz)

    vcoro_mgse = get_var_data(vcoro_var)*1e-3
    b_mgse = get_var_data(prefix+'b_mgse')
    ecoro_mgse = -vec_cross(vcoro_mgse,b_mgse)
    ecoro_var = prefix+'ecoro_mgse'
    store_data, ecoro_var, common_times, ecoro_mgse
    add_setting, ecoro_var, /smart, dictionary($
        'display_type', 'vector', $
        'unit', 'mV/m', $
        'short_name', 'Coro E', $
        'coord', 'MGSE', $
        'coord_labels', xyz)

    ; Calculate E_vxb.
    v_mgse = get_var_data(prefix+'v_mgse')*1e-3
    evxb_mgse = vec_cross(v_mgse,b_mgse)
    evxb_var = prefix+'evxb_mgse'
    store_data, evxb_var, common_times, evxb_mgse
    add_setting, evxb_var, /smart, dictionary($
        'display_type', 'vector', $
        'unit', 'mV/m', $
        'short_name', 'VxB E', $
        'coord', 'MGSE', $
        'coord_labels', xyz)


    ; E_model = E_coro + E_vxb.
    emod_mgse = evxb_mgse+ecoro_mgse
    emod_var = prefix+'emod_mgse'
    store_data, emod_var, common_times, emod_mgse
    add_setting, emod_var, /smart, dictionary($
        'display_type', 'vector', $
        'unit', 'mV/m', $
        'short_name', 'VxB+Coro E', $
        'coord', 'MGSE', $
        'coord_labels', xyz )

    diff_var = prefix+'de_mgse_'+strtrim(string(time_tag_offset,format='(F10.2)'),2)
    dif_data, prefix+'e_mgse', prefix+'emod_mgse', newname=diff_var
    get_data, diff_var, common_times, diff
    diff[*,0] = 0
    store_data, diff_var, common_times, diff, limits=default_lim

end


;---Settings.
time_range = time_double(['2013-01-01','2013-01-02'])
date = time_range[0]
probe = 'a'
time_tag_offsets = make_bins([-1,1],0.5)
foreach time_tag_offset, time_tag_offsets do begin
    test_spice_time_tag_offset2, time_range, probe=probe, time_tag_offset=time_tag_offset
endforeach
end
