;+
; Interpolate data to given times and return the values.
;-
;

function interp_data, var, ut0

    if tnames(var) eq '' then return, !null
    
    ;display_type = get_setting(var, 'display_type', exist)
    get_data, var, uts, dat
    return, sinterpol(dat, uts, ut0)
end