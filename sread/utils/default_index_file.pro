;+
; Return a string for the default index file.
; By default this is the local index file.
;
; sync=. A boolean. Set it for storing the remote index file.
;-
;
function default_index_file, sync=sync
    index_file = 'local_index.html'
    if keyword_set(sync) then index_file = 'remote_index.html'
    return, index_file
end