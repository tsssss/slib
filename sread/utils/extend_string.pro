;+
; Extend a string or an array of string to a given length.
;-

function extend_string, str_in, length=length
    retval = !null

    if n_elements(str_in) eq 0 then return, retval

    strs = str_in
    str_lens = strlen(strs)
    if n_elements(length) eq 0 then length = max(str_lens)
    nstr = n_elements(strs)
    for ii=0, nstr-1 do for jj=0, length-str_lens[ii] do strs[ii] += ' '
    return, strs

end

strs_list = list()
strs_list.add, 'a'
strs_list.add, ['a','bb','cc']
foreach strs, strs_list do print, '"'+extend_string(strs, length=5)+'"'
end
