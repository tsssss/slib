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
            panels.xspace[0] += diff_half
            panels.xspace[-1] += diff_half
            panels.xsize = xsize
        endif
    endif

    if n_elements(ysize) ne 0 then begin
        diff = ysize-panels.ysize
        if diff gt 0 then begin
            diff_half = diff*0.5
            panels.yspace[0] += diff_half
            panels.yspace[-1] += diff_half
            panels.ysize = ysize
        endif
        endif
    endif

end
