;+
; Convert a vector from GEO to GEI.
;
; vec0. An array in [3] or [n,3]. In GEO, in any unit.
; times. An array of UT sec, in [n].
;-

function geo2gei, vec0, time
    compile_opt idl2 & on_error, 2

    vec1 = double(vec0)
    n1 = n_elements(vec1)/3 & n2 = n1+n1 & n3 = n2+n1
    vx0 = vec1[0:n1-1]
    vy0 = vec1[n1:n2-1]
    vz0 = vec1[n2:n3-1]

    ; get transpose(t1).
    gmst = gmst(time, /radian)          ; geo to gei.
    sing = sin(gmst)
    cosg = cos(gmst)

    ; vectorized, so should be faster than matrix ##.
    vx1 =  cosg*vx0 - sing*vy0
    vy1 =  sing*vx0 + cosg*vy0
    vz1 =  vz0

    vec1[0:n1-1] = temporary(vx1)
    vec1[n1:n2-1] = temporary(vy1)
    vec1[n2:n3-1] = temporary(vz1)
    return, vec1

end

;  t1 = [[ cosg, sing, 0], $
;        [-sing, cosg, 0], $
;        [    0,    0, 1]]
