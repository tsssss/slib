;+
; Prepare panel info from given vars and xranges.
;
; vars. Input, strarr.
; label_vars=. Input, strarr.
; xrange=. Input
; panel_labels=. Input
; pansize=.
; ypans=.
; margins=.
; plot_file=.
;-

function sg_prepare_fig_info, vars, label_vars=label_vars, $
    xrange=xrange, panel_labels=panel_labels, $
    margins=margins, pansize=pansize, ypans=ypans, plot_file=plot_file, $
    errmsg=errmsg

    retval = !null
    errmsg = errmsg

    nvar = n_elements(vars)
    if nvar eq 0 then begin
        errmsg = 'No input vars ...'
        return, retval
    endif
    if n_elements(panel_labels) ne nvar then panel_labels = strarr(nvar)

    panel_info = orderedhash()
    foreach var, vars, vid do begin
        if ~check_if_var_exist(var) then continue
        var_type = get_var_setting(var, 'display_type', exist)
        if not exist then var_type = 'scalar'
        if var_type eq 'scalar' or var_type eq 'vector' then begin
            plot_routine = 'plot_line'
        endif else if var_type eq 'spec' then begin
            plot_routine = 'plot_spec'
        endif
        panel_info[var] = dictionary($
            'routine', plot_routine, $
            'ypan', 1.0, $
            'panel_label_text', panel_labels[vid], $
            'setting', dictionary($
                'placeholder', 0 ) )
    endforeach


;---Get panel label.
    plot_vars = panel_info.keys()
    nplot_var = n_elements(plot_vars)
    panel_letters = letters(nplot_var)
    foreach plot_var, plot_vars, vid do begin
        my_info = panel_info[plot_var]
        my_info['panel_letter'] = panel_letters[vid]
        my_info['panel_label_msg'] = my_info['panel_letter']+') '+my_info['panel_label_text']
    endforeach


;---Get position.
    if n_elements(label_vars) eq 0 then label_vars = 'time'
    nvar_label = n_elements(label_vars)
    if n_elements(margins) ne 4 then margins = [12,3.5+nvar_label,10,2]
    if n_elements(ypans) ne nplot_var then begin
        ypans = dblarr(nplot_var)
        foreach plot_var, plot_vars, vid do begin
            ypans[vid] = (panel_info[plot_var])['ypan']
        endforeach
    endif
    if n_elements(pansize) eq 0 then pansize = [10,0.8]
    if n_elements(plot_file) eq 0 then plot_file = 0
    plot_poss = panel_pos(plot_file, nypan=nplot_var, fig_size=fig_size, ypans=ypans, pansize=pansize, margins=margins)


;---Use positions to determine [x,y]ticklen.
    abs_ticklen = 0.3
    foreach plot_var, plot_vars, pid do begin
        my_info = panel_info[plot_var]
        my_info['position'] = plot_poss[*,pid]
        my_info['abs_ticklen'] = abs_ticklen
    endforeach

    tmp = get_abs_chsz()
    abs_xchsz = tmp[0]
    abs_ychsz = tmp[1]
    xchsz = abs_xchsz/fig_size[0]
    ychsz = abs_ychsz/fig_size[1]
    if n_elements(xrange) eq 0 then xrange = !null
    
    foreach plot_var, plot_vars, pid do begin
        my_info = panel_info[plot_var]
    
        my_pos = my_info['position']
        plot_routine = my_info['routine']
        plot_setting = my_info['setting']
        plot_setting['position'] = my_pos
        plot_setting['noerase'] = (pid eq 0)? 0: 1
        plot_setting['xtickformat'] = (pid eq nplot_var-1)? '': '(A1)'
        plot_setting['novtitle'] = (pid eq nplot_var-1)? 0: 1
        plot_setting['time_range'] = xrange
        plot_setting['tickinterval'] = tickinterval
        plot_setting['panel_label_pos'] = [xchsz*1,my_pos[3]-ychsz*0.7]
        plot_setting['panel_label_msg'] = my_info['panel_label_msg']
        plot_setting['var_labels'] = label_vars
        plot_setting['vlab_margin'] = margins[0]-1
        plot_setting['trange'] = xrange
        foreach key, plot_setting.keys() do begin
            index = strpos(key,'tick_setting')
            if index[0] ne -1 then begin
                tick_setting = plot_setting[key]
                foreach comp, constant('xyz') do begin
                    the_comp = comp+'tickv'
                    if tick_setting.haskey(the_comp) then begin
                        tick_setting[comp+'ticks'] = n_elements(tick_setting[the_comp])-1
                    endif
                endforeach
            endif
        endforeach

        my_info['plot_setting'] = plot_setting
    endforeach

    fig_info = dictionary($
        'file', plot_file, $
        'size', fig_size, $
        'xchsz', xchsz, $
        'ychsz', ychsz, $
        'abs_ticklen', abs_ticklen, $
        'margins', margins, $
        'plot_vars', plot_vars, $
        'label_vars', label_vars, $
        'panel_info', panel_info)

    return, fig_info

end


tr = ['2015-09-01/00:00','2015-09-01/01:00']
foreach phys_quant, ['orbit','bfield'] do var = lets_read(phys_quant, tr, source=['mms','1'])
vars = 'mms1_'+['r_gsm','b_gsm']

; tmp = sg_plot(vars)

fig_info = sg_prepare_fig_info(vars, xrange=tr)
sgopen, fig_info['file'], size=fig_info['size']
foreach plot_var, fig_info.panel_info.keys() do begin
    my_info = (fig_info['panel_info'])[plot_var]
    plot_setting = my_info['plot_setting']
    plot_routine = my_info['routine']
    tmp = call_function(plot_routine, plot_var, _extra=plot_setting.tostruct())
endforeach

end