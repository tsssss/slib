;+
; Replace given fillval with nan, or find fillval from settings.
; 
; var. A string of variable name.
; fillval. A number for the fill value.
;-
pro treat_fillval, var, fillval

    if n_elements(fillval) eq 0 then begin
        fillval = get_setting(var, 'fillval', exist)
        if not exist then fillval = -1d31
    endif else add_setting, var, {fillval: fillval}
    
    if n_elements(fillval) eq 0 then return
    
    get_data, var, tmp, dat
    idx = where(dat eq fillval, cnt)
    if cnt eq 0 then return
    type = size(dat[0],/type)
    case type of
        5: dat[idx] = !values.d_nan     ; double.
        4: dat[idx] = !values.f_nan     ; float.
        else: dat[idx] = 0.
    endcase
    store_data, var, tmp, dat
end