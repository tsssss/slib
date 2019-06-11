;+
; Join the paths with the proper separator.
;-
;
function join_path, paths
    return, strjoin(paths,path_sep())
end

print, join_path(['','Users','Sheng','Downloads'])
end