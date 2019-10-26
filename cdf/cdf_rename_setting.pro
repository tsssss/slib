;+
; Rename the key of a setting.
;-
pro cdf_rename_setting, key, to=key1, varname=var, filename=cdf0, errmsg=errmsg

    errmsg = ''

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
            if file_test(path,/directory) eq 0 then file_mkdir, path
            cdfid = cdf_create(file)
        endif else cdfid = cdf_open(file)
    endif else cdfid = cdf0


    if n_elements(key) eq 0 then return
    the_key = key[0]
    if n_elements(key1) eq 0 then return
    new_key = key1[0]

    all_keys = cdf_atts(cdfid)
    index = where(all_keys eq the_key, count)
    if count eq 0 then begin
        errmsg = handle_error('File does not have setting: '+the_key+' ...')
        if input_is_file then cdf_close, cdfid
        return
    endif
    index = where(all_keys eq new_key, count)
    if count ne 0 then begin
        errmsg = handle_error('File already has new setting: '+new_key+' ...')
        if input_is_file then cdf_close, cdfid
        return
    endif

    cdf_attrename, cdfid, the_key, new_key
    if input_is_file then cdf_close, cdfid

end
