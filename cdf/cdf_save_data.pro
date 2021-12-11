;+
; Save given data to given var. This is essentially a shortcut for cdf_varput.
; This just change the data saved in some existing var.
; 
; varname.
; value=.
; filename=.
;-

pro cdf_save_data, varname, value=data, filename=cdf0

    compile_opt idl2
    catch, error
    if error ne 0 then begin
        catch, /cancel
        errmsg = handle_error(!error_state.msg, cdfid=cdfid)
        return
    endif


    ; Check if var is a string.
    if n_elements(varname) eq 0 then begin
        errmsg = handle_error('No input var name ...')
        return
    endif
    the_var = varname[0]

    ; Check if given file is a cdf_id or filename.
    if n_elements(cdf0) eq 0 then begin
        errmsg = handle_error('No input file ...')
        return
    endif
    input_is_file = size(cdf0, /type) eq 7
    if input_is_file then begin
        file = cdf0
        path = fgetpath(file)
        if file_test(file) eq 0 then begin
            errmsg = handle_error('Input file does not exist ...')
            return
        endif else cdfid = cdf_open(file)
    endif else cdfid = cdf0


    ; Save data.
    if ~cdf_has_var(the_var, filename=cdfid, iszvar=iszvar) then begin
        errmsg = handle_error('Input var does not exist ...')
    endif else begin
        cdf_varput, cdfid, the_var, data, zvariable=iszvar
    endelse

    if input_is_file then cdf_close, cdfid

end
