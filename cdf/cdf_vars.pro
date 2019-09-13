;+
; Return all variables in the CDF file.
;-
function cdf_vars, cdf0, errmsg=errmsg

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

    ; Loop through variables in the file.
    varnames = list()
    cdfinq = cdf_inquire(cdfid)
    nzvar = cdfinq.nzvars
    for ii=0, nzvar-1 do begin
        varinq = cdf_varinq(cdfid, ii, zvariable=1)
        varnames.add, varinq.name
    endfor

    nrvar = cdfinq.nvars
    for ii=0, nrvar-1 do begin
        varinq = cdf_varinq(cdfid, ii, zvariable=0)
        varnames.add, varinq.name
    endfor

    if input_is_file then cdf_close, cdfid
    if n_elements(varnames) eq 0 then return, retval
    return, varnames.toarray()

end
