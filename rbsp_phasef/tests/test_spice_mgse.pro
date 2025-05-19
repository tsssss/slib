;+
; Test if GSE2MGSE introduces spin tone.
;-

probe = 'b'
time_range = time_double(['2013-05-02','2013-05-03'])
time_range = time_double(['2013-05-16','2013-05-17'])
time_range = time_double(['2013-05-21','2013-05-22'])
rbsp_read_quaternion, time_range, probe=probe

test = 1

    prefix = 'rbsp'+probe+'_'

;---Spin axis.
    rbsp_read_spice, time_range, probe=probe, id='spin_phase'
    spin_phase = get_var_data(prefix+'spin_phase', times=times)*constant('rad')
    ntime = n_elements(times)
    b_uvw = fltarr(ntime,3)
    ;b_uvw[*,0] = cos(spin_phase)
    ;b_uvw[*,1] =-sin(spin_phase)
    b_uvw[*,2] = 1
    b_gse = cotran(b_uvw, times, 'uvw2gse', probe=probe)
    xyz = constant('xyz')
    for ii=0,2 do store_data, prefix+'b'+xyz[ii]+'_test', $
        times, b_gse[*,ii], limits={ytitle:'(nT)', labels:'GSE '+xyz[ii]}
        
    rbsp_read_orbit, time_range, probe=probe
    dis = snorm(get_var_data(prefix+'r_gse', times=times))
    store_data, prefix+'dis', times, dis
        
    tplot_options, 'labflag', -1
    tplot_options, 'ynozero', 1
    tplot_options, 'ycharsize', 1.5
    tplot_options, 'version', 1
    file = join_path([homedir(),'test_rbsp_uvw2gse.pdf'])
    if keyword_set(test) then file = 0
    sgopen, file, xsize=8, ysize=8, /inch, xchsz=xchsz, ychsz=ychsz
    tplot, prefix+['b'+xyz+'_test','dis'], trange=time_range, get_plot_position=poss
    if keyword_set(test) then stop
    
    sgclose
    

;---B test.
    bmod_test = dblarr(ntime,3)
    bmod_test_values = [1,2,3]
    for ii=0,2 do bmod_test[*,ii] = bmod_test_values[ii]
    bmod_test_mgse = cotran(bmod_test, times, 'gse2mgse', probe=probe)
    xyz = constant('xyz')
    for ii=0,2 do store_data, prefix+'b'+xyz[ii]+'_test', $
        times, bmod_test_mgse[*,ii], limits={ytitle:'(nT)', labels:'MGSE B'+xyz[ii]}
    tplot_options, 'labflag', -1
    tplot_options, 'ynozero', 1
    msg = 'GSE B = ('+strjoin(string(bmod_test_values,format='(I0)'),', ')+') nT'
    file = join_path([homedir(),'test_rbsp_gse2mgse.pdf'])
    if keyword_set(test) then file = 0
    sgopen, file, xsize=6, ysize=6, /inch, xchsz=xchsz, ychsz=ychsz
    tplot, prefix+'b'+xyz+'_test', trange=time_range, get_plot_position=poss
    tpos = poss[*,0]
    tx = tpos[0]
    ty = tpos[3]+ychsz*0.5
    xyouts, tx,ty,/normal, msg
    if keyword_set(test) then stop
    sgclose

end
