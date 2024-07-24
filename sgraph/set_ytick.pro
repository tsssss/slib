pro set_ytick, var, yrange=yrange, ystep=ystep, $
    ylog=ylog, ytickv=ytickv, yminor=yminor, ytickn=ytickn

    if n_elements(var) eq 0 then return
    if tnames(var) eq '' then return

    if n_elements(yrange) ne 0 then options, var, 'yrange', yrange
    if n_elements(ylog) eq 0 then ylog = 0
    options, var, 'ylog', ylog

    if n_elements(ytickv) ne 0 then begin
        yticks = n_elements(ytickv)-1
        options, var, 'ytickv', ytickv
        options, var, 'yticks', yticks
    endif
    if n_elements(ytickn) ne 0 then options, var, 'ytickname', ytickn

    yrange = get_var_setting(var, 'yrange', exist)
    if exist eq 0 then begin
        yrange = minmax(get_var_data(var))
        yrange += [-1,1]*total(yrange*[-1,1])*0.05
        options, var, 'yrange', yrange
    endif
    
    if n_elements(ystep) eq 0 then begin
        ystep = abs(total(yrange*[-1,1]))/2
        ystep0 = 10d^floor(alog10(ystep))
        ystep = round(ystep/ystep0)*ystep0
    endif    

    if n_elements(ytickv) eq 0 then ytickv = make_bins(yrange, ystep, inner=1)
    yticks = n_elements(ytickv)-1
    if ylog eq 1 then begin
        log_yrange = alog10(yrange)
        log_ytickv = make_bins(log_yrange, 1, inner=1)
        ytickv = 10d^log_ytickv
        yminor = 9
    endif else begin
        if n_elements(yminor) eq 0 then begin
            yminor = ystep/10^floor(alog10(ystep))
            if yminor eq 1 then yminor = 4
        endif
    endelse

    options, var, 'ytickv', ytickv
    options, var, 'yticks', yticks
    options, var, 'yminor', yminor

end