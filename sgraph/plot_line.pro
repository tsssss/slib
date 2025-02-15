;+
; Plot lines for vectors, scalars, etc.
;
; yrange=. [v1,v2]. The yrange.
;-

function plot_line, var, time_range=time_range, $
    yrange=yrange, tick_setting=tick_setting, plot_magnitude=plot_magnitude, $
    abs_ticklen=abs_ticklen, abs_xticklen=abs_xticklen, abs_yticklen=abs_yticklen, $
    panel_label_pos=panel_label_pos, panel_label_msg=panel_label_msg, $
    position=my_pos, noerase=noerase, novtitle=novtitle, xtickformat=xtickformat, $
    var_labels=var_labels, vlab_margin=vlab_margin, $
    errmsg=errmsg, _extra=ex

    retval = !null


;---Figure out positions.
    if n_elements(my_pos) ne 4 then begin
        my_pos = sgcalcpos(1)
    endif


;---Figure out ticklen and panel_label
    chsz = get_charsize()
    xchsz = chsz[0]
    ychsz = chsz[1]
    fig_size = double([!d.x_size,!d.y_size])
    if n_elements(abs_ticklen) eq 0 then abs_ticklen = -0.3*ychsz*fig_size[1]
    if n_elements(abs_xticklen) eq 0 then abs_xticklen = abs_ticklen
    if n_elements(abs_yticklen) eq 0 then abs_yticklen = abs_ticklen
    if n_elements(panel_label_msg) eq 0 then panel_label_msg = ' '
    if n_elements(panel_label_pos) eq 0 then panel_label_pos = [my_pos[0]-xchsz*9,my_pos[3]-ychsz*0.7]

;---More settings.
    ;orig_labels = get_var_setting(var, 'labels')
    orig_ytitle = get_var_setting(var, 'ytitle')
    if n_elements(noerase) eq 0 then noerase = 0
    if n_elements(xtickformat) eq 0 then xtickformat = ''
    if n_elements(novtitle) eq 0 then novtitle = 0
    if n_elements(var_labels) eq 0 then var_labels = ''
    if n_elements(vlab_margin) eq 0 then vlab_margin = 10


;---Linear part.
    my_var = var
    if keyword_set(plot_magnitude) then begin
        my_var = var+'_tmp'
        copy_data, var, my_var
        vec = get_var_data(my_var, times=times, in=time_range, settings=settings)
        dims = size(vec,dimensions=1)
        if n_elements(dims) eq 2 then begin
            ndim = dims[1]
            if ndim gt 1 then begin
                mag = snorm(vec)
                vec = [[vec],[mag]]
                colors = settings['colors']
                labels = settings['labels']
                short_name = settings['short_name']
                colors = [colors,sgcolor('black')]
                labels = [labels,'|'+short_name+'|']
                store_data, my_var, times, vec
                options, my_var, colors=colors, labels=labels
            endif
        endif
    endif

    tpos = my_pos
    xticklen = abs_xticklen/(tpos[3]-tpos[1])/fig_size[1]
    yticklen = abs_yticklen/(tpos[2]-tpos[0])/fig_size[0]
    xstyle = 1
    ytitle = orig_ytitle
    my_xtickformat = xtickformat
    my_novtitle = novtitle
    my_var_labels = var_labels
    my_noerase = noerase
    my_labels = get_var_setting(my_var, 'labels')
    options, my_var, yrange=yrange, ystyle=1, ytitle=ytitle, $
        xstyle=xstyle, xtickformat=my_xtickformat, labels=my_labels, ylog=0, $
        xticklen=xticklen, yticklen=yticklen
    if n_elements(tick_setting) ne 0 then begin
        foreach key, tick_setting.keys() do options, my_var, key, tick_setting[key]
    endif
    tplot, my_var, position=tpos, noerase=my_noerase, novtitle=my_novtitle, trange=time_range, $
        var_label=my_var_labels, vlab_margin=vlab_margin, _extra=ex
    if my_var ne var then del_data, my_var
    

;---Labels.
    tx = panel_label_pos[0]
    ty = panel_label_pos[1]
    msg = panel_label_msg
    xyouts, tx,ty,normal=1, msg

    return, my_pos

end