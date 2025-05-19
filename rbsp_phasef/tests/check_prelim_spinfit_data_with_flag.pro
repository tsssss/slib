;+
; Check yearly files.
;-


pro check_prelim_spinfit_data_with_flag, time_range, probe=probe

test = 0
;---Settings.
    prefix = 'rbsp'+probe+'_'
    root_dir = '/Volumes/Research/data/rbsp/prelim_yearly_files/'
    years = sort_uniq(time_string(time_range,tformat='YYYY'))
    years = string(make_bins(fix(years),1,/inner),format='(I4)')
    base_names = 'rbsp'+probe+'_preliminary_e_spinfit_mgse_'+years+'_v01.cdf'
    files = root_dir+base_names

;---Load data.
    flag_var = prefix+'boom_flag'
    if check_if_update(flag_var, time_range) then begin
        rbsp_efw_read_boom_flag, time_range, probe=probe
        flags = get_var_data(flag_var, times=times)
        store_data, prefix+'flag_v12', times, total(flags[*,0:1],2) eq 2
        store_data, prefix+'flag_v34', times, total(flags[*,2:3],2) eq 2
    endif
    e12_var = prefix+'e_wake_spinfit_v12'
    if check_if_update(e12_var, time_range) then cdf2tplot, files
    dis_var = prefix+'dis'
    if check_if_update(dis_var, time_range) then begin
        rbsp_read_orbit, time_range, probe=probe
        dis = snorm(get_var_data(prefix+'r_gse', times=times))
        store_data, dis_var, times, dis
    endif


    fillval = !values.f_nan
    pairs = 'v'+['12','34']
    pad_time = 1800d    ; sec.
    foreach pair, pairs do begin
        e_var = prefix+'e_wake_spinfit_'+pair
        get_data, e_var, times, data, limits=lim
        flag_var = prefix+'flag_'+pair
        flags = get_var_data(flag_var, times=flag_times)
        index = where(flags eq 0, count)
        if count eq 0 then continue
        pad_nrec = pad_time/total(flag_times[0:1]*[-1,1])
        nan_index = time_to_range(index,time_step=1,pad_times=pad_nrec)
        nan_index = nan_index>0
        nan_index = nan_index<(n_elements(flag_times)-1)
        nnan_index = n_elements(nan_index)*0.5
        for ii=0,nnan_index-1 do begin
            diis = nan_index[ii,*]
            dii = total(diis*[-1,1])
            if dii le 0 then continue
            flags[diis[0]:diis[1]] = 0
        endfor
        flags = interp(flags, flag_times, times)
        index = where(flags eq 0)
        data[index,*] = fillval
        
        ; Remove perigee data.
        dis = get_var_data(dis_var, at=times)
        index = where(dis le 2, count)
        data[index,*] = fillval
        store_data, e_var+'_with_flag', times, data, limits=lim
    endforeach

    e_vars = prefix+'e_wake_spinfit_'+pairs+'_with_flag'
    options, e_vars, 'colors', constant('rgb')
    options, e_vars, 'labels', 'E'+constant('xyz')
    options, e_vars, 'ytitle', '(mV/m)'
    options, e_vars, 'xticklen', -0.02
    options, e_vars, 'yticklen', -0.02


    plot_file = homedir()+'/'+prefix+'spinfit_e_mgse_with_flag_'+$
        strjoin(time_string(time_range,tformat='YYYY_MMDD'),'_to_')+'.png'
    if keyword_set(test) then plot_file = 0
    sgopen, plot_file, xsize=10, ysize=5, /inch
    npanel = n_elements(e_vars)
    poss = sgcalcpos(npanel, xchsz=xchsz, ychsz=ychsz)
    panel_letters = letters(npanel)
    foreach e_var, e_vars, ii do begin
        tpos = poss[*,ii]
        add_xtick = (ii eq npanel-1)? 1: 0
        tplot_efield, e_var, trange=time_range, add_xtick=add_xtick, position=tpos
        msg = panel_letters[ii]+'. '+strupcase(pairs[ii])
        tx = xchsz*2
        ty = tpos[3]-ychsz*0.8
        xyouts, tx,ty, /normal, msg
    endforeach

    tpos = poss[*,0]
    tx = tpos[0]
    ty = tpos[3]+ychsz*0.5
    msg = 'RBSP-'+strupcase(probe)+' spinfit E MGSE with flag'
    xyouts, tx,ty,/normal, msg

    if keyword_set(test) then stop
    sgclose

end


time_range = time_double(['2015-01-01','2019-06-01'])
foreach probe, ['a','b'] do check_prelim_spinfit_data_with_flag, time_range, probe=probe
end