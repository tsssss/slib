;+
; Print skeleton to file or console.
; To replace snetcdfsktlpr.
;-

pro netcdf_print_skeleton, skeleton, filename=out_file

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
    printf, lun, str_enter

    printf, lun, '#header'
    printf, lun, str_enter
    tformat = '(A, T6, A, T16, A)'
    printf, lun, '!', 'G.Atts', 'Vars', format=tformat
    printf, lun, '!', '------', '----', format=tformat

    ngatt = skeleton.header.ngatt
    nvar = skeleton.header.nvar
    tformat = '(T6, I0, T16, I0)'
    printf, lun, ngatt, nvar, format=tformat
    printf, lun, str_enter


;---Global attribute.
    if ngatt gt 0 then begin
        printf, lun, str_enter
        printf, lun, '# Global Attribute'
        printf, lun, str_enter
        gatt = skeleton.setting
        foreach key, gatt.keys(), ii do begin
            printf, lun, string(ii,format='(I4)')+' '+key, ': ', gatt[key]
        endforeach
        printf, lun, str_enter
    endif


;---Variables.
    if nvar gt 0 then begin
        printf, lun, str_enter
        printf, lun, '# Variable'
        printf, lun, str_enter
        
        vars = skeleton.var
        foreach key, vars.keys(), ii do begin
            var = vars[key]
            printf, lun, ii, var.name, format='(I4, " ", A)'
            printf, lun, str_enter
            tformat = '("!", T6, A, T20, A)'
            printf, lun, format=tformat, 'Data Type', 'Dimensions'
            printf, lun, format=tformat, '---------', '----------'
            printf, lun, format=tformat, var.datatype, strjoin(string(var.dims,format='(I0)'),', ')
            printf, lun, str_enter
            tformat = '(T6, A, T40, A)'
            ; variable attribute.
            vatt = var.setting
            if n_elements(vatt) eq 0 then continue
            foreach key, vatt.keys() do begin
                printf, lun, key, string(vatt[key]), format=tformat
            endforeach
        endforeach
    endif

    if lun ne -1 then free_lun, lun

end