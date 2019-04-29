;+
; Set axis properties.
; Several ways:
;   1. use yrange, yticks.
;   2. use yrange, ytickv.
;
;-

pro set_yaxis, var, range=range, ticks=ticks, tickv=tickv, minor=minor, tickn=tickn

    ; Figure out yrange.
    if n_elements(range) eq 0 then range = sg_autolim(get_var_data(var))

    ; Figure out ticks, and tickv.
    if n_elements(ticks) ne 0 then begin
        tickv = smkarthm(range[0],range[1],ticks+1,'n')
    endif else if n_elements(tickv) eq 0 then begin
        drange = (range[1]-range[0])
        numbers = [2,3,4,5]
        foreach number, numbers do begin
            if (drange mod number) ne 0 then continue
            ticks = number
            break
        endforeach
        if n_elements(ticks) eq 0 then ticks = 2
        tickv = smkarthm(range[0],range[1],ticks+1,'n')
    endif
    if n_elements(tickv) ne 0 then ticks = n_elements(tickv)-1

    if n_elements(minor) eq 0 then begin
        drange = abs((range[1]-range[0])/ticks)
        numbers = [3,4,5,6,2]
        foreach number, numbers do begin
            if (drange mod number) ne 0 then continue
            minor = number
            break
        endforeach
        if n_elements(minor) eq 0 then minor = 5
    endif
    
    if n_elements(tickn) eq 0 then begin
        tickn = strarr(ticks+1)
        for ii=0, ticks do tickn[ii] = sgnum2str(tickv[ii])
    endif

    options, var, 'yrange', range
    options, var, 'yticks', ticks
    options, var, 'ytickv', tickv
    options, var, 'ytickname', tickn
    options, var, 'yminor', minor

end


set_yaxis, 'thd_b_tilt', range=[20,80]
end