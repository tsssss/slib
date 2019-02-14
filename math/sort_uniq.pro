;+
; Return the uniq element of an array after sorting.
;-
;

function sort_uniq, arr1d

    if n_elements(arr1d) lt 1 then return, arr1d
    return, arr1d[uniq(arr1d, sort(arr1d))]

end