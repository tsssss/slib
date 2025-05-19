;+
; Check hires r_gsm and that from interpolation.
;-


pro check_hires_r_gsm, date, probe=probe, component_index=component_index
    prefix = 'rbsp'+probe+'_'


;---Get time range.
    full_time_range = date[0]+[0,constant('secofday')]
    rbsp_read_orbit, full_time_range, probe=probe
    dis = snorm(get_var_data(prefix+'r_gsm', times=times))
    index = where(dis le 1.8, count)
    if count eq 0 then message, 'Inconsistency...'
    perigee_time_ranges = time_to_range(times[index], time_step=total(times[0:1]*[-1,1]))
    time_range = reform(perigee_time_ranges[1,*])
    time_range = time_range-(time_range mod 60)

;---Common times.
    hires_time_step = 1d/16
    hires_times = make_bins(time_range, hires_time_step)

;---Version 1: from spice.
    defsysv,'!rbsp_spice', exists=flag
    if flag eq 0 then rbsp_load_spice_kernel
    rbsp_load_spice_state, probe=probe, coord='gsm', times=hires_times, /no_spice_load
    tplot_rename, prefix+'state_pos_gsm', prefix+'r_gsm_spice'
    r_gsm_spice = get_var_data(prefix+'r_gsm_spice')/constant('re')
    store_data, prefix+'r_gsm_spice', limits=limits



;---Version 2: from interpolation.
    rbsp_read_sc_vel, full_time_range, probe=probe
    r_gsm = get_var_data(prefix+'r_gsm', times=times, limits=limits)

    ; Spline.
    r_gsm_interp = sinterpol(r_gsm, times, hires_times, /spline)
    store_data, prefix+'r_spline', hires_times, r_gsm_interp, limits=limits
    dr_interp = r_gsm_spice-r_gsm_interp
    store_data, prefix+'dr_spline', hires_times, dr_interp, limits=limits

    ; Linear.
    r_gsm_interp = sinterpol(r_gsm, times, hires_times)
    store_data, prefix+'r_linear', hires_times, r_gsm_interp, limits=limits
    dr_interp = r_gsm_spice-r_gsm_interp
    store_data, prefix+'dr_linear', hires_times, dr_interp, limits=limits

    ; Quadratic.
    r_gsm_interp = sinterpol(r_gsm, times, hires_times, /quadratic)
    store_data, prefix+'r_quadratic', hires_times, r_gsm_interp, limits=limits
    dr_interp = r_gsm_spice-r_gsm_interp
    store_data, prefix+'dr_quadratic', hires_times, dr_interp, limits=limits


    ; Single component.
    xyz = constant('xyz')
    component = xyz[component_index]

    store_data, prefix+'r'+component+'_spice', hires_times, r_gsm_spice[*,component_index], limits={ytitle:'(Re)', labels:'SPICE'}

    var_types = ['quadratic','spline','linear']
    foreach var_type, var_types do begin
        in_var = prefix+'dr_'+var_type
        get_data, in_var, times, vec, limits=limits
        out_var = prefix+'dr'+component+'_'+var_type
        store_data, out_var, times, vec[*,component_index], limits={ytitle:'(Re)', labels:str_cap(var_type)}
    endforeach


    plot_vars = prefix+['dr'+component+'_'+var_types,'r'+component+'_spice']
    plot_labels = 'GSM '+['dR'+component+'!C'+var_types+' - SPICE','R'+component+'!CSPICE']
    options, plot_vars, 'ynozero', 1
    options, plot_vars, 'labflag', -1
    options, plot_vars, 'ystyle', 1
    options, plot_vars, 'yticks', 2
    options, plot_vars, 'yminor', 5
    options, plot_vars, 'xticklen', -0.015
    options, plot_vars, 'yticklen', -0.005
    options, plot_vars, 'constant', 0
    tplot_options, 'version', 3

    plot_time = mean(time_range)
    plot_time = plot_time-(plot_time mod 60)
    plot_time_range = plot_time+[0,120]
    foreach var, plot_vars do begin
        data = get_var_data(var, in=plot_time_range)
        yrange = sg_autolim(minmax(data))
        options, var, 'yrange', yrange
    endforeach


;---Gen plot.
    plot_file = join_path([homedir(),'rbsp_phase_f',$
        prefix+time_string(time_range[0],tformat='YYYY_MMDD')+'_pos_study_r'+component+'_v01.pdf'])
    if keyword_set(test) then plot_file = test
    sgopen, plot_file, xsize=12, ysize=8, /inch

    nplot_var = n_elements(plot_vars)
    ypans = [intarr(nplot_var-1)+1,2]
    margins = [18,5,10,3]
    poss = sgcalcpos(nplot_var, ypans=ypans, margins=margins, xchsz=xchsz, ychsz=ychsz)
    tplot, plot_vars, trange=plot_time_range, position=poss

    ; Add time ruler.
    tpos = poss[*,-1]
    plot, plot_time_range, [0,1], /nodata, /noerase, xstyle=5, ystyle=5, position=tpos
    times = plot_time_range[0]+10+[0,1]
    timebar, times, color=sgcolor('red')
    txs = times
    foreach time, times, ii do txs[ii] = (convert_coord([time,0],/data,/to_normal))[0]
    ;foreach tx,txs do plots, tx+[0,0],tpos[[1,3]],/normal, color=sgcolor('red')
    tx = txs[1]+xchsz*0.5
    ty = tpos[3]-ychsz*1
    xyouts, tx,ty,/normal, '1 sec', color=sgcolor('red')

    ; Labels.
    label_letters = letters(nplot_var)
    for ii=0,nplot_var-1 do begin
        tpos = poss[*,ii]
        label = label_letters[ii]+'. '+plot_labels[ii]
        tx = xchsz*2
        ty = tpos[3]-ychsz*0.8
        xyouts, tx,ty,/normal, label
    endfor

    tpos = poss[*,0]
    tx = tpos[0]
    ty = tpos[3]+ychsz*0.5
    msg = 'RBSP-'+strupcase(probe)+' spacecraft GSM V'+component+' (Re). '+$
        'Comparison between R interpolated to 1/16 sec from 1 min, and R at 1/16 sec from SPICE'
    xyouts, tx,ty,/normal, msg

    if keyword_set(test) then stop
    sgclose

end


;---Input.
date = time_double('2013-07-19')
probe = 'a'
ndim = 3
for ii=0,ndim-1 do check_hires_r_gsm, date, probe=probe, component_index=ii
end
