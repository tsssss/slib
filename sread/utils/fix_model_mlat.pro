;+
; The footpoint MLat contains steps. By comparing the traced dipole results to
; the theoretical dipole results, I found that the local maximums are good.
; Thus the fix is to interpolate using local maximums of the traced MLat.
;-
;

pro fix_model_mlat, mlat_var, to=new_var, errmsg=errmsg

    errmsg = ''
    
    if tnames(mlat_var) eq '' then begin
        errmsg = handle_error('Invalid input variable ...')
        return
    endif
    
    get_data, mlat_var, times, mlat0s
    nrec = n_elements(times)
    
    ; 1: local maximum, 0: other points.
    flags = fltarr(nrec)
    ; assume the two ends are local maximums.
    flags[0] = 1
    flags[nrec-1] = 1
    for ii=1, nrec-2 do begin
        slope_before = mlat0s[ii]-mlat0s[ii-1]
        slope_after = mlat0s[ii+1]-mlat0s[ii]
        if slope_before gt 0 and slope_after lt 0 then flags[ii] = 1
    endfor
    
    index = where(flags eq 1)
    mlat1s = interpol(mlat0s[index], times[index], times)
    
    if n_elements(new_var) eq 0 then new_var = mlat_var[0]+'_fixed'
    store_data, new_var, times, mlat1s

end


fix_model_mlat, 'rba_fpt_mlat'
end