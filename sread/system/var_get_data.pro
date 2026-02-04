function var_get_data, var, val, in=time_range, at=time, raw=raw, times=times, limits=lim, settings=settings, _extra=ex

    data = get_var_data(var, val, in=time_range, at=time, raw=raw, times=times, limits=lim, settings=settings, _extra=ex)
    ;if n_elements(data) eq 0 then data = get_var_time(var, in=time_range, limits=lim, _extra=ex)
    return, data
    
end