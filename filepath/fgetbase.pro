;+
; Get the basename of a given full filename.
;-

function fgetbase, files
    return, file_basename(files)
end
