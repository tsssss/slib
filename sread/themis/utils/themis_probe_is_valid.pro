;+
; Return if a given probe is valid.
;-

function themis_probe_is_valid, probe

    probes = themis_get_probes()
    the_probe = strlowcase(probe[0])
    if strlen(the_probe) eq 3 then the_probe = strmid(the_probe,2,1)
    index = where(probes eq the_probe, count)
    if count eq 0 then return, 0 else return, 1

end

print, themis_probe_is_valid('a')
print, themis_probe_is_valid('thd')
end