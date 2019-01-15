;+
; Rotate a vector in [N,3] by a rotation maxtric by [N,3,3], or [3,3].
;-
function rotate_vector, v, m
    
    w = v

    v_ndim = size(v,/n_dimension)
    m_ndim = size(m,/n_dimension)

    if m_ndim eq 3 then begin
        w[*,0] = v[*,0]*m[*,0,0] + v[*,1]*m[*,0,1] + v[*,2]*m[*,0,2]
        w[*,1] = v[*,0]*m[*,1,0] + v[*,1]*m[*,1,1] + v[*,2]*m[*,1,2]
        w[*,2] = v[*,0]*m[*,2,0] + v[*,1]*m[*,2,1] + v[*,2]*m[*,2,2]
    endif else if v_ndim eq 1 then begin
        w[0] = v[0]*m[0,0] + v[1]*m[0,1] + v[2]*m[0,2]
        w[1] = v[0]*m[1,0] + v[1]*m[1,1] + v[2]*m[1,2]
        w[2] = v[0]*m[2,0] + v[1]*m[2,1] + v[2]*m[2,2]
    endif else begin
        w[*,0] = v[*,0]*m[0,0] + v[*,1]*m[0,1] + v[*,2]*m[0,2]
        w[*,1] = v[*,0]*m[1,0] + v[*,1]*m[1,1] + v[*,2]*m[1,2]
        w[*,2] = v[*,0]*m[2,0] + v[*,1]*m[2,1] + v[*,2]*m[2,2]
    endelse

    return, w
end
