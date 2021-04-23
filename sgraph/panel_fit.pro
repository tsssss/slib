;+
; Fit the panels to given xsize and ysize.
; Keep aspect ratio.
;-

pro panel_fit, panels, xsize=xsize, ysize=ysize


    if ~isa(panels,'dictionary') then return

    aspect_ratio = panels.ysize/panels.xsize
    if n_elements(xsize) eq 0 and n_elements(ysize) eq 0 then begin
        return
    endif
    if n_elements(xsize) eq 0 and n_elements(ysize) ne 0 then begin
        xsize = ysize/aspect_ratio
    endif
    if n_elements(xsize) eq 0 and n_elements(ysize) eq 0 then begin
        ysize = xsize*aspect_ratio
    endif
    new_xsize = xsize
    new_ysize = new_xsize*aspect_ratio
    if new_ysize gt ysize then begin
        new_ysize = ysize
        new_xsize = ysize/aspect_ratio
    endif

    panel_scale, panels, xsize=new_xsize
    panel_center, panels, xsize=xsize, ysize=ysize


end
