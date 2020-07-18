;+
; Capitalize the first letter of a string.
;-
function str_cap, str

    len = strlen(str)
    if len lt 1 then return, ''
    first = strupcase(strmid(str,0,1))
    if len eq 1 then return, first
    return, first+strmid(str,1)

end

print, str_cap('hello')
end