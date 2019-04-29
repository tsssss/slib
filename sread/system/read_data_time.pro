;+
; Read given variables from given files. If times are provided, cut data to time.
; 
; files. A string or an array of N full file names.
; vars. A string or an array of variables to be read.
; prefix. A string to be added before vars, e.g., 'tha_'.
; suffix. A string to be added after vars.
; time_var. A string specifies the variable correspond to time.
; times. An [N,2] array of time range in the format of time_var. 
; dum. A boolean. Set if the CDF is not well written.
;
; Will save data to system and replace fill value with nan.
;-

pro read_data_time, files, vars, prefix=prefix, suffix=suffix, $
    time_var=time_var, times=time, dum=dum
    
    nfile = n_elements(files)
    if nfile eq 0 then message, 'No file is given ...'
    
    if n_elements(prefix) eq 1 then begin
        vars = prefix+vars
        time_var = prefix+time_var
    endif
    
    if n_elements(suffix) eq 1 then begin
        vars += suffix
        time_var += suffix
    endif
    
    ; read the first file.
    if n_elements(time_var) eq 1 then begin
        rec = find_rec(files[0], time_var, time[0,*])
        dat0 = scdfread(files[0], vars, rec, skt=skt)
    endif else dat0 = scdfread(files[0], vars, skt=skt)
    
    ; construct a structue to hold all data.
    nvar = n_elements(vars)
    if nvar ne n_elements(dat0) then message, 'Some variables do not exist ...'
    ptrs = ptrarr(nvar)
    for j=0, nvar-1 do ptrs[j] = (dat0[j].value)
    
    ; read the rest files.
    for i=1, nfile-1 do begin
        if n_elements(time_var) eq 1 then begin
            rec = find_rec(files[i], time_var, time[i,*])
            dat0 = scdfread(files[i], vars, rec)
        endif else dat0 = scdfread(files[i], vars)
        for j=0, nvar-1 do begin
            ; works for all dims b/c cdf records on the 1st dim of array.
            dims1 = size(*ptrs[j],/dimensions)
            dims2 = size(*dat0[j].value,/dimensions)
            case n_elements(dims1)-n_elements(dims2) of
                1: *dat0[j].value = reform(*dat0[j].value,[1,dims2])
                -1: *ptrs[j] = reform(*ptrs[j],[1,dims1])
                0: ; do nothing.
                else: message, 'Incompatible dimensions ...'
            endcase
            *ptrs[j] = [*ptrs[j],*(dat0[j].value)]
            ptr_free, dat0[j].value  ; release pointers.
        endfor
    endfor
    
    
    ; save data to system, remove fill value with nan.
    if keyword_set(dum) then begin
        tvaridx = where(vars eq time_var, complement=varsidx)
        times = *ptrs[tvaridx[0]]
        foreach tidx, varsidx do begin
            store_data, vars[tidx], times, *ptrs[tidx]
        endforeach
    endif else begin    ; for well-written CDFs.
        save_data, vars, ptrs, skt
        foreach tvar, vars do treat_fillval, tvar
    endelse
    
end