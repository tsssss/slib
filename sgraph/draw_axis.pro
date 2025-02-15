
pro draw_axis, xrange=xrange, yrange=yrange, $
    xtitle=xtitle, ytitle=ytitle, position=my_pos, $
    xlog=xlog, ylog=ylog, $
    xstep=xstep, ystep=ystep, $
    noxtitle=noxtitle, noytitle=noytitle, $
    _extra=ex

    if n_elements(xrange) ne 2 then begin
        errmsg = 'Invalid xrange ...'
        return
    endif
    if n_elements(yrange) ne 2 then begin
        errmsg = 'Invalid yrange ...'
        return
    endif
    if n_elements(my_pos) ne 4 then begin
        errmsg = 'Invalid position ...'
        return
    endif

    if n_elements(xlog) eq 0 then xlog = 0
    if n_elements(ylog) eq 0 then ylog = 0
    if n_elements(xtitle) eq 0 then xtitle = ''
    if n_elements(ytitle) eq 0 then ytitle = ''
    if keyword_set(noxtitle) then my_xtitle = '' else my_xtitle = xtitle
    if keyword_set(noytitle) then my_ytitle = '' else my_ytitle = ytitle
    if keyword_set(noxtitle) then my_xtickformat = '(A1)' else my_xtickformat = ''
    if keyword_set(noytitle) then my_ytickformat = '(A1)' else my_ytickformat = ''


;---Do smart things for [xy]tickv, [xy]ticks, [xy]minor.
    if n_elements(xstep) eq 0 then begin
        xstep = abs(total(xrange*[-1,1]))/2
        xstep0 = 10d^floor(alog10(xstep))
        xstep = round(xstep/xstep0)*xstep0
    endif    
    if n_elements(xtickv) eq 0 then xtickv = make_bins(xrange, xstep, inner=1)
    if xlog eq 1 then begin
        log_xrange = alog10(xrange)
        log_xtickv = make_bins(log_xrange, 1, inner=1)
        xtickv = 10d^log_xtickv
        xminor = 9
    endif else begin
        if n_elements(xminor) eq 0 then begin
            xminor = xstep/10^floor(alog10(xstep))
            if xminor eq 1 then xminor = 4
        endif
    endelse
    xticks = n_elements(xtickv)-1

    if n_elements(ystep) eq 0 then begin
        ystep = abs(total(yrange*[-1,1]))/2
        ystep0 = 10d^floor(alog10(ystep))
        ystep = round(ystep/ystep0)*ystep0
    endif    
    if n_elements(ytickv) eq 0 then ytickv = make_bins(yrange, ystep, inner=1)
    if ylog eq 1 then begin
        log_yrange = alog10(yrange)
        log_ytickv = make_bins(log_yrange, 1, inner=1)
        ytickv = 10d^log_ytickv
        yminor = 9
    endif else begin
        if n_elements(yminor) eq 0 then begin
            yminor = ystep/10^floor(alog10(ystep))
            if yminor eq 1 then yminor = 4
        endif
    endelse
    yticks = n_elements(ytickv)-1


    fig_size = [!d.x_size,!d.y_size]
    chsz = get_charsize()
    xchsz = chsz[0]
    ychsz = chsz[1]
    abs_ticklen = -0.3*ychsz*fig_size[1]
    abs_xticklen = abs_ticklen
    abs_yticklen = abs_ticklen
    xticklen = abs_xticklen/(my_pos[3]-my_pos[1])/fig_size[1]
    yticklen = abs_yticklen/(my_pos[2]-my_pos[0])/fig_size[0]

    plot, xrange, yrange, $
        nodata=1, noerase=1, position=my_pos, $
        xstyle=1, xlog=xlog, xrange=xrange, xtitle=my_xtitle, $
        xtickv=xtickv, xminor=xminor, xticks=xticks, xticklen=xticklen, $
        ystyle=1, ylog=ylog, yrange=yrange, ytitle=my_ytitle, $
        ytickv=ytickv, yminor=yminor, yticks=yticks, yticklen=yticklen, $
        xtickformat=my_xtickformat, ytickformat=my_ytickformat
    
    return

end