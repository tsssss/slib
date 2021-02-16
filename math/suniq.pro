;+
; Type: function.
;
; Purpose: Remove duplicated items in given array.
; 
; Parameters: dat0, in, array, required. Given array.
;
; Keywords: keep_last, in, boolean, optional. Set to keep the last one in all
;   duplicated items. Default is to keep to first one.
;
; Notes: none.
;
; Dependence: none.
;
; History:
;   2015-08-19, Sheng Tian, create.
;-

function suniq, dat0, keep_last = keep_last

    nrec = n_elements(dat0)
    ; sort to use uniq.
    idx1 = sort(dat0)       ; index to map original to sorted array.
    if ~keyword_set(keep_last) then idx1 = reverse(idx1)
    dat1 = dat0[idx1]       ; sorted array.
    idx2 = uniq(dat1)       ; index of uniq array.
    idx3 = sort(idx1[idx2]) ; index to map sorted to original array.
    return, (dat1[idx2])[idx3]
end

a0 = [1,4,3,6,4,2,6]
a1 = suniq(a0)
print, a0
print, a1
print, suniq(a0,/keep_last)
end
