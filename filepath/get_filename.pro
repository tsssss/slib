;+
; Get the file name of the current routine.
;-

function get_filename

    sep = path_sep()

    calls = scope_traceback(/struct)
    ncall = n_elements(calls)
    
    if ncall lt 2 then begin
        file = !dir     ; calls from $MAIN.
    endif else begin
        file = calls[ncall-2].filename
    endelse

    return, file

end


fn = get_filename()
print, fn
end