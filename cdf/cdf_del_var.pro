;+
; Delete one variable in a on file.
;-
pro cdf_del_var, var, filename=cdf0, errmsg=errmsg


    errmsg = ''

    ; Check if var is a string.
    if n_elements(var) eq 0 then return
    the_var = var[0]

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

    ; Check if var exist.
    if ~cdf_has_var(var, filename=cdfid) then begin
        errmsg = handle_error('File does not have var: '+var+' ...')
        return
    endif

    ; Loop through variables in the file.
    cdfinq = cdf_inquire(cdfid)
    nzvar = cdfinq.nzvars
    for ii=0, nzvar-1 do begin
        varinq = cdf_varinq(cdfid, ii, zvariable=1)
        if varinq.name eq the_var then begin
            cdf_vardelete, cdfid, the_var, zvariable=1
            if input_is_file then cdf_close, cdfid
            return
        endif
    endfor

    nrvar = cdfinq.nvars
    for ii=0, nrvar-1 do begin
        varinq = cdf_varinq(cdfid, ii, zvariable=0)
        if varinq.name eq the_var then begin
            cdf_vardelete, cdfid, the_var, zvariable=1
            if input_is_file then cdf_close, cdfid
            return
        endif
    endfor


end
