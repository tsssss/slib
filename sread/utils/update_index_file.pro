;+
; Smart version of sync the local index file with remote server.
;   1. Set update_all to sync all index files.
;   2. Otherwise
;       a. Set times and threshold to update the index files that are "new".
;       b. Otherwise update the index files that do not exist locally.
; If the local index file needs to be updated, download it from remote path.
; Then if remote index is not found, this program returns no local index.
; 
; index_file. A string of the base file name of the index file,
;   e.g., 'remote-index.html', 'SHA1SUM'.
; local_paths. A string or an array of N full paths to the index file.
; remote_paths. A string or an array of N URL of the index file.
; update_all. A boolean sets whether to sync all index files or not.
; times. A time or an array of times in utsec. The time is when the index file
;   is supposed to be updated.
; threshold. A number in second. For files within this amount of time from now,
;   they are synced with the remote server; otherwise the files are assumed to
;   be early enough that they are not updated remotely.
;-
pro update_index_file, index_file, local_paths, remote_paths, $
    update_all=update_all, threshold=threshold, times=times, errmsg=errmsg
    
    nfile = n_elements(local_paths)
    if nfile eq 0 then message, 'No input paths ...'
    
    ; flag = [] means no file to be synced.
    ; otherwise, if flag is 1, the file needs to be synced.
    if keyword_set(update_all) then begin
        flag = []
    endif else begin
        flag = bytarr(nfile)
        ; 1: the file doesn't exist; 0: exists.
        for i=0, nfile-1 do flag[i] = ~file_test(join_path([local_paths[i],index_file]))
        ; 1: files are new, need to be synced; 0: old, do not change any more.
        if n_elements(threshold) ne 0 then begin
            if n_elements(times) eq nfile then $
                flag = flag or (times gt (systime(/second)-threshold))
                if n_elements(flag) eq 1 and flag[0] eq 0 then flag = []
        endif
    endelse
    
    if n_elements(flag) ne 0 then begin
        idx = where(flag eq 1, cnt)
        if cnt eq 0 then begin
            print, 'Local index files are up to date ...'
            return
        endif
        ; pick out the ones need sync.
        uniq_local_paths = local_paths[idx]
        uniq_remote_paths = remote_paths[idx]
        ; pick out unique paths.
        all_paths = uniq_local_paths+uniq_remote_paths
        idx = uniq(all_paths)
        uniq_local_paths = uniq_local_paths[idx]
        uniq_remote_paths = uniq_remote_paths[idx]
    endif else begin
        print, 'Local index files are up to date ...'
        return
    endelse
    
    nfile = n_elements(uniq_local_paths)
    errmsgs = ['404 Not Found']
    ; download each index file, check for error message.
    ; if error message is found, the index file is not what we want, delete it.
    for i=0, nfile-1 do begin
        print, 'Syncing index file '+index_file+' from '+uniq_remote_paths[i]+' to '+uniq_local_paths[i]+' ...'
        update_index, index_file, uniq_local_paths[i], uniq_remote_paths[i], errmsg=errmsg
        foreach errmsg, errmsgs do begin
            errmsg = lookup_index_file(errmsg, uniq_local_paths[i], index_file)
            if errmsg ne '' then begin
                file_delete, uniq_local_paths[i], /recursive
                errmsg = handle_error('Remote index file does not exist ...')
                break
            endif
        endforeach
    endfor
    
end
