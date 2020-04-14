;+
; Set intersection. Return the intersection set.
; Adopted from http://www.idlcoyote.com/tips/set_operations.html.
; 
; aa. Input set 1.
; bb. Input set 2.
;-
;

function set_inter, aa, bb

;    a = sort_uniq(aa)
;    b = sort_uniq(bb)
;    
;    flag=[replicate(0b,n_elements(a)),replicate(1b,n_elements(b))]
;    s=[a,b]
;    srt=sort(s)
;    s=s[srt] & flag=flag[srt]
;    wh=where(s eq shift(s,-1) and flag ne shift(flag, -1),cnt)
;    if cnt eq 0 then return, !null
;    return,a[srt[wh]]

    a = sort_uniq(aa)
    b = sort_uniq(bb)
    c = [a,b]
    c = c[sort(c)]
    index = where(c eq shift(c,-1), count)
    if count eq 0 then return, !null
    d = c[index]
    return, sort_uniq(d)
    
end

a = [3,1,2,5]
b = [1,3,4,3]
;a = findgen(11111)
b = findgen(100000)
tic
print, set_inter(a,b)
toc
end