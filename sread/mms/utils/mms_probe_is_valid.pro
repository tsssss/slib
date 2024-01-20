function mms_probe_is_valid, probe

    probes = mms_get_probes()
    the_probe = strlowcase(probe[0])
    if strlen(the_probe) eq 4 then the_probe = strmid(the_probe,3,1)
    index = where(probes eq the_probe, count)
    if count eq 0 then return, 0 else return, 1

end

print, mms_probe_is_valid('1')
print, mms_probe_is_valid('mms3')
end