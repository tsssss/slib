;+
; Normalize panel positions.
;-

function panel_normalize, panels

    abs_pos = panels.abs_pos
    xspace = panels.xspace
    yspace = panels.yspace
    norm_pos = abs_pos
    norm_pos[[0,2],*,*] /= panels.xsize
    norm_pos[[1,3],*,*] /= panels.ysize

    return, reform(norm_pos)

end
