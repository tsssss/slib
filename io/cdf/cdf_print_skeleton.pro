;+
; Print skeleton to file or console.
;-

pro cdf_print_skeleton, skeleton, filename=out_file

    compile_opt idl2
    on_error, 0

    str_enter = ''     ; this works better than string(10B) or string(13B).
    if n_elements(out_file) ne 0 then begin
        path = fgetpath(out_file)
        if file_test(path,/directory) eq 0 then file_mkdir, path
        openw, lun, out_file, /get_lun
    endif else lun = -1       ; console's lun is -1.

;---Print header.
    printf, lun, '! Skeleton table for the "'+skeleton.name
    printf, lun, '! Generated: ' +systime()
    printf, lun, '! CDF version: ' +skeleton.header.version
    printf, lun, str_enter
    printf, lun, '#header'
    printf, lun, str_enter
    tformat = '(A, T16, A)'
    printf, lun, 'CDF NAME:', skeleton.name, format = tformat
    printf, lun, 'DATA ENCODING:', skeleton.header.encoding, format = tformat
    printf, lun, 'DATA DECODING:', skeleton.header.decoding, format = tformat
    printf, lun, 'MAJORITY:', skeleton.header.majority, format = tformat
    printf, lun, 'FORMAT:', skeleton.header.cdfformat, format = tformat
    printf, lun, str_enter
    tformat = '(A, T6, A, T16, A, T26, A, T36, A)'
    printf, lun, '!', 'R.Vars', 'Z.Vars', 'G.Atts', 'V.Atts', format = tformat
    printf, lun, '!', '------', '------', '------', '------', format = tformat

    ngatt = skeleton.header.ngatt
    nvatt = skeleton.header.nvatt
    nrvar = skeleton.header.nrvar
    nzvar = skeleton.header.nzvar
    nvar = nrvar+nzvar

    tformat = '(T6, I0, T16, I0, T26, I0, T36, I0)'
    printf, lun, nrvar, nzvar, ngatt, nvatt, format = tformat
    printf, lun, str_enter

;---Global attribute.
    if ngatt gt 0 then begin
        printf, lun, str_enter
        printf, lun, '#GLOBALattributes'
        printf, lun, str_enter
        gatt = skeleton.setting
        foreach key, gatt.keys(), ii do begin
            printf, lun, string(ii+1, format = '(I4)')+' '+$
                key, ': ', gatt[key]
        endforeach
        printf, lun, str_enter
    endif

;---Variables.
    if nvar gt 0 then begin
        printf, lun, str_enter
        printf, lun, '#Variables'
        printf, lun, str_enter
        vars = skeleton.var
        foreach key, vars.keys(), ii do begin
            var = vars[key]
            recvary = var.recvary? 'VARY': 'NOVARY'
            dimvary = strjoin(string(var.dimvary,format='(I0)'),', ')
            printf, lun, ii, var.name, format = '(I4, " ", A)'
            printf, lun, str_enter
            printf, lun, format = '("!", T6, "CDF Type", T20, "# Elem", T30,'+$
                '"Max Rec", T42, "Rec Vary", T55, "Dimensions", T70,"Dim Vary")'
            printf, lun, format = '("!", T6, "--------", T20, "------", T30,'+$
                '"-------", T42, "--------", T55, "----------", T70,"--------")'
            printf, lun, var.cdftype, var.nelem, var.maxrec, recvary, $
                strjoin(string(var.dims, format = '(I0)'), ', '), dimvary, $
                format = '(T6, A, T20, I0, T30, I0, T42, A, T55, A, T70, A)'
            printf, lun, str_enter
            ; variable attribute.
            vatt = var.setting
            if n_elements(vatt) eq 0 then continue
            foreach key, vatt.keys() do begin
                printf, lun, key, string(vatt[key]), $
                    format = '(T6, A, T40, A)'
            endforeach
            printf, lun, str_enter
        endforeach
    endif

    if lun ne -1 then free_lun, lun

end
