;+
; Check yearly files.
;-


pro check_prelim_spinfit_data, time_range, probe=probe

;---Settings.
    prefix = 'rbsp'+probe+'_'
    root_dir = '/Volumes/Research/data/rbsp/prelim_yearly_files/'
    years = sort_uniq(time_string(time_range,tformat='YYYY'))
    years = string(make_bins(fix(years),1,/inner),format='(I4)')
    base_names = 'rbsp'+probe+'_preliminary_e_spinfit_mgse_'+years+'_v01.cdf'
    files = root_dir+base_names

;---Load data.
    e12_var = prefix+'e_wake_spinfit_v12'
    if check_if_update(e12_var, time_range) then cdf2tplot, files


    pairs = 'v'+['12','34']
    e_vars = prefix+'e_wake_spinfit_'+pairs
    options, e_vars, 'colors', constant('rgb')
    options, e_vars, 'labels', 'E'+constant('xyz')
    options, e_vars, 'ytitle', '(mV/m)'
    options, e_vars, 'xticklen', -0.02
    options, e_vars, 'yticklen', -0.02

    plot_file = homedir()+'/'+prefix+'spinfit_e_mgse_'+$
        strjoin(time_string(time_range,tformat='YYYY_MMDD'),'_to_')+'.png'
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
    msg = 'RBSP-'+strupcase(probe)+' spinfit E MGSE'
    xyouts, tx,ty,/normal, msg

    sgclose


end




time_range = time_double(['2015-01-01','2019-06-01'])
foreach probe, ['a','b'] do check_prelim_spinfit_data, time_range, probe=probe
end