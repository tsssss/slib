;+
; Set axis for plotting without actually drawing the axis.
;
; var.
; position=.
; xrange=.
; xlog=.
; yrange=.
; ylog=.
;-
pro set_axis, var, position=tpos, $
    xrange=xrange, xlog=xlog, yrange=yrange, ylog=ylog, iso=iso

    if n_elements(tpos) ne 4 then return

    if n_elements(xrange) eq 0 then begin
        xrange = minmax(get_var_time(var))
    endif
    
    if n_elements(xlog) eq 0 then begin
        xlog = 0
    endif
    
    if n_elements(yrange) eq 0 then begin
        if n_elements(var) eq 0 then return
        if tnames(var) eq '' then return
        yrange = get_var_setting(var, 'yrange', is_exist)
        if is_exist eq 0 then yrange = [0,1]
    endif
    
    if n_elements(ylog) eq 0 then begin
        if n_elements(var) eq 0 then begin
            ylog = 0
        endif else begin
            ylog = get_var_setting(var, 'ylog', is_exist)
            if is_exist eq 0 then ylog = 0
        endelse
    endif
    
    plot, xrange, yrange, $
        xstyle=5, xrange=xrange, xlog=xlog, $
        ystyle=5, yrange=yrange, ylog=ylog, $
        position=tpos, nodata=1, noerase=1, iso=iso
    
end