;+
; Check if there is a systematic time tag offset and rotation of B.
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

function rot_angle, vec0, angle

    ndim = 3
    nrec = n_elements(vec0)/ndim
    angs = fltarr(nrec,ndim)
    for ii=0,ndim-1 do angs[*,ii] = angle[ii]
    
    return, vec0+vec_cross(vec0, angs)

end


pro test_perigee_full_rotation_in_b, time_range, probe=probe, b_angles=b_angles, var=var

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
    rbsp_efw_phasef_read_wobble_free_var, time_range, probe=probe
    rbsp_read_e_model, time_range, probe=probe, id='e_model_related'
;
;    ; Read B UVW with the desired time tag offset.
;    rbsp_efw_phasef_read_b_uvw, time_range, probe=probe
;
;    ; Read E UVW with the desired time tag offset.
;    rbsp_efw_phasef_read_e_uvw, time_range, probe=probe


;---Select the 2nd perigee.
    dis = snorm(get_var_data(prefix+'r_mgse', time=orbit_times))
    perigee_lshell = 2.5
    index = where(dis le perigee_lshell)
    perigee_times = orbit_times[time_to_range(index,time_step=1)]
    the_time_range = reform(perigee_times[1,*])
    timespan, the_time_range[0], total(the_time_range*[-1,1]), /second
    common_times = orbit_times[where_pro(orbit_times,'[]',the_time_range)]
    ncommon_time = n_elements(common_times)
    common_time_step = sdatarate(common_times)


;;---Get V and R in mGSE manually.
;    foreach type, ['r','v'] do begin
;        gse_var = prefix+type+'_gse'
;        add_setting, gse_var, /smart, dictionary($
;            'display_type', 'vector', $
;            'short_name', strupcase(type), $
;            'coord', 'GSE', $
;            'coord_labels', xyz)
;        vec_gse = get_var_data(gse_var, at=common_times)
;
;        mgse_var = prefix+type+'_mgse'
;        get_data, q_var, uts, q_uvw2gse
;        q_uvw2gse = qslerp(q_uvw2gse, uts, common_times)
;        m_uvw2gse = qtom(q_uvw2gse)
;        wsc_gse = reform(m_uvw2gse[*,*,2])
;        vec_mgse = gse2mgse(vec_gse, common_times, wsc=wsc_gse)
;        store_data, mgse_var, common_times, vec_mgse, limits=default_lim
;    endforeach


;;---Get E and B in mGSE manually.
;    foreach type, ['e','b'] do begin
;        mgse_var = prefix+type+'_mgse'
;        uvw_var = prefix+type+'_uvw'
;        get_data, uvw_var, times, vec_uvw
;
;        get_data, q_var, uts, q_uvw2gse
;        q_uvw2gse = qslerp(q_uvw2gse, uts, times)
;        m_uvw2gse = qtom(q_uvw2gse)
;        vec_gse = rotate_vector(vec_uvw, m_uvw2gse)
;        wsc_gse = reform(m_uvw2gse[*,*,2])
;        vec_mgse = gse2mgse(vec_gse, times, wsc=wsc_gse)
;        
;        if type eq 'b' then begin
;            vec_mgse = rot_angle(vec_mgse, b_angles)
;        endif
;        store_data, prefix+type+'_mgse_raw', times, vec_mgse, limits=default_lim
;
;        vec_bg = sinterpol(vec_mgse, times, common_times, /nan)
;        store_data, mgse_var, common_times, vec_bg, limits=default_lim
;    endforeach

;---Get B in mGSE manually.
    get_data, prefix+'b_mgse', times, vec_mgse
    vec_mgse = rot_angle(vec_mgse, b_angles)
    vec_bg = sinterpol(vec_mgse, times, common_times, /nan)
    store_data, prefix+'b_mgse_new', common_times, vec_bg, limits=default_lim


;---Calc E model.
    ; Calculate E_coro. Use GSE to avoid interp quaternion.
    vcoro_var = prefix+'vcoro_mgse'
    vcoro_mgse = get_var_data(vcoro_var, at=common_times)*1e-3
    b_mgse = get_var_data(prefix+'b_mgse_new')
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
    v_mgse = get_var_data(prefix+'v_mgse', at=common_times)*1e-3
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

    label = ''
    var = prefix+'de_mgse'
    foreach b_angle, b_angles do begin
        if b_angle eq 0 then begin
            msg = '0'
        endif else begin
            msg = strtrim(string(b_angle*constant('deg'),format='(F6.3)'),2)
        endelse
        label +='!C  '+msg+' deg'
        var += '!C'+msg+'deg'
    endforeach



    diff_var = var
    dif_data, prefix+'e_mgse', prefix+'emod_mgse', newname=diff_var
    get_data, diff_var, common_times, diff
    diff[*,0] = 0
    store_data, diff_var, common_times, diff, limits=default_lim
    
    err = stddev(snorm(diff),/nan)
    options, diff_var, 'err', err
    err_str = 'err=!C  '+strtrim(string(err,format='(F6.4)'),2)
    options, diff_var, 'labels', [label,'',err_str]


end


;---Settings.
time_range = time_double(['2013-01-01','2013-01-02'])
time_range = time_double(['2014-09-01','2014-09-02'])
time_range = time_double(['2015-04-01','2015-04-02'])
time_range = time_double(['2013-03-15','2013-03-16'])
time_range = time_double(['2013-03-14','2013-03-15'])
time_range = time_double(['2012-12-25','2012-12-26'])
time_range = time_double(['2014-01-02','2014-01-03'])
date = time_range[0]
probe = 'a'

xxs = [0,[1]*0.005]   ; rad.
yys = [0]   ; rad.
;zzs = [0,[-1,1]*0.01]   ; rad.
;yys = [0]
zzs = [0]
b_angles = list()
foreach xx, xxs do foreach yy, yys do foreach zz, zzs do b_angles.add, [xx,yy,zz]

vars = []
foreach b_angle, b_angles do begin
    test_perigee_full_rotation_in_b, time_range, probe=probe, $
        b_angles=b_angle, var=var
    vars = [vars,var]
endforeach
prefix = 'rbsp'+probe+'_'

sgopen, 0, xsize=6, ysize=8
ylim, vars, [-1,1]*4

nvar = n_elements(vars)
margins = [12,4,8,2]
poss = sgcalcpos(nvar, margins=margins)
tplot_options, 'labflag', -1
tplot, vars, position=poss

end
