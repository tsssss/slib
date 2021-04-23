;+
; Scale panels to given xsize or ysize.
; Keep aspect ratio.
;-

pro panel_scale, panels, xsize=xsize, ysize=ysize

    if ~isa(panels,'dictionary') then return

    aspect_ratio = panels.ysize/panels.xsize
    if n_elements(xsize) ne 0 and n_elements(ysize) ne 0 then begin
        if aspect_ratio ne ysize/xsize then return
    endif
    if n_elements(xsize) eq 0 and n_elements(ysize) eq 0 then begin
        return
    endif
    if n_elements(xsize) ne 0 then ysize = xsize*aspect_ratio
    if n_elements(ysize) ne 0 then xsize = ysize/aspect_ratio

    region_resize, panels, xsize=xsize, ysize=ysize

end
