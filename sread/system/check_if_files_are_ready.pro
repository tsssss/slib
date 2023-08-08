function check_if_files_are_ready, file_list, files=files

    files = list()
    foreach file_info, file_list do begin
        if size(file_info,type=1) eq 7 then begin
            if file_search(file_info) eq '' then return, 0
        endif else begin
            if n_elements(file_info.local_files) ne 1 then return, 0
            the_file = file_info.local_files[0]
            if file_search(the_file) eq '' then return, 0
        endelse
        files.add, the_file
    endforeach
    files = files.toarray()

    return, 1

end