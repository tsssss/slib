
function download_recursively, local_path, remote_path, username=username, password=password, update=update
    compile_opt idl2

    if keyword_set(update) then file_delete, local_path, allow_nonexistent=1

    ; Determine if it is a file or directory.
    is_dir = strmid(local_path,0,1,reverse_offset=1) eq '/'

;---The path is a file, download and done.
    if not is_dir then begin
        local_file = local_path
        remote_file = remote_path
        if keyword_set(update) then file_delete, local_file, allow_nonexistent=1
        if file_test(local_file) eq 1 then return, 1
        download_file, local_file, remote_file, username=username, password=password
        return, 1
    endif


;---The path is a directory, obtain subdirectories and download them recursively.
    index_file = 'index.html'
    local_index_file = join_path([local_path,index_file])
    if file_test(local_index_file) eq 0 then begin
        remote_index_file = remote_path
        download_file, local_index_file, remote_index_file, username=username, password=password
    endif
    if file_test(local_index_file) eq 0 then return, 0
    subfiles = download_parse_subdirs(local_index_file)
    foreach subfile, subfiles do begin
        local_file = join_path([local_path,subfile])
        remote_file = join_path([remote_path,subfile])
        tmp = download_recursively(local_file, remote_file, username=username, password=password)
    endforeach
    
    return, 1

end






