;+
; Interpolate a given data to given times.
; 
; var. A string of a variable name.
; times. An array of times to be interpolated to.
; to. A string specified the varialbe, whos times will be used.
;-

pro interp_time, var, times, to=new_var

    get_data, var, tmp, dat, val
    if keyword_set(new_var) then get_data, new_var, times
    dat = sinterpol(dat, tmp, times, /nan)
    
    ndim = size(val,/n_dimension)
    if ndim eq 2 then val = sinterpol(val, tmp, times, /nan)
    if ndim eq 0 then store_data, var, times, dat else store_data, var, times, dat, val

end