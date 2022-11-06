;+
; Calculated ilat from L-shell.
;-
;

function lshell2ilat, lshell, radian=radian, degree=degree

    deg = 180d/!dpi
    rad = !dpi/180d
    
    ilat = acos(sqrt(1d/lshell))
    if keyword_set(degree) then ilat *= deg
    
    return, ilat

end