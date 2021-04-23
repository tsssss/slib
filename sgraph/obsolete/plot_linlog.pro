;+
; Plot scalar or vector in linear-log yscale.
;-

pro plot_linlog, var, ypans=ypans, positive=positive, negative=negative, $
    xstyle=xstyle, xlog=xlog, xrange=xrange, xticks=xticks, xtickv=xtickv, xminor=xminor, xticklen=xticklen, xtickformat=xtickformat, xtickname=xtickn, xtitle=xtitle, $
    ystyle=ystyle, ylog=ylog, yrange=yrange, yticks=yticks, ytickv=ytickv, yminor=yminor, yticklen=yticklen, ytickformat=ytickformat, ytickname=ytickn, ytitle=ytitle, $
    log_ystyle=log_ystyle, log_yticks=log_yticks, log_yrange=log_yrange, log_ytickv=log_ytickv, log_yminor=log_yminor, log_ytickformat=log_ytickformat, log_ytickname=log_ytickn, $
    position=tpos

;---Default settings.
    if n_elements(var) eq 0 then begin
        xxs = [0.,1]
        yys = [0.,1]
    endif else if tnames(var) eq '' then begin
        xxs = [0.,1]
        yys = [0.,1]
    endif else begin
        if n_elements(xrange) eq 0 then begin
            yys = get_var_data(var, times=xxs, limits=lim)
        endif else begin
            yys = get_var_data(vars, times=xxs, in=xrange, limits=lim)
        endelse
    endelse

    xticklen_chsz = -0.15
    yticklen_chsz = -0.30
    xchsz = double(!d.x_ch_size)/!d.x_size
    ychsz = double(!d.y_ch_size)/!d.y_size
    if n_elements(tpos) eq 0 then tpos = sgcalcpos(1)
    if n_elements(ypans) eq 0 then begin
        if keyword_set(positive) then ypans = [1.,1] else $
        if keyword_set(negative) then ypans = [1.,1] else $
        ypans = [1.,2,1]
    endif
    if n_elements(xstyle) eq 0 then xstyle = 1
    if n_elements(xlog) eq 0 then xlog = 0
    if n_elements(xticklen) eq 0 then xticklen = xticklen_chsz*ychsz/(tpos[3]-tpos[1])
    if n_elements(xrange) eq 0 then xrange = minmax(xxs)
    if n_elements(ystyle) eq 0 then ystyle = 1
    if n_elements(ylog) eq 0 then ylog = 0
    if n_elements(yticklen) eq 0 then yticklen = yticklen_chsz*xchsz/(tpos[2]-tpos[0])
    if n_elements(yrange) eq 0 then yrange = minmax(yys)
