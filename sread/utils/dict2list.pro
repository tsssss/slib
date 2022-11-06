;+
; Convert a dictionary containing arrays, to an list of dictionaries.
;-

function dict2list, dict
    retval = list()

    if n_elements(dict) eq 0 then return, retval
    if typename(dict) ne strupcase('dictionary') then return, retval
    keys = dict.keys()

    ; Ensure all values have the same length.
    nrec = n_elements(dict[keys[0]])
    foreach key, keys do if n_elements(dict[key]) ne nrec then return, retval

    for ii=0, nrec-1 do begin
        tdict = dictionary()
        foreach key, keys do tdict[key] = (dict[key])[ii]
        retval.add, tdict
    endfor

    return, retval

end