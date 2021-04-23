;+
; Calculate figure xysize, region pos in norm, panel pos in norm.
;-

function fig_pos_calc_size, fig, region_geometry

    if n_elements(region_geometry) eq 0 then region_geometry = fig.region_geometry

    xsizes = list()
    ysizes = list()
    foreach node, (*region_geometry) do begin
        type = size(node,/type)
        if type eq 7 then continue
        if type eq 10 then begin
            size = fig_pos_calc_size(fig, node)
            xsizes.add, size[0]
            ysizes.add, size[1]
        endif else begin
            xsizes.add, (fig.regions[node-1]).xsize
            ysizes.add, (fig.regions[node-1]).ysize
        endelse
    endforeach
    xsizes = xsizes.toarray()
    ysizes = ysizes.toarray()

    direction = (*region_geometry)[0]
    if direction eq 'row' then begin
        xsize = xsizes[0]
        ysize = total(ysizes)
        index = where(xsizes-xsize ne 0, count)
        if count ne 0 then message, 'Inconsistent region xsize ...'
    endif else begin
        xsize = total(xsizes)
        ysize = ysizes[0]
        index = where(ysizes-ysize ne 0, count)
        if count ne 0 then message, 'Inconsistent region ysize ...'
    endelse

    return, [xsize,ysize]
end

pro fig_pos_calc_region_pos, fig, region_geometry, pos=pos
    
    if n_elements(region_geometry) eq 0 then region_geometry = fig.region_geometry
    if n_elements(pos) eq 0 then pos = [0d,0,1,1]
    xsize = pos[2]-pos[0]
    ysize = pos[3]-pos[1]
    xoffset = pos[0]
    yoffset = pos[1]
    
    xsizes = list()
    ysizes = list()
    foreach node, (*region_geometry) do begin
        type = size(node,/type)
        if type eq 7 then continue
        if type eq 10 then begin
            size = fig_pos_calc_size(fig, node)
            xsizes.add, size[0]
            ysizes.add, size[1]
        endif else begin
            xsizes.add, (fig.regions[node-1]).xsize
            ysizes.add, (fig.regions[node-1]).ysize
        endelse
    endforeach
    xsizes = xsizes.toarray()
    ysizes = ysizes.toarray()
    
    direction = (*region_geometry)[0]
    if direction eq 'row' then begin
        region = region_init(fig, ypans=ysizes, xsize=xsize, ysize=ysize, margins=[0,0,0,0], xpads=0, ypads=0)
    endif else begin
        region = region_init(fig, xpans=xsizes, xsize=xsize, ysize=ysize, margins=[0,0,0,0], xpads=0, ypads=0)
    endelse
    norm_pos = reform(region.abs_pos)
    norm_pos[[0,2],*] += xoffset
    norm_pos[[1,3],*] += yoffset
    foreach node, (*region_geometry), node_id do begin
        pos = norm_pos[*,node_id-1]
        type = size(node,/type)
        if type eq 7 then continue
        if type ne 10 then begin
            (fig.regions)[node-1].pos = pos
            pan_pos = (fig.regions)[node-1].abs_pos
            pan_pos[[0,2],*,*] = (pan_pos[[0,2],*,*]/(fig.regions)[node-1].xsize)*(pos[2]-pos[0])+pos[0]
            pan_pos[[1,3],*,*] = (pan_pos[[1,3],*,*]/(fig.regions)[node-1].ysize)*(pos[3]-pos[1])+pos[1]
            (fig.regions)[node-1].pan_pos = reform(pan_pos)
        endif else begin
            fig_pos_calc_region_pos, fig, node, pos=pos
        endelse
    endforeach

end

function fig_pos, fig

    ; Figure size in inch.
    fig_size = fig_pos_calc_size(fig)
    fig.xsize = fig_size[0]
    fig.ysize = fig_size[1]
    
    ; Figure out the normalized position.
    fig_pos_calc_region_pos, fig
    
    
    sgopen, 0, xsize=fig.xsize, ysize=fig.ysize, inch=1
    foreach region, fig.regions do begin
        plot, [0,1],[0,1], $
            xstyle=1, ystyle=1, $
            xtickformat='(A1)', ytickformat='(A1)', $
            xticks=1, xminor=1, yticks=1, yminor=1, $
            position=region.pos, nodata=1, noerase=1
        pan_pos = region.pan_pos
        npan = n_elements(pan_pos)/4
        pan_pos = reform(pan_pos,[4,npan])
        for pan_id=0,npan-1 do begin
            plot, [0,1],[0,1], $
                xstyle=1, ystyle=1, $
                xtitle='X', ytitle='Y', $
                position=pan_pos[*,pan_id], nodata=1, noerase=1
        endfor
    endforeach
    
stop

end


fig = fig_init(0)
fig_replace_region, fig, region_init(fig, nypan=4, xsize=4, ysize=2.5)
fig_add_region, fig, region_init(fig, xsize=6, ysize=4), 'right', 1
fig_add_region, fig, region_init(fig, nxpan=3, xsize=4, ysize=1.5), 'below', 1
size = fig_pos_calc_size(fig)
pos = fig_pos(fig)
end
