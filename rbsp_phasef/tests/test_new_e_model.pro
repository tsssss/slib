pro read_solene_efield, file

    data = (read_ascii(file)).FIELD01
    base = file_basename(file)
    probe = strlowcase(strmid(base,0,1))
    prefix = 'rbsp'+probe+'_'
    date = strmid(base,36,6)
    date = time_double(date,tformat='yyMMDD')

    rgb = constant('rgb')
    xyz = constant('xyz')

    time = reform(data[0,*])
    time = time+date


    vxi = reform(data[1,*])
    vyi = reform(data[2,*])
    vzi = reform(data[3,*])

    vx = reform(data[4,*])
    vy = reform(data[5,*])
    vz = reform(data[6,*])

    bx = reform(data[7,*])
    by = reform(data[8,*])
    bz = reform(data[9,*])

    store_data, prefix+'ExBscxGSE!Cinertial-frame',data={x:time,y:[[vxi],[vyi],[vzi]]},dlim={labels:['x','y','z'],colors:rgb}
    store_data, prefix+'ExBscxGSE!Cspacecraft-frame',data={x:time,y:[[vx],[vy],[vz]]},dlim={labels:['x','y','z'],colors:rgb}
    store_data, prefix+'b_gse_solene',data={x:time,y:[[bx],[by],[bz]]},dlim={labels:['x','y','z'],colors:rgb}

    ex = (vy*bz-vz*by)/1000.
    ey = (vz*bx-vx*bz)/1000.
    ez = (vx*by-vy*bx)/1000.

    store_data, prefix+'E-GSE-from-vXB!Cspacecraft-frame',data={x:time,y:[[ex],[ey],[ez]]},dlim={labels:['x','y','z'],colors:rgb}

    exi = (vyi*bz-vzi*by)/1000.
    eyi = (vzi*bx-vxi*bz)/1000.
    ezi = (vxi*by-vyi*bx)/1000.

    store_data, prefix+'E-GSE-from-vXB!Cinertial-frame',data={x:time,y:[[exi],[eyi],[ezi]]},dlim={labels:['x','y','z'],colors:rgb}


    re1 = 1d/constant('re')
    store_data, prefix+'r_gse', time, transpose(data[11:13,*])*re1, limits={$
        labels:xyz, colors:rgb}
    store_data, prefix+'v_gse', time, transpose(data[14:16,*]), limits={$
        labels:xyz, colors:rgb}


    vars = prefix+[$
        'b_gse_solene', $
        'ExBscxGSE!Cinertial-frame', $
        'ExBscxGSE!Cspacecraft-frame', $
        'E-GSE-from-vXB!Cspacecraft-frame', $
        'E-GSE-from-vXB!Cinertial-frame' ]
    foreach var, vars do begin
        pos = strpos(strlowcase(var),'gse')
        new_var = strmid(var,0,pos)+'mGSE'+strmid(var,pos+3)
        get_data, var, times, e_gse
        e_mgse = cotran(e_gse, times, 'gse2mgse', probe=probe)
        store_data, new_var, times, e_mgse, limits={$
            labels: xyz, colors:rgb }
    endforeach
end




    time_range = time_double('2012-12-22')+[0,86400d]
;    time_range = time_double('2013-10-06')+[0,86400d]
    probe = 'b'


    prefix = 'rbsp'+probe+'_'
    rgb = constant('rgb')
    xyz = constant('xyz')
    vec_lim = {colors:rgb, labels:xyz}
    ndim = 3



;---Read Solene's data.
    path = join_path([googledir(),'works','scottthaller','solene_efield_comparison','GSE'])
    base = apply_time_to_pattern(strupcase(probe)+'_ExBGSE_0andT_BGSE_SCPOT_XGSE_VGSE_%y%m%d.txt', time_range[0])
    file = join_path([path,base])
    if ~file_test(file) then message, 'File does not exist ...'
    read_solene_efield, file


    ; Load wobble free data.
    rbsp_efw_phasef_read_wobble_free_var, time_range, probe=probe

;    foreach var, prefix+['r','v']+'_mgse' do begin
;        get_data, var, times, data
;        store_data, var, times-1, data
;    endforeach

    foreach var, prefix+['b']+'_mgse' do begin
        get_data, var, times, data
        store_data, var, times+0.5d*1/64, data
    endforeach
    
    ; Use solene's b_mgse.
    copy_data, prefix+'b_mGSE_solene', prefix+'b_mgse'


;---Calc emodel.
    common_time_step = 10.
    common_times = make_bins(time_range, common_time_step)
    common_times = make_bins(time_range+[1,0]*common_time_step, common_time_step)
    foreach var, prefix+['r','v','b']+'_mgse' do interp_time, var, common_times


;---Calculate E_coro.
    vcoro_mgse = calc_vcoro(r_var=prefix+'r_mgse', probe=probe)
    vcoro_var = prefix+'vcoro_mgse'
    store_data, vcoro_var, common_times, vcoro_mgse
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

;---Calculate E_vxb.
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


;---E_model = E_coro + E_vxb.
    emod_mgse = evxb_mgse+ecoro_mgse
    emod_var = prefix+'emod_mgse'
    store_data, emod_var, common_times, emod_mgse
    add_setting, emod_var, /smart, dictionary($
        'display_type', 'vector', $
        'unit', 'mV/m', $
        'short_name', 'VxB+Coro E', $
        'coord', 'MGSE', $
        'coord_labels', xyz )

;get_data, prefix+'emod_mgse', times, data
;store_data, prefix+'emod_mgse', times-1, data
;interp_time, prefix+'emod_mgse', common_times

;---Test using e_mgse.
    get_data, emod_var, common_times, emod_mgse
    rbsp_efw_read_e_mgse, time_range, probe=probe
get_data, prefix+'e_mgse', times, data
store_data, prefix+'e_mgse', times-1d/16, data
    e_mgse = get_var_data(prefix+'e_mgse', at=common_times)
    e_mgse = e_mgse-emod_mgse
    e_mgse[*,0] = 0
    store_data, prefix+'e_mgse1', common_times, e_mgse, limits=vec_lim


;---Load the previous version of spinfit E field.
    rbsp_efw_phasef_read_spinfit_efield, time_range, probe=probe
    bp = rbsp_efw_phasef_get_boom_pair(time_range, probe=probe)
    e_var = prefix+'e_spinfit_mgse_v'+bp
    e_mgse = get_var_data(e_var, times=times)
    store_data, prefix+'e_mgse_in_corotation_frame', times, e_mgse, limits={$
        labels:xyz, colors:rgb}
    rbsp_efw_read_l3, time_range, probe=probe

    vars = prefix+['e_mgse1','e_mgse_in_corotation_frame',$
        'ExBscxmGSE!Cinertial-frame','efw_efield_in_corotation_frame_spinfit_mgse']
    options, vars, 'colors', rgb
    options, vars, 'labels', xyz
    tplot, vars, trange=time_range

end
