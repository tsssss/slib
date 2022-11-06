;+
; Delete a setting.
;-
pro cdf_del_setting, key, varname=var, filename=cdf0, errmsg=errmsg

    errmsg = ''

    if n_elements(key) eq 0 then begin
        errmsg = handle_error('No input setting ...')
        return
    endif
    the_key = key[0]

    ; Check if given file is a cdf_id or filename.
    if n_elements(cdf0) eq 0 then begin
        errmsg = handle_error('No input file ...')
        return
    endif
    input_is_file = size(cdf0, /type) eq 7
    if input_is_file then begin
        file = cdf0
        if file_test(file) eq 0 then begin
            errmsg = handle_error('Input file does not exist ...')
            return
        endif
        cdfid = cdf_open(file)
    endif else begin
        cdfid = cdf0
    endelse

    vatt_mode = n_elements(var) gt 0
    if vatt_mode then begin
        if ~cdf_has_var(var, filename=cdfid, iszvar=iszvar) then begin
            errmsg = handle_error('File does not have var: '+var+' ...')
            if input_is_file then cdf_close, cdfid
            return
        endif
    endif

    cdf_control, cdfid, get_numattrs=natt
    natt = total(natt)
    if natt eq 0 then return

    the_other_mode = vatt_mode? 'G': 'V'
    for ii=0, natt-1 do begin
        cdf_attinq, cdfid, ii, attname, scope, foo
        if strmid(scope,0,1) eq the_other_mode then continue
        if the_key ne attname then continue
        if vatt_mode then begin
            cdf_attdelete, cdfid, the_key, var, zvariable=iszvar
        endif else begin
            cdf_attdelete, cdfid, the_key
        endelse
        break
    endfor
    
    if input_is_file then cdf_close, cdfid

end
