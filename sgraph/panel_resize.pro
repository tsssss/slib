;+
; Resize panels to given xsize or ysize.
; Adopted from region_scale.
;-

pro panel_resize, panels, xsize=xsize, ysize=ysize

    if ~isa(panels,'dictionary') then return

    abs_pos = panels.abs_pos
    if n_elements(xsize) ne 0 then begin
        xpans = panels.xpansize
        abs_xspace = panels.xspace
        xpans = (xsize-total(abs_xspace))/total(xpans)*xpans
        nxpan = n_elements(xpans)
        for xpan_id=0,nxpan-1 do begin
            if xpan_id eq 0 then x0 = 0 else x0 = abs_pos[2,xpan_id-1,0]
            abs_pos[0,xpan_id,*] = x0+abs_xspace[xpan_id]
            abs_pos[2,xpan_id,*] = abs_pos[0,xpan_id,*]+xpans[xpan_id]
        endfor
        panels['xpansize'] = xpans
        panels['xsize'] = xsize
    endif

    if n_elements(ysize) ne 0 then begin
        ypans = panels.ypansize
        abs_yspace = panels.yspace
        ypans = (ysize-total(abs_yspace))/total(ypans)*ypans
        nypan = n_elements(ypans)
        for ypan_id=0,nypan-1 do begin
            if ypan_id eq 0 then y0 = ysize else y0 = abs_pos[1,0,ypan_id-1]
            abs_pos[3,*,ypan_id] = y0-abs_yspace[ypan_id]
            abs_pos[1,*,ypan_id] = abs_pos[3,*,ypan_id]-ypans[ypan_id]
        endfor
        panels['ypansize'] = ypans
        panels['ysize'] = ysize
    endif

    panels['abs_pos'] = abs_pos

end
