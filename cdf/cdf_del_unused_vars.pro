
pro cdf_del_unused_vars, file

    unused_vars = cdf_detect_unused_vars(file)
    all_vars = cdf_vars(file)
    foreach key, unused_vars.keys() do begin
        foreach var, unused_vars[key] do begin
            index = where(all_vars eq var, count)
            if count eq 0 then continue
            cdf_del_var, var, filename=file
        endforeach
    endforeach

end
