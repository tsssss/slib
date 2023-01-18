;+
; Type: Procedure.
; Purpose: Plot 2d pitch angle distribution from flux, angle and energy/vel.
;   This code fill in an annular sector, without any interpolation.
; Parameters:
;   tdat, in, dblarr[m,n], req. The measured flux.
;   angs, in, dblarr[m,n], req. The pitch angle, in rad.
;   vels, in, dblarr[m,n], req. The "radius', velocity or energy.
;   cangs, in, dblarr[m+1,n+1], req. The pitch angle at the corners of the
;       annular sector.
;   cdiss, in, dblarr[m+1,n+1], req. The radius at the corners.
; Keywords:
;   ncolor, in, int, opt. # of colors for contour.
;   position, in, dblarr[4], opt. Position in normalized coord for the plot.
;   zrange, in, dblarr[2], opt. The range for tdat.
; Return: none.
; Notes: Angles and distances have to be in the same dimension. Angles at
;   certain distance can be the same.  Though in reality, the angles should be
;   different b/c the detector is rotating as sweeping energies.
; Dependence: slib.
; History:
;   2017-06-07, Sheng Tian, documented.
;-

pro sgdistr2d_polygon, tdat, angs, diss, cangs, cdiss, ncolor = nztk, $
    position = tpos, zrange = zrng, title = titl, xtitle = xttl0, ct=ct

    ; dat in [nang,nvel], number flux.
    ; cang in [nang+1], in radian [0,pi].
    ; cdis in [nvel+1], in km/s.

    blck = sgcolor('black')
    if n_elements(ct) eq 0 then ct = 40

    ; constants.
    emsz = double(!d.x_ch_size)/!d.x_size
    exsz = double(!d.y_ch_size)/!d.y_size


    if n_elements(tpos) eq 0 then tpos = [0.15,0.15,0.85,0.85]
    if n_elements(titl) eq 0 then titl = ''

    zttl = 'Log Eflux (s!E-1!Ncm!E-2!Nsr!E-1!NeV!E-1!N)'
    if n_elements(zrng) eq 0 then zrng = sg_autolim(alog10(tdat))
    if n_elements(nztk) eq 0 then nztk = 20
    ztks = 10^smkarthm(zrng[0],zrng[1],nztk,'n')
    zcls = floor(smkarthm(10,250,nztk,'n'))

    if n_elements(xttl0) eq 0 then xttl0 = 'V (km/s)'
    xttl = 'Para '+xttl0
    xrng = [-1,1]*max(diss,/nan)

    yttl = 'Perp '+xttl0
    yrng = xrng

    ; setup coord.
    plot, xrng, yrng, position = tpos, /normal, /noerase, /nodata, $
        xstyle = 5, xrange = xrng, $
        ystyle = 5, yrange = yrng

    sz = size(tdat,/dimensions)
    nang = sz[0]
    ndis = sz[1]
    
    tmp = findgen(11)*2*!dpi/10
    txs = cos(tmp)
    tys = sin(tmp)
    
    for i = 0, ndis-1 do begin
        for j = 0, nang-1 do begin
            if tdat[j,i] eq 0 then continue
            
            tmp = where(ztks le tdat[j,i], cnt)
            if cnt eq 0 then idx = 0 else idx = tmp[cnt-1]
;            tc = sgcolor(zcls[idx],ct=ct,file='ct2')
            tc = sgcolor(zcls[idx],ct=ct)
            
            tcdis = cdiss[[i,i,i+1,i+1,j]]
            tcang = cangs[[j,j+1,j+1,j,j]]
            
            tx = tcdis*cos(tcang)
            ty = tcdis*sin(tcang)
            polyfill, tx, ty, /data, color = tc
                      
            tx = tcdis*cos(2*!dpi-tcang)
            ty = tcdis*sin(2*!dpi-tcang)
            polyfill, tx, ty, /data, color = tc            
            
            tx = diss[i]*cos(angs[j])
            ty = diss[i]*sin(angs[j])
            usersym, txs, tys, color = blck
            plots, tx, ty, /data, psym = 8, symsize = 0.3
            
            usersym, txs, tys, color = tc, /fill
            plots, tx, ty, /data, psym = 8, symsize = 0.3
            
            tx = diss[i]*cos(2*!dpi-angs[j])
            ty = diss[i]*sin(2*!dpi-angs[j])
            usersym, txs, tys, color = blck
            plots, tx, ty, /data, psym = 8, symsize = 0.3
            
            usersym, txs, tys, color = tc, /fill
            plots, tx, ty, /data, psym = 8, symsize = 0.3
        endfor
    endfor

    
    ; plot the box.
    ticklen = -0.01
    plot, xrng, yrng, position = tpos, /normal, /noerase, /nodata, $
        xstyle = 1, xrange = xrng, xtitle = xttl, $
        ystyle = 1, yrange = yrng, ytitle = yttl, color = blck, $
        xticklen=ticklen, yticklen=ticklen
        
    tx = (tpos[0]+tpos[2])*0.5
    ty = tpos[3]+0.05
    xyouts, tx,ty, titl, normal=1, color=blck, alignment=0.5

    
    tmp = findgen(101)*2*!dpi/100
    txs = cos(tmp)
    tys = sin(tmp)
    ncirc = 5
    circs = smkarthm(0,max(xrng),ncirc,'n')
    for i = 0, ncirc-1 do oplot, txs*circs[i], tys*circs[i], color = black, linestyle = 2

    ; plot color bar.
    pos2 = tpos
    pos2[0] = pos2[2]+emsz & pos2[2] = pos2[0]+emsz
;    rgb = sgcolor(findgen(255),ct=43,file='ct2',/triplet)
;    tvlct,rgb

    sgcolorbar, zcls, position=pos2, $
        zrange=zrng, ztitle=zttl, zcharsize=0.8, ct=ct

end
