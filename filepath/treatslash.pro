;+
; Replace '\' with '/'.
;
; dir. A string
;-
function treatslash, in_dirs
    if n_elements(in_dirs) eq 0 then return, !null

    dirs = in_dirs
    foreach dir, dirs, ii do begin
        pos = strpos(dir,'\')
        while pos ne -1 do begin
            dir = strmid(dir,0,pos)+'/'+strmid(dir,pos+1)
            pos = strpos(dir,'\')
        endwhile
        dirs[ii] = dir
    endforeach
    return, dirs

end
