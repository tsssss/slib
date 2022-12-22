;+
; Type: Procedure.
; Purpose: Plot 2d pitch angle distribution from flux, angle and energy/vel.
; Parameters:
;   tdat, in, dblarr[m,n], req. The measured flux.
;   angs, in, dblarr[m,n], req. The pitch angle, in rad.
;   vels, in, dblarr[m,n], req. The "radius', velocity or energy.
; Keywords:
;   ncolor, in, int, opt. # of colors for contour.
;   position, in, dblarr[4], opt. Position in normalized coord for the plot.
;   zrange, in, dblarr[2], opt. The range for tdat.
;   no_cb=. Boolean set to suppress colorbar.
;   no_data_point=. Boolean, set to suppress data points.
;   no_axis=. Boolean, set to suppress axis.
; Return: none.
; Notes: Angles and distances have to be in the same dimension. Angles at
;   certain distance should not be the same, otherwise you get error in
;   TRIANGULATE. In reality, the angles should be different b/c the detector
;   is rotating as sweeping energies.
; Dependence: slib.
; History:
;   2017-06-07, Sheng Tian, documented.
;-

pro sgdistr2d, tdat, angs, vels, ncolor = nztk, $
    position = tpos, zrange = zrng, title = titl, xtitle = xttl0, $
    no_cb=no_cb, cbpos=cbpos, no_data_point=no_data_point, no_axis=no_axis, _extra=ex

    ; dat in [nang,nvel], number flux.
    ; ang in [nang,nvel], in radian.
    ; vel in [nang,nvel], in km/s.

    black = sgcolor('black')

    ; constants.
    emsz = double(!d.x_ch_size)/!d.x_size
    exsz = double(!d.y_ch_size)/!d.y_size
    blck = 0

    if n_elements(tpos) eq 0 then tpos = [0.15,0.15,0.85,0.85]
    if n_elements(titl) eq 0 then titl = ''

    zttl = 'Log Eflux (s!E-1!Ncm!E-2!Nsr!E-1!NeV!E-1!N)'
    if n_elements(zrng) eq 0 then zrng = sg_autolim(alog10(tdat))
    if n_elements(nztk) eq 0 then nztk = 15
    ztks = 10^smkarthm(zrng[0],zrng[1],nztk,'n')
    zcls = floor(smkarthm(10,250,nztk,'n'))

    if n_elements(xttl0) eq 0 then xttl0 = 'V (km/s)'
    if n_elements(xttl) eq 0 then xttl = 'Para '+xttl0
    xrng = [-1,1]*max(vels,/nan)

    if n_elements(yttl) eq 0 then yttl = 'Perp '+xttl0
    yrng = xrng

    ; plot the contour.
    pos1 = tpos
    polar_contour, tdat, angs, vels, /noerase, $
        position = pos1, /fill, $
        nlevel = nztk, levels = ztks, c_colors = zcls, $
        xtitle = xttl, xstyle=5, xrange = xrng, $
        ytitle = yttl, ystyle=5, yrange = yrng, $
        _extra = extr

    ; plot data points.
    ticklen = -0.01
    plot, xrng, yrng, position = pos1, /noerase, /nodata, $
        xstyle = 1, xrange = xrng, xtitle=xttl, $
        ystyle = 1, yrange = yrng, ytitle=yttl, color=blck, $
        xticklen=ticklen, yticklen=ticklen

    tx = (tpos[0]+tpos[2])*0.5
    ty = tpos[3]+0.05
    xyouts, tx,ty, titl, normal=1, color=blck, alignment=0.5

    if ~keyword_set(no_data_point) then begin
        tmp = findgen(11)*2*!dpi/10
        txs = cos(tmp)
        tys = sin(tmp)
        for i = 0, n_elements(tdat)-1 do begin
            tmp = where(ztks le tdat[i], cnt)
            idx = tmp[cnt-1]
            usersym, txs, tys, color = blck
            plots, vels[i]*cos(angs[i]), vels[i]*sin(angs[i]), /data, psym = 8, symsize = 0.3
            usersym, txs, tys, color = zcls[idx], /fill
            plots, vels[i]*cos(angs[i]), vels[i]*sin(angs[i]), /data, psym = 8, symsize = 0.3
        endfor
    endif else begin
        plots, xrng, [0,0], linestyle=2, color=black
        plots, [0,0], yrng, linestyle=2, color=black
    endelse

    
    tmp = findgen(101)*2*!dpi/100
    txs = cos(tmp)
    tys = sin(tmp)
    ncirc = 5
    circs = smkarthm(0,max(xrng),ncirc,'n')
    for i = 0, ncirc-1 do oplot, txs*circs[i], tys*circs[i], color = black, linestyle = 2

    ; plot color bar.
    if ~keyword_set(no_cb) then begin
        sgtruecolor
        pos2 = tpos
        pos2[0] = pos2[2]+emsz & pos2[2] = pos2[0]+emsz
        if keyword_set(cbpos) then pos2 = cbpos
        sgcolorbar, reverse(zcls), position = pos2, $
            zrange = zrng, ztitle = zttl, zcharsize = 0.8, _extra=ex
    endif
    

end
