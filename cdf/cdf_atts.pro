;+
; Return all attributes in the CDF file.
;-
function cdf_atts, cdf0, errmsg=errmsg

    errmsg = ''
    retval = ''

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
    attnames = list()
    for ii=0, natt-1 do begin
        cdf_attinq, cdfid, ii, attname, scope, foo
        attnames.add, attname
    endfor

    if input_is_file then cdf_close, cdfid
    if n_elements(attnames) eq 0 then return, retval
    return, attnames.toarray()

end
