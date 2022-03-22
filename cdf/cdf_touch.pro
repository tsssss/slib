;+
; Create an empty cdf file.
;
;-

pro cdf_touch, cdf0, _extra=ex

    ; Check if given file is a cdf_id or filename.
    if n_elements(cdf0) eq 0 then begin
        errmsg = handle_error('No input file ...')
        return
    endif

;---Default settings.
    col_major = 1   ; SPDF likes column major, by default is row major.

    input_is_file = size(cdf0, /type) eq 7
    if input_is_file then begin
        file = cdf0
        path = fgetpath(file)
        if file_test(file) eq 0 then begin
            if file_test(path,/directory) eq 0 then file_mkdir, path
            cdfid = cdf_create(file, $
                col_major=col_major, _extra=ex)
        endif
    endif else cdfid = cdf0

    if input_is_file then cdf_close, cdfid

end
