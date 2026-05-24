function is_valid_probe, all_probes, probe
    compile_opt idl2

    index = where(all_probes eq probe, count)
    if count eq 0 then return, 0
    return, 1
end
