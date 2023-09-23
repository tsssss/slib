;+
; Convert a vector from MAG to GEO.
;
; vec0. An array in [3] or [n,3]. In MAG, in any unit.
; times. An array of UT sec, in [n].
;-

function mag2geo, vec0, time, _extra=ex
    compile_opt idl2 & on_error, 2

    vec1 = double(vec0)
    n1 = n_elements(vec1)/3 & n2 = n1+n1 & n3 = n2+n1
    vx0 = vec1[0:n1-1]
    vy0 = vec1[n1:n2-1]
    vz0 = vec1[n2:n3-1]

    ; get transpose(T5).
    dipole_dir, time, lat, lon, /radian
    sinp =  sin(lat)
    cosp = -cos(lat)
    sinl =  sin(lon)
    cosl =  cos(lon)

    ; vectorized, so should be faster than matrix ##.
    tmp = sinp*vx0 - cosp*vz0
    vx1 = cosl*tmp - sinl*vy0
    vy1 = sinl*tmp + cosl*vy0
    vz1 = cosp*vx0 + sinp*vz0

    vec1[0:n1-1] = temporary(vx1)
    vec1[n1:n2-1] = temporary(vy1)
    vec1[n2:n3-1] = temporary(vz1)
    return, vec1

end

;  t5 = [[ sinp*cosl,  sinp*sinl, cosp], $
;        [     -sinl,       cosl,    0], $
;        [-cosp*cosl, -cosp*sinl, sinp]]
