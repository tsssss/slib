;+
; Plot as image.
;-

pro plot_cwt2, cwt_info, position=pos, colorbar_position=cbpos, ct=ct, $
    xtitle=xtitle, xrange=xrange, xlog=xlog, xticks=xticks, xminor=xminor, xtickv=xtickv, $
    ytitle=ytitle, yrange=yrange, ylog=ylog, $
    ztitle=ztitle, zrange=zrange, zlog=zlog, zticks=zticks, $
    horizontal=horizontal, $
    _extra=ex

    if n_elements(cwt_info) eq 0 then return
    if n_elements(pos) ne 4 then pos = sgcalcpos(1,xchsz=xchsz,ychsz=ychsz)

    dt = cwt_info.dt
    N = cwt_info.N
    sigma2 = cwt_info.sigma2
    s0 = cwt_info.s0
    sJ = cwt_info.sJ
    s2t = cwt_info.s2t

    zz = abs(cwt_info.w_nj)^2
    xx = dt*findgen(N)
    yy = 1d/(cwt_info.s_j*s2t)

    yticklen = -0.005
    if n_elements(yrange) ne 2 then yrange = minmax(1d/([s0,sJ]*s2t))
    if n_elements(ylog) eq 0 then ylog = 1
    if n_elements(ytitle) ne 1 then ytitle='Freq (Hz)'

    xrange = minmax(xx)
    xticklen = -0.02
    xlog = 0
    if n_elements(xtitle) ne 1 then xtitle='Time (sec)'

    if n_elements(zrange) ne 2 then begin
        z0 = alog10(min(zz))
        z1 = alog10(max(zz))
        if z0 lt z1-2 then begin
            z0 = double(ceil(z0))
            z1 = double(floor(z1))
        endif
        zrange = [z0,z1]
    endif
    nlevel = zrange[1]-zrange[0]+1
    if n_elements(zticks) ne 0 then nlevel = zticks+1
    if n_elements(zlog) eq 0 then zlog = 1
    levels = smkarthm(zrange[0],zrange[1],nlevel, 'n')
    if zlog then levels = 10d^levels

    raw_colors = round(smkarthm(10,240,nlevel, 'n'))
    colors = fltarr(nlevel)
    for ii=0, nlevel-1 do colors[ii] = sgcolor(raw_colors[ii], ct=ct)

    contour, zz, xx, yy, /noerase, /fill, position=pos, $
        xstyle=1, xlog=xlog, xrange=xrange, xticklen=xticklen, xtitle=xtitle, $
        xticks=xticks, xtickv=xtickv, xminor=xminor, $
        ystyle=1, ylog=ylog, yrange=yrange, yticklen=yticklen, ytitle=ytitle, $
        levels=levels, c_colors=colors, _extra=ex

    if n_elements(xchsz) eq 0 then xchsz = double(!d.x_ch_size)/!d.x_size
    if n_elements(ychsz) eq 0 then ychsz = double(!d.y_ch_size)/!d.y_size
    if n_elements(cbpos) ne 4 then begin
        if keyword_set(horizontal) then begin
            cbpos = pos[[0,3,2,3]]+[0,0.5,0,1]*ychsz
        endif else begin
            cbpos = pos[[2,1,2,3]]+[1,0,2,0]*xchsz
        endelse
    endif
    sgcolorbar, raw_colors, ct=ct, zrange=zrange, position=cbpos, horizontal=horizontal, ztitle=ztitle
end
