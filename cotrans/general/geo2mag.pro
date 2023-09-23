;+
; Convert a vector from GEO to MAG.
;
; vec0. An array in [3] or [n,3]. In GEO, in any unit.
; times. An array of UT sec, in [n].
;-

function geo2mag, vec0, time, _extra=ex
    compile_opt idl2 & on_error, 2

    vec1 = double(vec0)
    n1 = n_elements(vec1)/3 & n2 = n1+n1 & n3 = n2+n1
    vx0 = vec1[0:n1-1]
    vy0 = vec1[n1:n2-1]
    vz0 = vec1[n2:n3-1]

    ; get T5.
    dipole_dir, time, lat, lon, /radian
    sinp =  sin(lat)
    cosp = -cos(lat)
    sinl =  sin(lon)
    cosl =  cos(lon)

    ; vectorized, so should be faster than matrix ##.
    tmp =  cosl*vx0 + sinl*vy0
    vx1 =  sinp*tmp + cosp*vz0
    vy1 = -sinl*vx0 + cosl*vy0
    vz1 = -cosp*tmp + sinp*vz0

    vec1[0:n1-1] = temporary(vx1)
    vec1[n1:n2-1] = temporary(vy1)
    vec1[n2:n3-1] = temporary(vz1)
    return, vec1

end

;  t5 = [[ sinp*cosl,  sinp*sinl, cosp], $
;        [     -sinl,       cosl,    0], $
;        [-cosp*cosl, -cosp*sinl, sinp]]
