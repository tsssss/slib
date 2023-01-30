;+
; Plot 2d pitch angle distribution.
;
; Adopted from sgdistr2d.pro
;
; fluxs, in [nangle,nenergy]
; angles, in [nangle,nenergy]
; energys, in [nangle,nenergy]
;-

function plot_pa_contour2d, fluxs, angles, energys, circles=circles, $
    position=tpos, no_axis=no_axis, axis_title=axis_title, $
    xrange=xrange, xticks=xticks, xtickv=xtickv, xminor=xminor, $
    color_table=color_table, cbpos=cbpos, no_colorbar=no_colorbar, ncolor=ncolor, $
    is_velocity=is_velocity, title=title, ztitle=ztitle, $
    zrange=zrange, zticks=zticks, ztickv=ztickv, zminor=zminor, zticklen=zticklen, $
    _extra=ex



    ; constants.
    xchsz = double(!d.x_ch_size)/!d.x_size
    ychsz = double(!d.y_ch_size)/!d.y_size
    black = sgcolor('black')

    if n_elements(tpos) eq 0 then tpos = sgcalcpos(margins=[4,10,5,3])
    if n_elements(title) eq 0 then title = ''
    if n_elements(ztitle) eq 0 then ztitle = 'Log!D10!N flux (#/s-cm!E2!N-sr-eV)'
    if n_elements(ncolor) eq 0 then ncolor = 15

    if n_elements(zrange) eq 0 then begin
        log_zrange = minmax(alog10(fluxs))
        log_zrange = [ceil(log_zrange[0]),floor(log_zrange[1])]
        zrange = 10^log_zrange
    endif else begin
        log_zrange = alog10(zrange)
    endelse
    log_ztickv = make_bins(log_zrange,1,inner=1)
    if n_elements(ztickv) eq 0 then ztickv = 10^log_ztickv
    if n_elements(zticks) eq 0 then zticks = n_elements(ztickv)-1
    if n_elements(zminor) eq 0 then zminor = 10

    if n_elements(cbpos) eq 0 then begin
        cbpos = tpos
        cbpos[0] = cbpos[2]+xchsz
        cbpos[2] = cbpos[0]+xchsz
    endif

    abs_ticklen = ychsz*0.15
    ticklen = -abs_ticklen/(tpos[3]-tpos[1])
    xticklen = ticklen
    yticklen = ticklen
    zticklen = ticklen*(tpos[2]-tpos[0])/(cbpos[2]-cbpos[0])

    ; Colors.
    color_top = 250
    color_bottom = 10
    if n_elements(color_table) eq 0 then color_table = 40
    index_colors = floor(smkarthm(color_bottom,color_top,ncolor,'n'))
    colors = index_colors
    for ii=0,ncolor-1 do colors[ii] = sgcolor(index_colors[ii],ct=color_table)
    log_c_levels = smkarthm(log_zrange[0],log_zrange[1],ncolor,'n')
    c_levels = 10.^log_c_levels

    ; plot color bar.
    label_size = 0.8
    zlog = 1
    if ~keyword_set(no_colorbar) then begin
        sgcolorbar, index_colors, position=cbpos, ct=color_table, $
            zrange=zrange, ztitle=ztitle, zcharsize=label_size, log=zlog, $
            ztickv=ztickv, zticks=zticks, zminor=zminor, zticklen=zticklen, $
            _extra=ex
    endif


    ; plot the contour.
    if n_elements(axis_title) eq 0 then axis_title = keyword_set(is_velocity)? 'V (km/s)': 'E (eV)'
    xtitle = 'Para '+axis_title
    ytitle = 'Perp '+axis_title

    if n_elements(xrange) ne 2 then xrange = [-1,1]*max(energys,nan=1)
    yrange = xrange



    polar_contour, fluxs, angles, energys, noerase=1, $
        position=tpos, fill=1, iso=1, $
        nlevel=nztick, levels=c_levels, c_colors=colors, $
        xtitle=xtitle, xstyle=1, xrange=xrange, $
        ytitle=ytitle, ystyle=1, yrange=yrange, $
        xticklen=xticklen, yticklen=yticklen, $
        _extra=ex

    tx = (tpos[0]+tpos[2])*0.5
    ty = tpos[3]+ychsz*0.5
    xyouts, tx,ty, title, normal=1, color=black, alignment=0.5

    ; Add lines at every 45 deg.
    tts = smkarthm(45,360,45,'dx')*constant('rad')
    dis = [0,xrange[1]]*2
    foreach tmp, tts do begin
        oplot, dis*cos(tmp), dis*sin(tmp), color=black, linestyle=2
    endforeach
    
    ; Add circles.
    tmp = findgen(101)*2*!dpi/100
    txs = cos(tmp)
    tys = sin(tmp)
    if n_elements(circles) eq 0 then begin
        circles = xtickv
    endif
    ncircle = n_elements(circles)
    for ii=0, ncircle-1 do begin
        plots, txs*circles[ii], tys*circles[ii], linestyle=2, color=black
    endfor
    

end