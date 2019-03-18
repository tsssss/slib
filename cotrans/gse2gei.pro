;+
; Convert vector from GSE to GEI.
;
; vec0. An array in [3] or [n,3]. In GSE, in any unit.
; times. An array of UT sec, in [n].
;-

function gse2gei, vec0, time
    compile_opt idl2 & on_error, 2

    vec1 = double(vec0)
    n1 = n_elements(vec1)/3 & n2 = n1+n1 & n3 = n2+n1
    vx0 = vec1[0:n1-1]
    vy0 = vec1[n1:n2-1]
    vz0 = vec1[n2:n3-1]

    ; get transpose(t2).
    sun_dir, time, e, l
    sine = sin(e)
    cose = cos(e)
    sinl = sin(l)
    cosl = cos(l)

    ; vectorized, so should be faster than matrix ##.
    tmp =  sinl*vx0 + cosl*vy0
    vx1 =  cosl*vx0 - sinl*vy0
    vy1 =  cose*tmp - sine*vz0
    vz1 =  sine*tmp + cose*vz0

    vec1[0:n1-1] = temporary(vx1)
    vec1[n1:n2-1] = temporary(vy1)
    vec1[n2:n3-1] = temporary(vz1)
    return, vec1

end

; <l,z> = [[ cosl, sinl, 0D], $
;          [-sinl, cosl, 0D], $
;          [   0D,   0D, 1D]]
; <e,x> = [[1D,    0D,   0D], $
;          [0D,  cose, sine], $
;          [0D, -sine, cose]]
; t2 = <l,z> * <e,x>
;    = [[ cosl, sinl *cose, sinl *sine], $
;       [-sinl, cosl *cose, cosl *sine], $
;       [   0D,      -sine,       cose]]
