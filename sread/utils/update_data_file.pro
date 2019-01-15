;+
; Download data file if it doesn't exist locally, or if it is old and needs
; to be synced from the remote server.
; 
; Skip if a basename is ''.
;-

pro update_data_file, basenames, local_paths, remote_paths, $
    update_all=update_all, threshold=threshold
    
    nfile = n_elements(basenames)
    if nfile eq 0 then message, 'No input paths ...'
    
    if keyword_set(update_all) then begin
        for i=0, nfile-1 do begin
            if basenames[i] eq '' then continue
            print, 'Downloading file '+basenames[i]+' from '+remote_paths[i]+' to '+local_paths[i]+' ...'
            download_file, join_path([local_paths[i],basenames[i]]), join_path([remote_paths[i],basenames[i]])
        endfor
        return
    endif
    
    for i=0, nfile-1 do begin
        if basenames[i] eq '' then continue
        local_file = join_path([local_paths[i],basenames[i]])
        if file_test(local_file) eq 1 then begin
            print, 'Local file '+local_file+' exists ...'
            if n_elements(threshold) ne 0 then begin
                t0 = systime(/second)-threshold
                local_info = file_info(local_file)
                local_mtime = local_info.mtime
                local_fsize = local_info.size
                print, 'Local file is last modified at '+convert_time(local_mtime,from='unix',to='%Y-%m-%d/%H:%M:%S')+' ...'
                if local_mtime gt t0 then begin
                    url = join_path([remote_paths[i],basenames[i]])
                    remote_info = get_remote_info(url)
                    if (local_fsize lt remote_info.size) or (local_mtime lt remote_info.mtime) then begin
                        print, 'Local file needs to be synced to remote server ...'
                        print, 'Downloading file '+basenames[i]+' from '+remote_paths[i]+' to '+local_paths[i]+' ...'
                        download_file, local_file, url
                        fix_mtime, local_file, remote_info.mtime
                    endif else print, 'Local file is up to date ...'
                endif else print, 'Local file is up to date ...'
            endif else print, 'Local file is up to date ...'
        endif else begin
            print, 'Local file '+local_file+' does not exist ...'
            print, 'Downloading file '+basenames[i]+' from '+remote_paths[i]+' to '+local_paths[i]+' ...'
            download_file, join_path([local_paths[i],basenames[i]]), join_path([remote_paths[i],basenames[i]])
        endelse
    endfor
end