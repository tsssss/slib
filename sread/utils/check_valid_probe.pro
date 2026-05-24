function check_valid_probe, probe, valid_probes
    compile_opt idl2

    if n_elements(probe) eq 0 then return, 0
    the_probe = strlowcase(probe)
    if n_elements(valid_probes) eq 0 then return, 0
    index = where(strlowcase(valid_probes) eq the_probe, count)
    if count eq 0 then return, 0
    return, the_probe

end
