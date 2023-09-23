;+
; Return color table for given id
;-

function get_ct, id

    if id eq 'electron' then return, 65
    if id eq 'proton' then return, 63
    if id eq 'oxygen' then return, 64
    if id eq 'e' then return, get_ct('electron')
    if id eq 'p' then return, get_ct('proton')
    if id eq 'i' then return, get_ct('proton')
end