;+
; y0 is the data.
; x0 is optional.
; width sets the section to calc stddev.
; ratio sets how many points are used to calc stddev.
; extra keywords for interpol.
;-
function moving_median, y0, x0, $
    width = width, ratio = ratio, _extra = extra

    nrec = n_elements(y0)
    if nrec eq 0 then message, 'no data ...'
    if n_elements(x0) eq 0 then x0 = findgen(nrec)
    if n_elements(width) eq 0 then width = nrec/20>1    ; calc 20 sections.
    if n_elements(ratio) eq 0 then ratio = 0.025        ; use 95% points.

    nsec = nrec/width
    x1 = findgen(nsec+1)*(nrec-1)/nsec
    mvtmp = findgen(nsec)
    for i = 0, nsec-1 do begin
        tmp = y0[x1[i]:x1[i+1]]
        mvtmp[i] = median((tmp[sort(tmp)])[ratio*width:(1-ratio)*width])
    endfor
    x1 = (x1[0:nsec-1]+x1[1:nsec])*0.5      ; use middle of section.
    mvtmp = interpol(mvtmp, x0[x1], x0, _extra = extra)

    return, mvtmp
end