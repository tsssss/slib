;+
; Check the MGSE B field between Solene and mine.
; According to my notes: the spin tone in xyz represents the offset in angle.
; The smoothed version is the ideal xyz components.
;-

time_range = time_double(['2013-06-19/09:50','2013-06-19/10:20'])
;time_range = time_double(['2013-06-19','2013-06-20'])
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


;---Emfisis.
    rbsp_read_emfisis, time_range, probe=probe, id='l3%magnetometer', resolution='hires', coord='gse'
    add_setting, prefix+'b_gse', /smart, dictionary($
        'display_type', 'vector', $
        'unit', 'nT', $
        'short_name', 'B', $
        'coord', 'Emfisis GSE', $
        'coord_labels', xyz )
    b_gse = get_var_data(prefix+'b_gse', times=uts)
    b_mgse = cotran(b_gse, uts, 'gse2mgse', probe=probe)
    store_data, prefix+'b_emfisis_mgse', uts, b_mgse
    add_setting, prefix+'b_emfisis_mgse', /smart, dictionary($
        'display_type', 'vector', $
        'unit', 'nT', $
        'short_name', 'B', $
        'coord', 'Emfisis MGSE', $
        'coord_labels', xyz )
    bmag = snorm(b_gse)
    store_data, prefix+'bmag_emfisis', uts, bmag
    add_setting, prefix+'bmag_emfisis', /smart, dictionary($
        'display_type', 'scalar', $
        'unit', 'nT', $
        'short_name', 'Emfisis |B|' )
    
;---Sheng
    b_sheng_mgse = rbsp_remove_spintone(b_mgse, uts)
    store_data, prefix+'b_sheng_mgse', uts, b_sheng_mgse
    add_setting, prefix+'b_sheng_mgse', /smart, dictionary($
        'display_type', 'vector', $
        'unit', 'nT', $
        'short_name', 'B', $
        'coord', 'Sheng MGSE', $
        'coord_labels', xyz )
    bmag_sheng = snorm(b_sheng_mgse)
    store_data, prefix+'bmag_sheng', uts, bmag_sheng
    add_setting, prefix+'bmag_sheng', /smart, dictionary($
        'display_type', 'scalar', $
        'unit', 'nT', $
        'short_name', 'Sheng |B|' )

;---T89.
    pflux_grant_read_level1_data, time_range, probe=probe, id='bfield'
    bmod_gsm = get_var_data(prefix+'bmod_gsm', at=uts)
    b_t89_mgse = cotran(bmod_gsm, uts, 'gsm2mgse', probe=probe)
    store_data, prefix+'b_t89_mgse', uts, b_t89_mgse
    add_setting, prefix+'b_t89_mgse', /smart, dictionary($
        'display_type', 'vector', $
        'unit', 'nT', $
        'short_name', 'T89 B', $
        'coord', 'MGSE', $
        'coord_labels', xyz )
    bmag_t89 = snorm(b_t89_mgse)
    store_data, prefix+'bmag_t89', uts, bmag_t89
    add_setting, prefix+'bmag_t89', /smart, dictionary($
        'display_type', 'scalar', $
        'unit', 'nT', $
        'short_name', 'T89 |B|' )


;---Combine them.
    vars = ['solene','sheng','t89','emfisis']
    nvar = n_elements(vars)
    labels = vars & foreach label, labels, ii do labels[ii] = str_cap(label)
    colors = sgcolor(['red','green','blue','black'])
    get_data, prefix+'bmag_t89', times
    ntime = n_elements(times)
    data = fltarr(ntime,nvar)
    foreach var, vars, ii do data[*,ii] = get_var_data(prefix+'bmag_'+var, at=times)
    store_data, prefix+'bmag', times, data, limits={$
        colors:colors, labels:'|B| '+labels, ytitle:'(nT)'}
    ndim = 3
    for jj=0,ndim-1 do begin
        foreach var, vars, ii do data[*,ii] = (get_var_data(prefix+'b_'+var+'_mgse', at=times))[*,jj]
        store_data, prefix+'b'+xyz[jj]+'_mgse', times, data, limits={$
            colors:colors, labels:'MGSE B'+xyz[jj]+' '+labels, ytitle:'(nT)'}
    endfor
    
    tplot_options, 'ynozero', 1
    tplot_options, 'labflag', -1
    
    
    deg = constant('deg')
    bmag = get_var_data(prefix+'bmag', times=times)
    for jj=0,ndim-1 do begin
        bj_mgse = get_var_data(prefix+'b'+xyz[jj]+'_mgse')
        angle = (acos(bj_mgse[*,0]/bmag[*,0])-acos(bj_mgse[*,1]/bmag[*,0]))*deg
        store_data, prefix+'b'+xyz[jj]+'_angle', times, angle, limits={$
            ytitle:'(deg)'}
    endfor

stop



end
