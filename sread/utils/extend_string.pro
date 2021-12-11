;+
; Extend a string or an array of string to a given length.
; 
; str_in. A string or an array of string to be extended.
; length=. A number sets the target length.
; left=. A boolean. Set to extend on the left.
;-

function extend_string, str_in, length=length, left=left
    retval = !null

    if n_elements(str_in) eq 0 then return, retval

    strs = str_in
    str_lens = strlen(strs)
    if n_elements(length) eq 0 then length = max(str_lens)
    nstr = n_elements(strs)
    for ii=0, nstr-1 do begin
        if keyword_set(left) then begin
            for jj=0, length-str_lens[ii]-1 do strs[ii] = ' '+strs[ii]
        endif else begin
            for jj=0, length-str_lens[ii]-1 do strs[ii] = strs[ii]+' '
        endelse
    endfor
    return, strs

end

strs_list = list()
strs_list.add, 'a'
strs_list.add, ['a','bb','cc']
foreach strs, strs_list do print, '"'+extend_string(strs, length=5)+'"'
end
