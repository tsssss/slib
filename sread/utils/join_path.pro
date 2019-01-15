;+
; Join the paths with the proper separator.
;-
;
function join_path, paths
    sep = path_sep()
    return, strjoin(paths,'/')
end

print, join_path(['','Users','Sheng','Downloads'])
end