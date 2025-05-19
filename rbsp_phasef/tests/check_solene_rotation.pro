;+
; Check to see if the rotation angles in Solene's paper work on Buvw.
;-

;---Input.
    date = time_double('2013-06-19')
    probe = 'b'

;---Other settings.
    secofday = constant('secofday')
    xyz = constant('xyz')
    full_time_range = date+[0,secofday]
    prefix = 'rbsp'+probe+'_'
    spin_period = 11d
    common_time_step = 1d/16
    smooth_width = spin_period/common_time_step

;---Find the perigee.
    rbsp_read_orbit, full_time_range, probe=probe
    dis = snorm(get_var_data(prefix+'r_gsm', times=times))
    perigee_lshell = 1.15
    perigee_times = times[where(dis le perigee_lshell)]
    orbit_time_step = total(times[0:1]*[-1,1])
    perigee_time_ranges = time_to_range(perigee_times, time_step=orbit_time_step)
    time_range = reform(perigee_time_ranges[1,*])
    common_times = make_bins(time_range, common_time_step)
    ncommon_time = n_elements(common_times)


;---B field.
    rbsp_read_emfisis, data_time_range, probe=probe, id='l2%magnetometer'
    b_uvw = get_var_data(prefix+'b_uvw', at=common_times)
    store_data, prefix+'b_uvw', common_times, b_uvw
    add_setting, prefix+'b_uvw', /smart, dictionary($
        'display_type', 'vector', $
        'unit', 'nT', $
        'short_name', 'B', $
        'coord', 'UVW', $
        'coord_labels', constant('uvw') )
    bw = b_uvw[*,2]
    store_data, prefix+'bw', common_times, bw
    bw_bg = rbsp_remove_spintone(bw, common_times)
    bw_fg = bw-bw_bg
    store_data, prefix+'bw_fg', common_times, bw_fg
    

;---Rotate B field.
    rad = constant('rad')
    rotation_angles = (probe eq 'a')? [0.05,-0.02,-1.2]: [-0.035,0.08,-0.8] ; in the paper.
    rotation_angles = (probe eq 'a')? [0.04,-0.03,-0.5]: [-0.035,0.08,-0.6] ; in the email.
    rotation_angles *= rad
    
    b_uvw = get_var_data(prefix+'b_uvw')
    for ii=0,2 do srotate, b_uvw, rotation_angles[ii], ii
    ;vec_rotate = rotation_angles ## (fltarr(ncommon_time)+1)
    ;b_uvw -= vec_cross(b_uvw, vec_rotate)
    store_data, prefix+'b_uvw_solene', common_times, b_uvw
    add_setting, prefix+'b_uvw_solene', /smart, dictionary($
        'display_type', 'vector', $
        'unit', 'nT', $
        'short_name', 'B', $
        'coord', 'UVW', $
        'coord_labels', constant('uvw') )
    bw = b_uvw[*,2]
    store_data, prefix+'bw_solene', common_times, bw
    bw_bg = rbsp_remove_spintone(bw, common_times)
    bw_fg = bw-bw_bg
    store_data, prefix+'bw_solene_fg', common_times, bw_fg
    
    b_uvw = get_var_data(prefix+'b_uvw')
    for ii=0,2 do srotate, b_uvw, -rotation_angles[ii], ii
    ;vec_rotate = rotation_angles ## (fltarr(ncommon_time)+1)
    ;b_uvw += vec_cross(b_uvw, vec_rotate)
    store_data, prefix+'b_uvw_solene_backward', common_times, b_uvw
    add_setting, prefix+'b_uvw_solene_backward', /smart, dictionary($
        'display_type', 'vector', $
        'unit', 'nT', $
        'short_name', 'B', $
        'coord', 'UVW', $
        'coord_labels', constant('uvw') )
    bw = b_uvw[*,2]
    store_data, prefix+'bw_solene_backward', common_times, bw
    bw_bg = rbsp_remove_spintone(bw, common_times)
    bw_fg = bw-bw_bg
    store_data, prefix+'bw_solene_fg_backward', common_times, bw_fg
    
    tplot, prefix+['bw_fg','bw_solene_fg','bw_solene_fg_backward'], trange=time_range
end
