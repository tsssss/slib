;+
; A wrapper for file_unzip. Change interface to funzip, source, desitnation.
;-

pro funzip, infiles, outfiles, _extra=extra
    errmsg = ''

    ninfile = n_elements(infiles)
    if n_elements(outfiles) ne ninfile then begin
        errmsg = handle_error('Inconsistent in and out files ...')
        return
    endif

    file_unzip, infiles, _extra=extra
    for ii=0, ninfile-1 do file_move, infiles[ii], outfiles[ii], /overwrite, /allow_same

end