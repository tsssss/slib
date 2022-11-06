;+
; Delete one variable in a one file.
; 
; var. The variable.
; filename=. The file.
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
    if ~cdf_has_var(the_var, filename=cdfid, iszvar=iszvar) then begin
        errmsg = handle_error('File does not have var: '+the_var+' ...')
        return
    endif

    ; Loop through variables in the file.
    cdf_vardelete, cdfid, the_var, zvariable=iszvar
    if input_is_file then cdf_close, cdfid

end
