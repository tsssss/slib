;+
; Plot spec.
;-

function plot_spec, var, time_range=time_range, $
    abs_ticklen=abs_ticklen, abs_xticklen=abs_xticklen, abs_yticklen=abs_yticklen, abs_zticklen=abs_zticklen, $
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
    if n_elements(abs_zticklen) eq 0 then abs_zticklen = abs_ticklen
    if n_elements(panel_label_msg) eq 0 then panel_label_msg = ' '
    if n_elements(panel_label_pos) eq 0 then panel_label_pos = [my_pos[0]-xchsz*9,my_pos[3]-ychsz*0.7]

;---More settings.
    if n_elements(noerase) eq 0 then noerase = 0
    if n_elements(xtickformat) eq 0 then xtickformat = ''
    if n_elements(novtitle) eq 0 then novtitle = 0
    if n_elements(var_labels) eq 0 then var_labels = ''
    if n_elements(vlab_margin) eq 0 then vlab_margin = 10


;---Plot
    my_var = var

    tpos = my_pos
    xticklen = abs_xticklen/(tpos[3]-tpos[1])/fig_size[1]
    yticklen = abs_yticklen/(tpos[2]-tpos[0])/fig_size[0]
    if n_elements(cbpos) ne 4 then begin
        cbpos = tpos
        cbpos[0] = tpos[2]+xchsz*0.8
        cbpos[2] = cbpos[0]+xchsz*0.8
    endif
    zticklen = abs_zticklen/(cbpos[2]-cbpos[0])/fig_size[0]
    options, my_var, zposition=cbpos, zticklen=zticklen, xtickformat=xtickformat, $
        xcharsize=1, ycharsize=1, zcharsize=0.9, charsize=1, xticklen=xticklen, yticklen=yticklen

    tplot, my_var, position=tpos, noerase=noerase, novtitle=novtitle, trange=time_range, $
        var_label=var_labels, vlab_margin=vlab_margin


;---Labels.
    tx = panel_label_pos[0]
    ty = panel_label_pos[1]
    msg = panel_label_msg
    xyouts, tx,ty,normal=1, msg

    return, my_pos

end