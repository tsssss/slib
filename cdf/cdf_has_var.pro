;+
; Return a flag for if a given variable is in the file.
; var. A string for filename.
; filename=. A string for a CDF file.
; iszvar=. A boolean for output.
;-
function cdf_has_var, var, filename=cdf0, iszvar=iszvar, errmsg=errmsg

    errmsg = ''
    retval = 0

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

    ; Loop through variables in the file.
    cdfinq = cdf_inquire(cdfid)
    nzvar = cdfinq.nzvars
    for ii=0, nzvar-1 do begin
        varinq = cdf_varinq(cdfid, ii, zvariable=1)
        if varinq.name eq the_var then begin
            iszvar = 1
            if input_is_file then cdf_close, cdfid
            return, 1
        endif
    endfor

    nrvar = cdfinq.nvars
    for ii=0, nrvar-1 do begin
        varinq = cdf_varinq(cdfid, ii, zvariable=0)
        if varinq.name eq the_var then begin
            iszvar = 0
            if input_is_file then cdf_close, cdfid
            return, 1
        endif
    endfor

end
