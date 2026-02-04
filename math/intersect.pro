function intersect, a0, b0

    a1 = sort_uniq(a0)
    b1 = sort_uniq(b0)
    na = n_elements(a1)
    nb = n_elements(b1)
    if na le nb then begin
        a2 = temporary(a1)
        b2 = temporary(b1)
    endif else begin
        a2 = temporary(b1)
        b2 = temporary(a1)
    endelse

    c0 = list()
    foreach a, a2 do begin
        index = where(b2 eq a, count)
        if count eq 0 then continue
        c0.add, a
    endforeach

    return, c0.toarray()
end


a0 = [1,2,3,4,5,6]
b0 = [4,5,6,7,8,9]
c0 = intersect(a0, b0)
print, c0
end