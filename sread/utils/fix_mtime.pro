;+
; Change the file's last-modified time to given time in utsec.
; 
; file. A string of the file's full file name.
; mtime. A time in utsec.
;-
pro fix_mtime, file, mtime
    stouch, file, mtime=mtime
end