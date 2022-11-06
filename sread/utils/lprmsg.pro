;+
; Print a message to console or a file.
; 
; Output to a file only if it is set and exists on disk.
;-
;
pro lprmsg, msg, file

    ; determine if output to console
    console = 1    
    if size(file,/type) eq 7 then console = (file_test(file) eq 0)? 1: 0
    
    if console then lun = -1 else openw, lun, file, /get_lun, /append
    printf, lun, msg
    if lun ne -1 then free_lun, lun

end