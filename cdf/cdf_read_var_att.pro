;+
; Return a dict of atttribute of given variable.
;
; var. A string for var name.
; filename. A string for file name or a cdfid.
;-

function cdf_read_var_att, var, filename=cdf0, errmsg=errmsg

    errmsg = ''
    retval = dictionary()


    ; Check if var is a string.
    if n_elements(var) eq 0 then return, retval
    the_var = var[0]

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

    ; No var is found.
    if ~cdf_has_var(the_var,filename=cdf0) then begin
        errmsg = handle_error('File does not have var: '+var+' ...')
        if input_is_file then cdf_close, cdfid
        return, retval
    endif

    vatt = dictionary()
    cdf_control, cdfid, get_numattrs=natt
    natt = total(natt)
    for ii=0, natt-1 do begin
        cdf_attinq, cdfid, ii, attname, scope, foo
        if strmid(scope,0,1) eq 'G' then continue
        if ~cdf_attexists(cdfid, attname, the_var) then continue
        cdf_attget, cdfid, attname, the_var, value
        vatt[strtrim(attname,2)] = value
    endfor

    if input_is_file then cdf_close, cdfid
    return, vatt
end
