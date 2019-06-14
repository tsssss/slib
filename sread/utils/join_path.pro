;+
; Join the paths with the proper separator.
;-
;
function join_path, paths
    return, strjoin(paths,'/')  ; use '/' instead of path_sep(), b/c windows now handles '/' well. On the other hand, '\' in URL causes trouble in downloading files.
end

print, join_path(['','Users','Sheng','Downloads'])
end