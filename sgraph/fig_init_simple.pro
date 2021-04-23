;+
; Return normalized position for the panels.
;-

function fig_init_simple, id0, size=fig_size, _extra=ex

    fig = fig_init(fig)
    region = region_init(fig, _extra=ex)
    abs_pos = region.abs_pos
    
    norm_pos = abs_pos
    xsize = region.xsize
    ysize = region.ysize
    norm_pos[[0,2],*,*] /= xsize
    norm_pos[[1,3],*,*] /= ysize
    fig_size = [xsize,ysize]
    
    return, reform(norm_pos)
    
end


id = 0
ypans = [1,1,1,2,2,1]
margins = [8,5,6,1]
poss = fig_init_simple(id, size=fig_size, ypans=ypans, margins=margins)
sgopen, id, xsize=fig_size[0], ysize=fig_size[1], /inch

end