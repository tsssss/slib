;+
; Return a list of array for all unique combinations when choosing k elements from an n-element array.
; 
; array. An n-elements array, elements must be unique.
; kk. A number sets the number of elements that are picked.
;-
;
function choose_from, array, kk

    mm = n_elements(array)
    n0 = (kk gt floor(mm/2))? mm-kk: kk
    ncombo = 1ull
    for ii=0, n0-1 do ncombo *= (mm-ii)
    
    if mm le kk then return, list(array)            ; list of 1.
    if kk eq 1 then return, list(array,/extract)    ; list of n.
    
    ; Use C(n,k) = C(n-1,k)+C(n-1,k-1).
    combo = list()
    if mm eq 1 then return, combo
    rest_combo = choose_from(array[1:*],kk-1)
    foreach rest, rest_combo do combo.add, reform((list(array[0],rest,/extract)).toarray())
    rest_combo = choose_from(array[1:*],kk)
    foreach rest, rest_combo do combo.add, rest
    
    return, combo

end

foreach combo, choose_from(['a','b','c'], 3) do print, combo
foreach combo, choose_from(['a','b','c','d'], 3) do print, combo
foreach combo, choose_from(['a','b','c','d'], 2) do print, combo
foreach combo, choose_from(['a','b','c','d','e'], 3) do print, combo

end