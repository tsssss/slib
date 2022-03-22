;+
; Init position in inch for a certain grid of panels.
; This program builds a region from panels.
;
; pansize=. [xsize,ysize]. In inch.
; panid=. [xid,yid]. [0,0] by default.
;
; nxpan=. # of columns. 1 by default.
; xpads=. Similar to xpad, but in [nxpan-1].
; xpans=. The size ratio in x, in [nxpan].
; nypan=. # of rows. 1 by default.
; ypads=. Similar to ypad, but in [nypan-1].
; ypans=. The size ratio in y, in [nypan].
;
; margins=. [4], [l,b,r,t], lr in xcharsize, bt in ycharsize.
;-

function panel_init, plot_file, $
    pansize=pansize, panid=panid, $
    xpads=xpads, nxpan=nxpan, xpans=xpans, $
    ypads=ypads, nypan=nypan, ypans=ypans, $
    margins=margins


    if n_elements(plot_file) eq 0 then plot_file = 0
    fig = fig_info(plot_file)

;---xpanel: xpans, xpads, nxpan.
    if n_elements(nxpan) eq 0 then nxpan = 1
    if nxpan lt 0 then nxpan = 1
    if n_elements(xpans) eq 0 then begin
        xpans = dblarr(nxpan)+1
    endif else begin
        nxpan = n_elements(xpans)
    endelse
    xpad = 8d
    if n_elements(xpads) eq 0 then xpads = xpad
    if n_elements(xpads) eq 1 then xpad = xpads[0]
    if nxpan eq 1 then xpads = !null
    if n_elements(xpads) ne nxpan-1 then begin
        xpads = dblarr(nxpan-1)+xpad
    endif
    if nxpan eq 1 then xpads = !null

;---ypanel: ypans, ypads, nypan.
    if n_elements(nypan) eq 0 then nypan = 1
    if nypan le 0 then nypan = 1
    if n_elements(ypans) eq 0 then begin
        ypans = dblarr(nypan)+1
    endif else begin
        nypan = n_elements(ypans)
    endelse
    ypad = 0.4d
    if n_elements(ypads) eq 0 then ypads = ypad
    if n_elements(ypads) eq 1 then ypad = ypads[0]
    if nypan eq 1 then ypads = !null
    if n_elements(ypads) ne nypan-1 then begin
        ypads = dblarr(nypan-1)+ypad
    endif
    if nypan eq 1 then ypads = !null

;---margins.
    if n_elements(margins) ne 4 then begin
        margins = [8d,4,4,1]
    endif


;---panel sizes.
    if n_elements(pansize) ne 2 then begin
        pansize = [2d,0.5]
    endif
    if n_elements(panid) ne 2 then begin
        panid = [0,0]
    endif

    xpansize = pansize[0]*xpans/xpans[panid[0]]
    ypansize = pansize[1]*ypans/ypans[panid[1]]

;---figure size.
    abs_xchsz = fig.xchsz
    abs_ychsz = fig.ychsz
    abs_xspace = [margins[0],xpads,margins[2]]*abs_xchsz
    abs_yspace = [margins[3],ypads,margins[1]]*abs_ychsz
    region_xsize = total(xpansize)+total(abs_xspace)
    region_ysize = total(ypansize)+total(abs_yspace)


;---panel positions.
    abs_pos = dblarr(4,nxpan,nypan)
    for ypan_id=0,nypan-1 do begin
        if ypan_id eq 0 then y0 = region_ysize else y0 = abs_pos[1,0,ypan_id-1]
        for xpan_id=0,nxpan-1 do begin
            if xpan_id eq 0 then x0 = 0 else x0 = abs_pos[2,xpan_id-1,0]
            abs_pos[0,xpan_id,ypan_id] = x0+abs_xspace[xpan_id]
            abs_pos[3,xpan_id,ypan_id] = y0-abs_yspace[ypan_id]
            abs_pos[2,xpan_id,ypan_id] = abs_pos[0,xpan_id,ypan_id]+xpansize[xpan_id]
            abs_pos[1,xpan_id,ypan_id] = abs_pos[3,xpan_id,ypan_id]-ypansize[ypan_id]
        endfor
    endfor



;---Cleanup.
    panels = dictionary($
        ; essential info.
        'xspace', abs_xspace, $ ; [nxpan+1].
        'yspace', abs_yspace, $ ; [nypan+1].
        'xpansize', xpansize, $ ; [nxpan].
        'ypansize', ypansize, $ ; [nypan].
        'abs_pos', abs_pos, $   ; positions of panels in inch.
        'xsize', region_xsize, $
        'ysize', region_ysize, $
        'placeholder', 0 )

    return, panels

end

plot_file = homedir()+'/test.pdf'
fig = fig_init(plot_file)

ypans = [1,2]
nxpan = 3
panels = region_init(fig, nxpan=nxpan, ypans=ypans)
sgopen, fig.id, xsize=panels.xsize, ysize=panels.ysize
poss = panels.pos
foreach ypan, ypans, id do begin
    for ii=0,nxpan-1 do $
    plot, [0,1],[0,1], $
        nodata=1, noerase=1, $
        position=poss[*,ii,id]
endforeach

end
