;+
; Save data to system.
;-
pro save_data, vars, ptrs, skt

    nvar = n_elements(vars)
    if nvar eq 0 then return
    
    vars = strlowcase(vars)
    allvars = strlowcase(tag_names(skt.var))
    for i=0, nvar-1 do begin
        tvar = vars[i]
        vatt = skt.var.(where(allvars eq tvar)).att
        if not stagexist('var_type', vatt) then return
        if strlowcase(vatt.var_type.value) ne 'data' then continue   ; skip support data.
        data = *ptrs[i]
        if stagexist('depend_time', vatt) then timevar = strlowcase(vatt.depend_time.value) $
        else timevar = strlowcase(vatt.depend_0.value)
        idx = where(vars eq timevar, cnt)
        if cnt eq 0 then message, 'no time found ...'
        time = *ptrs[idx[0]]
        if not stagexist('depend_1', vatt) then begin
            store_data, tvar, time, data
        endif else begin
            value = *ptrs[(where(vars eq strlowcase(vatt.depend_1.value)))[0]]
            store_data, tvar, time, data, value
        endelse
        
        ; save vatt.
        for j=0, n_elements(tag_names(vatt))-1 do $
            options, tvar, strlowcase(vatt.(j).name), vatt.(j).value
    endfor
end