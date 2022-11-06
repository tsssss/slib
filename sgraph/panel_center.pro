;+
; Center panels to given xsize and ysize.
;+

pro panel_center, panels, xsize=xsize, ysize=ysize

    if ~isa(panels,'dictionary') then return

    abs_pos = panels.abs_pos
    if n_elements(xsize) ne 0 then begin
        diff = xsize-panels.xsize
        if diff gt 0 then begin
            diff_half = diff*0.5
            xspace = panels.xspace
            xspace[0] += diff_half
            xspace[-1] += diff_half
            panels.xspace = xspace
            panels.xsize = xsize
            abs_pos[[0,2],*,*] += diff_half
        endif
    endif

    if n_elements(ysize) ne 0 then begin
        diff = ysize-panels.ysize
        if diff gt 0 then begin
            diff_half = diff*0.5
            yspace = panels.yspace
            yspace[0] += diff_half
            yspace[-1] += diff_half
            panels.yspace = yspace
            panels.ysize = ysize
            abs_pos[[1,3],*,*] += diff_half
        endif
    endif

    panels.abs_pos = abs_pos

end
