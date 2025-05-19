;+
; Check the effect before and after fixing wobble in emfisis B field.
; 
; This shows that the b_mgse from rbsp_fix_b_uvw has DC offset relative to emfisis original data by several 10s nT around perigee.
; The b_mgse from a running median does not.
;-

    time_range = time_double(['2012-12-25','2012-12-26'])
    probe = 'b'


    prefix = 'rbsp'+probe+'_'
    rgb = constant('rgb')
    xyz = constant('xyz')
    vec_lim = {colors:rgb, labels:xyz}
    ndim = 3


    ; Load B UVW.
    b_uvw_var = prefix+'b_uvw'
    rbsp_read_emfisis, time_range, probe=probe, id='l2%magnetometer'

    b_mgse_var = prefix+'b_mgse_emfisis'
    get_data, b_uvw_var, times, b_uvw
    b_mgse = cotran(b_uvw, times, 'uvw2mgse', probe=probe)
    store_data, b_mgse_var, times, b_mgse, limit=vec_lim
    stplot_split, b_mgse_var, newnames=prefix+'b'+xyz+'_mgse_emfisis'


    b_mgse_var = prefix+'b_mgse'
    rbsp_fix_b_uvw, time_range, probe=probe
    b_uvw = get_var_data(prefix+'b_uvw', times=times)
    b_mgse2 = cotran(b_uvw, times, 'uvw2mgse', probe=probe)
    store_data, b_mgse_var, times, b_mgse2

    get_data, prefix+'b_mgse_emfisis', times, b_mgse
    b_mgse2 = get_var_data(prefix+'b_mgse', at=times)
    for ii=0,ndim-1 do begin
        store_data, prefix+'b'+xyz[ii]+'_mgse', times, [[b_mgse[*,ii]],[b_mgse2[*,ii]]], limits={$
            colors:sgcolor(['blue','red']), labels:['emfisis','fixed']}
        store_data, prefix+'db'+xyz[ii]+'_mgse', times, b_mgse[*,ii]-b_mgse2[*,ii]
    endfor
    
    
;---Compare to 4 sec data.
    rbsp_read_emfisis, time_range, id='l3%magnetometer', probe=probe, resolution='4sec', coord='gse', errmsg=errmsg
    get_data, prefix+'b_gse', times, b_gse
    b_mgse = cotran(b_gse, times, 'gse2mgse', probe=probe)
    b_mgse2 = get_var_data(prefix+'b_mgse', at=times)
    for ii=0,ndim-1 do begin
        store_data, prefix+'b'+xyz[ii]+'_mgse2', times, [[b_mgse[*,ii]],[b_mgse2[*,ii]]], limits={$
            colors:sgcolor(['blue','red']), labels:['emfisis','fixed']}
        store_data, prefix+'db'+xyz[ii]+'_mgse2', times, b_mgse[*,ii]-b_mgse2[*,ii]
    endfor
    store_data, prefix+'dbmag2', times, snorm(b_mgse)-snorm(b_mgse2)


;---Try a new way of correction.
    get_data, prefix+'b_mgse_emfisis', times, b_mgse
    time_step = sdatarate(times)
    width = 11d/time_step
    dr = 10
    sec_times = make_bins(time_range, dr)
    nsec_time = n_elements(sec_times)
    nrec = nsec_time-1
    b_mgse_bg = fltarr(nrec,ndim)
    for jj=1,nsec_time-1 do begin
        time_index = where_pro(times,'[]',sec_times[jj-1:jj])
        for ii=0,ndim-1 do begin
            b_mgse_bg[jj-1,ii] = median(b_mgse[time_index,ii])
        endfor
    endfor
    b_mgse3 = sinterpol(b_mgse_bg, sec_times[1:*]-dr*0.5, times, quadratic=1)
    store_data, prefix+'b_mgse3', times, b_mgse3, limits=vec_lim
    
    for ii=0,ndim-1 do begin
        store_data, prefix+'b'+xyz[ii]+'_mgse3', times, [[b_mgse[*,ii]],[b_mgse3[*,ii]]], limits={$
            colors:sgcolor(['blue','red']), labels:['emfisis','fixed2']}
        store_data, prefix+'db'+xyz[ii]+'_mgse3', times, b_mgse[*,ii]-b_mgse3[*,ii]
    endfor
    store_data, prefix+'dbmag3', times, snorm(b_mgse)-snorm(b_mgse3)

    tplot, prefix+['b'+xyz+'_mgse2','db'+xyz+'_mgse2', 'b'+xyz+'_mgse3','db'+xyz+'_mgse3']

end
