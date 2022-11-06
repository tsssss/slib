;+
; Return a dictionary of settings.
; 
; var.
; filename=.
;-
function cdf_read_setting, var, filename=cdf0, errmsg=errmsg

    errmsg = ''
    retval = hash()

    ; Check if return vatt or gatt.
    vatt_mode = n_elements(var) gt 0
    if vatt_mode then return, cdf_read_var_att(var, filename=cdf0, errmsg=errmsg)


    ; Check if given file is a cdf_id or filename.
    if n_elements(cdf0) eq 0 then begin
        errmsg = handle_error('No input file ...')
        return, retval
    endif
    input_is_file = size(cdf0, /type) eq 7
    if input_is_file then begin
        file = cdf0
        if file_test(file) eq 0 then begin
            errmsg = handle_error('Input file does not exist ...')
            return, retval
        endif
        cdfid = cdf_open(file)
    endif else begin
        cdfid = cdf0
    endelse

    cdf_control, cdfid, get_numattrs=natt
    natt = total(natt)
    for ii=0, natt-1 do begin
        cdf_attinq, cdfid, ii, attname, scope, foo
        if strmid(scope,0,1) eq 'V' then continue
        cdf_control, cdfid, attribute=attname, get_attr_info=attinfo
        val = list()
        maxentrys = attinfo.maxgentry
        for jj=0, maxentrys do begin
            if ~cdf_attexists(cdfid, attname, jj) then continue
            cdf_attget, cdfid, attname, jj, tval
            val.add, tval
        endfor
        val = val.toarray()
        if n_elements(val) eq 1 then val = val[0]
        retval[attname] = val
    endfor

    if input_is_file then cdf_close, cdfid
    return, retval
end
