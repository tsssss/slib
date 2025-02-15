;+
; vars.
; xrange=.
; filename=.
; pansize=.
; panel_labels=.
;-
function sgplot, vars, xrange=xrange, filename=plot_file, pansize=pansize, $
    errmsg=errmsg, panel_labels=panel_labels

    errmsg = errmsg
    retval = !null
    
    ; Check exisitng vars.
    nvar = n_elements(vars)
    if nvar eq 0 then begin
        errmsg = 'No input vars ...'
        return, retval
    endif
    
    var_flags = fltarr(nvar)
    foreach var, vars, vid do begin
        var_flags[vid] = check_if_var_exist(var)
    endforeach
    index = where(var_flags eq 1, nplot_var)
    if nplot_var eq 0 then begin
        errmsg = 'No valid var ...'
        return, retval
    endif
    plot_vars = vars[index] 
       
    if n_elements(xrange) eq 0 then xrange = minmax(get_var_time(plot_vars[0]))
    
    if n_elements(plot_file) eq 0 then plot_file = 0
    if n_elements(pansize) eq 0 then begin
        if nplot_var le 1 then begin
            pansize = [6,3]
        endif else if nplot_var le 4 then begin
            pansize = [6,1.5]
        endif else if nplot_var le 10 then begin
            pansize = [6,0.8]
        endif else begin
            pansize = [6,0.5]
        endelse
    endif
    
    fig_info = sg_prepare_fig_info(plot_vars, xrange=xrange, $
        plot_file=plot_file, pansize=pansize, panel_labels=panel_labels)
    sgopen, fig_info['file'], size=fig_info['size']
    foreach plot_var, fig_info.panel_info.keys() do begin
        my_info = (fig_info['panel_info'])[plot_var]
        plot_setting = my_info['plot_setting']
        plot_routine = my_info['routine']
        tmp = call_function(plot_routine, plot_var, _extra=plot_setting.tostruct())
    endforeach

    return, fig_info

end


tr = ['2015-09-01/00:00','2015-09-01/01:00']
foreach phys_quant, ['orbit','bfield'] do var = lets_read(phys_quant, tr, source=['mms','1'])
vars = 'mms1_'+['r_gsm','b_gsm']
;fig_info = sgplot(vars, xrange=tr, pansize=[6,2])
fig_info = sgplot(vars)
end