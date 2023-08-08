function get_fid, id0, input_is_file=input_is_file, $
    errmsg=errmsg, file_open_routine=file_open_routine, _extra=ex

    errmsg = ''
    retval = !null

    if n_elements(id0) eq 0 then begin
        errmsg = handle_error('No input file ...')
        return, retval
    endif

    input_is_file = size(id0, type=1) eq 7
    if input_is_file then begin
        file = id0
        if file_test(file) eq 0 then begin
            errmsg = handle_error('Input file does not exist ...')
            return, retval
        endif
        if n_elements(file_open_routine) eq 0 then begin
            errmsg = handle_error('No file_open_routine ...')
            return, retval
        endif
        known_routines = ['cdf_open','h5f_open','ncdf_open']
        index = where(known_routines eq strlowcase(file_open_routine), count)
        if count eq 0 then begin
            errmsg = handle_error('Unkown file_open_routine: '+file_open_routine+' ...')
            return, retval
        endif
        fid = call_function(file_open_routine, file, _extra=ex)
    endif else begin
        fid = id0
    endelse

    return, fid

end