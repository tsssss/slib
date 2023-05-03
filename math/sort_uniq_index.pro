;+
; Return the uniq element index after sorting.
;-
;

function sort_uniq_index, arr1d

    if n_elements(arr1d) lt 1 then return, 0
    return, uniq(arr1d, sort(arr1d))

end