;+
; Calculate the cross product of two 3-D vtors.
; 
; v1. An array of [3], [N,3], or [3,N]. Set transpose for [3,N].
;-
function vec_cross, v1, v2, transpose=transpose

    if n_elements(v1) eq 3 then $
        return, [$
            v1[1] * v2[2] - v1[2] * v2[1], $
            v1[2] * v2[0] - v1[0] * v2[2], $
            v1[0] * v2[1] - v1[1] * v2[0]]

    v = v1
    if keyword_set(transpose) then begin
        v[0,*] = v1[1,*] * v2[2,*] - v1[2,*] * v2[1,*]
        v[1,*] = v1[2,*] * v2[0,*] - v1[0,*] * v2[2,*]
        v[2,*] = v1[0,*] * v2[1,*] - v1[1,*] * v2[0,*]
    endif else begin
        v[*,0] = v1[*,1] * v2[*,2] - v1[*,2] * v2[*,1]
        v[*,1] = v1[*,2] * v2[*,0] - v1[*,0] * v2[*,2]
        v[*,2] = v1[*,0] * v2[*,1] - v1[*,1] * v2[*,0]
    endelse
    
    return, v

end