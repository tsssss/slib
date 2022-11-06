;+
; Calculate the cross product of two 3-D vtors.
;
; v1. An array of [3], [N,3], or [3,N]. Set transpose for [3,N].
;-
function vec_dot, v1, v2, transpose=transpose

    if n_elements(v1) eq 3 then $
        return, v1[0]*v2[0] + v1[1]*v2[1] + v1[2]*v2[2]
        
    if keyword_set(transpose) then begin
        return, v1[0,*]*v2[0,*] + v1[1,*]*v2[1,*] + v1[2,*]*v2[2,*]
    endif else begin
        return, v1[*,0]*v2[*,0] + v1[*,1]*v2[*,1] + v1[*,2]*v2[*,2]
    endelse
        
end