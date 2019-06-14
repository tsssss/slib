;+
; Join the paths with the proper separator.
;-
;
function join_path, paths
    ; sep = path_sep()  ; In Windows, \ causes problem in downloading an URL.
    ; / is handled well in Windows now, so use it for all OS.
    return, strjoin(paths,'/')
end

print, join_path(['','Users','Sheng','Downloads'])
end
