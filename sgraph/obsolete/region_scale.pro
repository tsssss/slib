;+
; Scale a region with new xsize or ysize.
;-

pro region_scale, region, xsize=xsize, ysize=ysize

    if ~isa(region,'dictionary') then return

    abs_pos = region.abs_pos
    if n_elements(xsize) ne 0 then begin
        xpans = region.xpansize
        abs_xspace = region.xspace
        xpans = (xsize-total(abs_xspace))/total(xpans)*xpans
        nxpan = n_elements(xpans)
        for xpan_id=0,nxpan-1 do begin
            if xpan_id eq 0 then x0 = 0 else x0 = abs_pos[2,xpan_id-1,0]
            abs_pos[0,xpan_id,*] = x0+abs_xspace[xpan_id]
            abs_pos[2,xpan_id,*] = abs_pos[0,xpan_id,*]+xpans[xpan_id]
        endfor
        region['xpansize'] = xpans
        region['xsize'] = xsize
    endif

    if n_elements(ysize) ne 0 then begin
        ypans = region.ypansize
        abs_yspace = region.yspace
        ypans = (ysize-total(abs_yspace))/total(ypans)*ypans
        nypan = n_elements(ypans)
        for ypan_id=0,nypan-1 do begin
            if ypan_id eq 0 then y0 = ysize else y0 = abs_pos[1,0,ypan_id-1]
            abs_pos[3,*,ypan_id] = y0-abs_yspace[ypan_id]
            abs_pos[1,*,ypan_id] = abs_pos[3,*,ypan_id]-ypans[ypan_id]
        endfor
        region['ypansize'] = ypans
        region['ysize'] = ysize
    endif

    region['abs_pos'] = abs_pos

end

fig = fig_info(0)
ypans = [1,2]
nxpan = 3
region = build_region(fig, nxpan=nxpan, ypans=ypans)
sgopen, fig.id, xsize=region.xsize, ysize=region.ysize
poss = region.pos
foreach ypan, ypans, id do begin
    for ii=0,nxpan-1 do $
    plot, [0,1],[0,1], $
        nodata=1, noerase=1, $
        position=poss[*,ii,id]
endforeach

region_scale, region, ysize=6
poss = region.pos
sgopen, 1, xsize=region.xsize, ysize=region.ysize
foreach ypan, ypans, id do begin
    for ii=0,nxpan-1 do $
    plot, [0,1],[0,1], $
        nodata=1, noerase=1, $
        position=poss[*,ii,id]
endforeach
end
