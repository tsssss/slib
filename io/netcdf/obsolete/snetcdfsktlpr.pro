pro snetcdfsktlpr, skt, fn

    compile_opt idl2
    on_error, 0
    
    if n_elements(skt) eq 0 then return
    
    ; output to console or file.
    if n_elements(fn) ne 0 then openw, lun, fn, /get_lun else lun = -1
    
    enter = ''


;---Header.
    printf, lun, '! Skeleton table for file: "'+skt.name+'"'
    printf, lun, '! Generated: '+systime()
    printf, lun, enter
    
    printf, lun, '# Header'
    printf, lun, enter
    tformat = '(A, T6, A, T16, A)'
    printf, lun, '!', 'G.Atts', 'Vars', format=tformat
    printf, lun, '!', '------', '----', format=tformat
    
    ngatt = skt.header.ngatt
    nvar = skt.header.nvar
    tformat = '(T6, I0, T16, I0)'
    printf, lun, ngatt, nvar, format=tformat
    printf, lun, enter
    
    
;---Global attribute.
    if ngatt gt 0 then begin
        printf, lun, enter
        printf, lun, '# Global Attribute'
        printf, lun, enter
        gatts = skt.gatts
        for ii=0, ngatt-1 do begin
            gatt = gatts.(ii)
            printf, lun, string(ii,format='(I4)')+' '+gatt.name, ': ', gatt.value
        endfor
        printf, lun, enter
    endif
    

;---Variables.
    if nvar gt 0 then begin
        printf, lun, enter
        printf, lun, '# Variable'
        printf, lun, enter
        
        vars = skt.vars
        for ii=0, nvar-1 do begin
            var = vars.(ii)
            printf, lun, ii, var.name, format='(I4, " ", A)'
            printf, lun, enter
            tformat = '("!", T6, A, T20, A)'
            printf, lun, format=tformat, 'Data Type', 'Dimensions'
            printf, lun, format=tformat, '---------', '----------'
            printf, lun, format=tformat, var.datatype, strjoin(string(var.dims,format='(I0)'),', ')
            printf, lun, enter
            tformat = '(T6, A, T40, A)'
            if var.natt gt 0 then begin
                vatts = var.atts
                for jj=0, var.natt-1 do begin
                    vatt = vatts.(jj)
                    printf, lun, vatt.name, string(vatt.value), format=tformat
                endfor
            endif
        endfor
    endif
end