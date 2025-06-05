;+
; Return the uniq element of an array after sorting.
; 
; index=. Set to return the index.
;-
;

function sort_uniq, arr1d, index=index

    if n_elements(arr1d) lt 1 then begin
        if keyword_set(index) then return, 0
        return, arr1d
    endif
    
    the_index = uniq(arr1d, sort(arr1d))
    if keyword_set(index) then return, the_index
    return, arr1d[the_index]

end