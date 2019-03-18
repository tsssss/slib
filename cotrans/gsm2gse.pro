;+
; Convert a vector from GSM to GSE.
;
; vec0. An array in [3] or [n,3]. In GSM, in any unit.
; times. An array of UT sec, in [n].
;-

function gsm2gse, vec0, time
    compile_opt idl2 & on_error, 2

    vec1 = double(vec0)
    n1 = n_elements(vec1)/3 & n2 = n1+n1 & n3 = n2+n1
    vx0 = vec1[0:n1-1]
    vy0 = vec1[n1:n2-1]
    vz0 = vec1[n2:n3-1]

    ; get transpose(t3).
    dipole_dir, time, qgx, qgy, qgz     ; qg in geo.
    gmst = gmst(time, /radian)          ; geo to gei.
    sing = sin(gmst)
    cosg = cos(gmst)
    qex = cosg*qgx - sing*qgy
    qey = sing*qgx + cosg*qgy
    sun_dir, time, e, l                 ; gei to gse.
    sine = sin(e)
    cose = cos(e)
    sinl = sin(l)
    cosl = cos(l)
    p = atan(-sinl*qex+cosl*(cose*qey+sine*qgz), -sine*qey+cose*qgz)
    sinp = sin(p)
    cosp = cos(p)

    ; vectorized, so should be faster than matrix ##.
    vx1 =  vx0
    vy1 =  cosp*vy0 + sinp*vz0
    vz1 = -sinp*vy0 + cosp*vz0

    vec1[0:n1-1] = temporary(vx1)
    vec1[n1:n2-1] = temporary(vy1)
    vec1[n2:n3-1] = temporary(vz1)
    return, vec1

end

; t3 = <-p,x>
;    = [[1D,   0D,    0D], $
;       [0D, cosp, -sinp], $
;       [0D, sinp,  cosp]]
