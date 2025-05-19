;+
; Check if there is a systematic time tag offset of B.
;-


pro rbsp_efw_phasef_read_b_uvw, time_range, probe=probe

    prefix = 'rbsp'+probe+'_'
    time_step = 1d/16
    common_times = make_bins(time_range, time_step)
    ntime = n_elements(common_times)

;---Load B UVW.
    b_uvw_var = prefix+'b_uvw'
    rbsp_read_emfisis, time_range, probe=probe, id='l2%magnetometer'
    get_data, b_uvw_var, times

;---Remove invalid data and convert b_uvw to b_mgse.
    index = where_pro(times, '[]', time_range, count=count)
    if count ge 10 then begin
        ; Mask invalid data with NaN.
        cal_state = get_var_data(prefix+'cal_state', times=uts)
        mag_valid = get_var_data(prefix+'mag_valid')
        bad_index = where(cal_state ne 0 or mag_valid eq 1, count, complement=good_index)
        fillval = !values.f_nan
        pad_time = 10.   ; sec.
        if count ne 0 then begin
            time_ranges = uts[time_to_range(bad_index,time_step=1)]
            ntime_range = n_elements(time_ranges)*0.5
            b_uvw = get_var_data(b_uvw_var, times=uts)
            for ii=0,ntime_range-1 do begin
                index = where_pro(uts, '[]', time_ranges[ii,*]+[-1,1]*pad_time, count=count)
                if count eq 0 then continue
                b_uvw[index,*] = fillval
            endfor
            store_data, b_uvw_var, uts, b_uvw
        endif

        b_uvw = get_var_data(b_uvw_var, times=uts)
        b_valid = -99999
        pad_time = 0.   ; sec.
        bad_index = where((b_uvw[*,0] lt b_valid) or (b_uvw[*,1] lt b_valid) or (b_uvw[*,2] lt b_valid), count)
        if count ne 0 then begin
            time_ranges = uts[time_to_range(bad_index,time_step=1)]
            ntime_range = n_elements(time_ranges)*0.5
            for ii=0,ntime_range-1 do begin
                index = where_pro(uts, '[]', time_ranges[ii,*]+[-1,1]*pad_time, count=count)
                if count eq 0 then continue
                b_uvw[index,*] = fillval
            endfor
            store_data, b_uvw_var, uts, b_uvw
        endif

        interp_time, b_uvw_var, common_times
    endif

end


pro test_perigee_time_tag_offset_in_b, time_range, probe=probe, time_tag_offset=time_tag_offset

    ndim = 3
    rgb = constant('rgb')
    xyz = constant('xyz')
    default_lim = {colors:rgb}
    yr = [-1,1]*5
    prefix = 'rbsp'+probe+'_'


;---Load basic data.
    ; Read spice data with a time tag correction.
    rbsp_read_spice_var, time_range, probe=probe
    q_var = prefix+'q_uvw2gse'

    ; Read B UVW with the desired time tag offset.
    rbsp_efw_phasef_read_b_uvw, time_range, probe=probe

    ; Read E UVW with the desired time tag offset.
    rbsp_efw_phasef_read_e_uvw, time_range, probe=probe


;---Select the 2nd perigee.
    dis = snorm(get_var_data(prefix+'r_gse', time=orbit_times))
    perigee_lshell = 2.5
    index = where(dis le perigee_lshell)
    perigee_times = orbit_times[time_to_range(index,time_step=1)]
    the_time_range = reform(perigee_times[1,*])
    timespan, the_time_range[0], total(the_time_range*[-1,1]), /second
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
        uvw_var = prefix+type+'_uvw'
        get_data, uvw_var, times, vec_uvw

        if type eq 'b' then begin
            vec_uvw = sinterpol(vec_uvw, times+time_tag_offset, times, /quadratic)
        endif

        get_data, q_var, uts, q_uvw2gse
        q_uvw2gse = qslerp(q_uvw2gse, uts, times)
        m_uvw2gse = qtom(q_uvw2gse)
        vec_gse = rotate_vector(vec_uvw, m_uvw2gse)
        wsc_gse = reform(m_uvw2gse[*,*,2])
        vec_mgse = gse2mgse(vec_gse, times, wsc=wsc_gse)
        store_data, prefix+type+'_mgse_raw', times, vec_mgse, limits=default_lim

;        time_step = sdatarate(times)
;        min_count = common_time_step*0.5/time_step
;        vec_bg = fltarr(ncommon_time,ndim)+!values.f_nan
;        for time_id=0,ncommon_time-1 do begin
;            sec_time = common_times[time_id]+[-1,1]*common_time_step*0.5
;            time_index = where_pro(times,'[]',sec_time, count=count)
;            if count lt min_count then continue
;            for dim_id=0,ndim-1 do begin
;                dat = vec_mgse[time_index,dim_id]
;                index = where(finite(dat), count)
;                if count lt min_count then continue
;                vec_bg[time_id,dim_id] = median(dat)
;            endfor
;        endfor
        vec_bg = sinterpol(vec_mgse, times, common_times)
        store_data, mgse_var, common_times, vec_bg, limits=default_lim
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

    diff_var = prefix+'de_mgse_'+strtrim(string(time_tag_offset,format='(F10.3)'),2)
    dif_data, prefix+'e_mgse', prefix+'emod_mgse', newname=diff_var
    get_data, diff_var, common_times, diff
    diff[*,0] = 0
    store_data, diff_var, common_times, diff, limits=default_lim

end


;---Settings.
time_range = time_double(['2013-01-01','2013-01-02'])
;time_range = time_double(['2014-09-01','2014-09-02'])
;time_range = time_double(['2016-09-01','2016-09-02'])
;time_range = time_double(['2015-04-01','2015-04-02'])
time_range = time_double(['2013-03-15','2013-03-16'])
time_range = time_double(['2013-03-14','2013-03-15'])
date = time_range[0]
probe = 'b'
time_tag_offsets = make_bins([-1,1]*0.02,0.01)
time_tag_offsets = [0,make_bins([-0.030,-0.025],0.001)]
time_tag_offsets = [0,-0.03125,-0.0625]
foreach time_tag_offset, time_tag_offsets do begin
    test_perigee_time_tag_offset_in_b, time_range, probe=probe, $
        time_tag_offset=time_tag_offset
endforeach
ylim, 'rbsp?_de_mgse_*', [-1,1]*4

end
