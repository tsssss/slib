;+
; Sync the index file with remote server.
; 
; index_file. A string of the base file name of the index file.
; local_path. A string of the local full path of the index file.
; remote_path. A string of the remote URL.
;-
pro update_index, index_file, local_path, remote_path, errmsg=errmsg

    local_index = join_path([local_path, index_file])
    if file_test(local_path,/directory) eq 0 then file_mkdir, local_path

    if index_file eq 'remote-index.html' then begin ; is a remote "folder".
        if strmid(remote_path,0,1,/reverse) ne '/' then remote_path += '/'
        scurl, remote_path, local_index, errmsg=errmsg
    endif else download_file, local_index, join_path([remote_path, index_file])

end