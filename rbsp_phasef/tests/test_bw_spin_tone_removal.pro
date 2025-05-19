;+
; Test to remove Bw spin tone in MGSE.
;-

;---Input.
    date = time_double('2014-07-19')
    probe = 'a'

    secofday = constant('secofday')
    time_range = date+[0,secofday]
    prefix = 'rbsp'+probe+'_'
    rgb = constant('rgb')
    xyz = constant('xyz')


;---Load data.
    if check_if_update(prefix+'b_gsm', time_range) then $
        pflux_grant_read_level1_data, time_range, probe=probe, id='bfield'
    if check_if_update(prefix+'r_gsm', time_range) then $
        rbsp_read_orbit, time_range, probe=probe
    if check_if_update(prefix+'q_uvw2gsm', time_range) then $
        rbsp_read_quaternion, time_range, probe=probe


;---Work in MGSE.
    vars = prefix+['b','bmod','r']
    foreach var, vars do begin
        if ~check_if_update(var+'_mgse', time_range) then continue
        vec = get_var_data(var+'_gsm', times=times)
        vec = cotran(vec, times, 'gsm2mgse', probe=probe)
        store_data, var+'_mgse', times, vec, limits={colors:rgb, labels:xyz}
    endforeach

;    if check_if_update(prefix+'db_mgse', time_range) then begin
;        b_mgse = get_var_data(prefix+'b_mgse', times=common_times)
;        bmod_mgse = get_var_data(prefix+'bmod_mgse')
;        db_mgse = b_mgse-bmod_mgse
;        store_data, prefix+'db_mgse', common_times, db_mgse, limits={colors:rgb, labels:xyz}
;    endif


    spin_period = 12.
    ndim = 3

    get_data, prefix+'b_gsm', common_times
    common_time_step = total(common_times[0:1]*[-1,1])
    spin_width = spin_period/common_time_step
    b_mgse = get_var_data(prefix+'b_mgse')
    bmod_mgse = get_var_data(prefix+'bmod_mgse')
    db_mgse = b_mgse-bmod_mgse
    b0_mgse = db_mgse
    for ii=0,ndim-1 do b0_mgse[*,ii] = smooth(db_mgse[*,ii],spin_width,/edge_truncate,/nan)+bmod_mgse[*,ii]
    b1_mgse = b_mgse-b0_mgse


;---Focus on x-component.
    deg = constant('deg')

    bx = b_mgse[*,0]
    b0mag = snorm(b0_mgse)
    store_data, prefix+'b0mag', common_times, b0mag, limits={$
        ytitle:'(nT)', labels: '|B|'}
    bx_center = b0_mgse[*,0]
    alpha = acos(bx/b0mag)
    alpha0 = smooth(alpha, spin_width, /edge_truncate, /nan)
    store_data, prefix+'alpha0', common_times, alpha0*deg, limits={$
        ytitle:'(deg)', labels: 'Angle b/w!C  B and w'}
    dalpha = alpha-alpha0
    dalpha = sqrt(dalpha^2+shift(dalpha,spin_width*0.25)^2)
    dalpha = smooth(dalpha, spin_width, /edge_truncate, /nan)
    store_data, prefix+'alpha', common_times, dalpha*deg, limits={$
        ytitle:'(deg)', labels: 'dw', yrange:[0,0.5]}

test = 0
    tplot_options, 'ynozero', 1
    tplot_options, 'labflag', -1
    plot_file = join_path([srootdir(),'test_bw_spin_tone_removal_'+time_string(date,tformat='YYYY_MMDD')+'_v01.pdf'])
    if keyword_set(test) then plot_file = test
    sgopen, plot_file, xsize=8, ysize=6
    tplot, prefix+['alpha0','alpha','b0mag'], trange=time_range
    if keyword_set(test) then stop
    sgclose

stop

end
