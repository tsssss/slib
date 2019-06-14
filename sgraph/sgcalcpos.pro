;+
; Type: function.
; Purpose: Calculate panel positions in normal coordinate.
; Parameters:
;   nypanel, in, int, opt. # of panels in y direction. Default is 1.
; Keywords:
;   ypad, in, int, opt. Space b/w y-panels, in # of ycharsize. Default is 0.4.
;   position, in, dlbarr[4], opt. In normal coord, set the area for panels.
;   region, in, dblarr[4], opt. In normal coord, set area including margins.
;   lmargin, in, int, opt. # of xcharsize, left margin. Default is 10.
;   rmargin, in, int, opt. # of xcharsize, right margin. Default is 10.
;   tmargin, in, int, opt. # of ycharsize, top margin. Default is 4.
;   bmargin, in, int, opt. # of bcharsize, bottom margin. Default is 4.
;   margins, in, int/intarr[2]/intarr[4], opt. # of charsize.
;       intarr[4]:[l,b,r,t](in position sense), inarr[2]:[lr,tb], int:[lrtb].
;   lpad, in, int, opt. Line skip in # of ycharsize. Default is 0.1.
; Return:
;   dblarr[4,n]. The position of panels.
; Notes: In this code, "region" is the area contains margins and plotting area,
;   "positon" is the plotting area that excludes margins, it is also exactly
;   the boundary the y-panels.
;       Effectively, the difference between region and position is the margins,
;   but region and position are in normal coordinate, margins are in charsize,
;   i.e., we provide 2 ways to set margin. [lrtb]margin overwrite margins,
;   position overwrites [lrtb]margin.
;       Our panels stack in y-direction, so there is no nxpanel, xpad, etc.
; Dependence: none.
; History:
;   2014-04-08, Sheng Tian, create.
;   
; [xy]chsz. Output. The size of a nominal character in the normalized coordinate.
;-
function sgcalcpos, nypanel, nxpanel, ypad=ypad0, xpad=xpad0, $
    position=pos0, region=region, margins=margins, $
    lmargin=lmg0, rmargin=rmg0, bmargin=bmg0, tmargin=tmg0, $
    xpans=xpans, ypans=ypans, $
    xchsz=xchsz, ychsz=ychsz

    ; x- and y-charsize in normal coord.
    xchsz = double(!d.x_ch_size)/double(!d.x_size)
    ychsz = double(!d.y_ch_size)/double(!d.y_size)

    ; # of x- and y-panels.
    nxpan = (n_elements(nxpanel) eq 0)? 1: nxpanel
    nypan = (n_elements(nypanel) eq 0)? 1: nypanel

    ; The ratio of the panels.
    if n_elements(xpans) ne nxpan then xpans = dblarr(nxpan)+1
    if n_elements(ypans) ne nypan then ypans = dblarr(nypan)+1

    ; x- and y-panel skip, line skip in ycharsize.
    ypad = (n_elements(ypad0) eq 0)? 0.4: ypad0
    xpad = (n_elements(xpad0) eq 0)? 4: xpad0   ; b/c title is vertical.


    ; margins in the unit of charsize, mgs in [l,r,t,b].
    default_margins = [10,5,5,5]
    case n_elements(margins) of
        ; no settings.
        0: mgs = default_margins
        ; [lrtb].
        1: mgs = replicate(margins,4)
        ; [lr],[tb].
        2: mgs = [replicate(margins[0],2),replicate(margins[1],2)]
        ; [l,b,r,t], same as position and region.
        4: mgs = [margins[0],margins[2],margins[3],margins[1]]
        else: mgs = default_margins
    endcase
    ; overwrite specific margin, still in the unit of charsize.
    lmg = (n_elements(lmg0) eq 0)? mgs[0]: lmg0
    rmg = (n_elements(rmg0) eq 0)? mgs[1]: rmg0
    tmg = (n_elements(tmg0) eq 0)? mgs[2]: tmg0
    bmg = (n_elements(bmg0) eq 0)? mgs[3]: bmg0

    ; convert margins and skips to normal coord.
    lmg *= xchsz
    rmg *= xchsz
    tmg *= ychsz
    bmg *= ychsz
    ypad *= ychsz
    xpad *= xchsz

;---Figure out the over-all position for the panels.
    if n_elements(region) eq 0 then region = [0d,0,1,1]
    if n_elements(region) ne 4 then region = [0d,0,1,1]
    x0 = region[0]
    y0 = region[1]
    x1 = region[2]
    y1 = region[3]

    if n_elements(pos0) eq 4 then begin
        lmg = pos0[0]-region[0]
        rmg = region[2]-pos0[2]
        bmg = pos0[1]-region[1]
        tmg = region[3]-pos0[3]
    endif

    ; Note: do not check [lbrt]margin, to keep the flexibility to do special things.
    pos_overall = [x0+lmg, y0+bmg, x1-rmg, y1-tmg]

    ; One panel.
    if nypan eq 1 and nxpan eq 1 then return, pos_overall

    ; Multiple panels.
    pos = dblarr(4,nxpan,nypan)

    ; calc inter panel size.
    xpads = (nxpan eq 1)? 0: dblarr(nxpan-1)+xpad    ; 0 for nxpad=1
    ypads = (nypan eq 1)? 0: dblarr(nypan-1)+ypad    ; 0 for nypad=1

    ; size of panel's [xy]size.
    xpan = (pos_overall[2]-pos_overall[0]-total(xpads))
    xsizes = xpan*double(xpans)/total(xpans)
    ypan = (pos_overall[3]-pos_overall[1]-total(ypads))
    ysizes = ypan*double(ypans)/total(ypans)

    ; Work out the position of each panel.
    ; The x-position of all rows. From left to right.
    pos[0,0,*] = pos_overall[0]
    for ii=0, nxpan-2 do begin
        pos[2,ii,*] = pos[0,ii,*]+xsizes[ii]
        pos[0,ii+1,*] = pos[2,ii,*]+xpads[ii]
    endfor
    pos[2,nxpan-1,*] = pos_overall[2]

    ; The y-position of all columns. From top to bottem.
    pos[3,*,0] = pos_overall[3]
    for ii=0, nypan-2 do begin
        pos[1,*,ii] = pos[3,*,ii]-ysizes[ii]
        pos[3,*,ii+1] = pos[1,*,ii]-ypads[ii]
    endfor
    pos[1,*,nypan-1] = pos_overall[1]

    return, reform(pos)
end
