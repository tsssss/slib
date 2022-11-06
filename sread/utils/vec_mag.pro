;+
; Calculate the magnitude of a given vector.
; 
; vec. Several cases:
;   0. An array of [M], where M is vector dimension. Return its magnitude.
;   1. An array of [N,M], where N is the # of record. Return [N] magnitudes.
;   2. An array of [M,N], N is still # of rec, in this case set transpose.
;   3. A number. Return its absolute value.
;-
function vec_mag, vec, transpose=transpose

    ndim = size(vec,/n_dimension)
    
    if ndim eq 0 then return, abs(vec)
    if ndim eq 1 then return, sqrt(total(vec^2))
    if ndim ne 2 then message, 'Wrong dimension ...'
    
    ; vec in [N,M], assume N is the # records.
    sum_index = (keyword_set(transpose))? 1: 2
    return, sqrt(total(vec^2, sum_index))

end    