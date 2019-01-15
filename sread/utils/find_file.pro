;+
; Smart find file using time and patterns for the base name, local path, etc.
; 
; The program deals with only one time, and thus only one file at once.
; First, the program determines to find files locally or remotely. Find file
; locally if no remote_pattern, no internet connection, or local_only is set.
; 
; Searching locally will search files using regular expression and return the
; file exists on disk at the highest version.
; 
; Searching remotely will sync the index file if download_index is set, or
; the index file doesn't exist. Then the program will lookup the index file 
; and choose the file of the highest version. With this information, the 
; program determines to sync the file with remote server or not. Sync if 
; local file does not exist, or local file is older or different in file size,
; or syn_data_file is set.
; 
; time. A number for unix time in sec.
; base_pattern. A string for base file name.
; local_pattern. A string for local path.
; remote_pattern. A string for remote path. Set it to trigger sync with server.
; index_file. A string for base file name of the index file, which contains
;   all file names under the current folder.
; local_only. A boolean, set it to stay local.
; download_file. A boolean, set it to force sync file. Have effect when
;   local_only = 0.
; skip_index. A boolean, set it to skip looping up the index file.
; download_index. A boolean, set it to force sync index file. Have effect
;   when local_only = 0 and skip_index = 0.
;-
;

function find_file, time, base_pattern, local_pattern, $
    remote_pattern=remote_pattern, index_file=index_file, $
    local_only=local_only, skip_index=skip_index, errmsg=errmsg, $
    download_index=download_index, download_file=download_file
    
    
;---Check input.
    if n_elements(time) ne 1 then begin
        errmsg = handle_error('Wrong input time ...')
        return, ''
    endif
    
    if n_params() ne 3 then begin
        errmsg = handle_error('No input pattern for base name or local path ...')
        return, ''
    endif
    
    
;---Decide to go with local or remote.
    if keyword_set(local_only) then begin
        stay_local = local_only
    endif else begin
        stay_local = 1
        ; If remote_pattern is provided, then we go with remote.
        if n_elements(remote_pattern) ne 0 then begin
            stay_local = 0
            ; Stay local if remote_pattern is invalid.
            if remote_pattern[0] eq '' then stay_local = 1
            ; Stay local if no internet connection to the remove server.
            if check_internet_connection(remote_pattern) eq 0 then stay_local = 1
        endif
    endelse
    
    
;---Find file locally or remotely.
    basefn = apply_time_to_pattern(base_pattern, time)
    locdir = apply_time_to_pattern(local_pattern, time)
    idxbfn = (n_elements(index_file) eq 0)? default_index_file(): index_file[0]
    idxffn = join_path([locdir,idxbfn]) ; full file name.
    if stay_local then begin
        lprmsg, 'Searching for "'+basefn+'" in "'+locdir+'" ...'
        fullfn = join_path([locdir,basefn])
        if file_test(fullfn) eq 1 then return, fullfn
        
        ; No further search option is available.
        if keyword_set(skip_index) then begin
            errmsg = handle_error('Cannot locally find file: '+fullfn+' ...')
            return, ''
        endif
        
        ; Prepare index file.
        if file_test(idxffn) eq 0 then begin
            lprmsg, 'Preparing index file "'+idxffn+'" ...'
            idxold = join_path([locdir,'.remote-index.html'])
            if file_test(idxold) eq 1 then begin
                file_copy, idxold, idxffn
                file_delete, idxold
            endif else make_index_file, idxffn
        endif
        fullfn = join_path([locdir,basefn])
        if file_test(idxffn) eq 0 then begin
            errmsg = handle_error('No index file is found ...')
            return, ''
        endif
        ; Look up files in the index file.
        lprmsg, 'Looking up "'+basefn+'" in "'+idxbfn+'" ...'
        files = lookup_index_file(basefn, locdir, idxbfn)
        nfile = n_elements(files)
        if nfile eq 1 then begin
            if files[0] eq '' then begin
                errmsg = handle_error('No file is found in index file ...')
                return, ''
            endif
            fullfn = join_path([locdir,files[0]])
        endif else begin
            index = sort(files)
            fullfn = join_path([locdir,files[idx[nfile-1]]])
        endelse
        return, fullfn
        
    endif else begin
        remdir = apply_time_to_pattern(remote_pattern, time)
        lprmsg, 'Searching for "'+basefn+'" from "'+remdir+'" ...'
        
        if keyword_set(skip_index) then begin
            ; To make this works, the base name must be explicit.
            locffn = join_path([locdir,basefn])
            remffn = join_path([remdir,basefn])
        endif else begin
            ; Lookup the index file to find the base name.
            ; Prepare the index file.
            sync_index = 0
            if keyword_set(download_index) then begin
                sync_index = download_index
            endif else begin
                if file_test(idxffn) eq 0 then begin
                    idxold = join_path([locdir,'.remote-index.html'])
                    if file_test(idxold) eq 1 then begin
                        file_copy, idxold, idxffn
                        file_delete, idxold
                    endif else sync_index = 1
                endif
            endelse
            
            if sync_index then begin
                lprmsg, 'Syncing "'+idxbfn+'" from "'+remdir+'" ...'
                update_index, idxbfn, locdir, remdir
            endif
            
            lprmsg, 'Looking up "'+basefn+'" in "'+idxbfn+'" ...'
            files = lookup_index_file(basefn, locdir, idxbfn)
            nfile = n_elements(files)
            if nfile eq 1 then begin
                if files[0] eq '' then begin
                    errmsg = handle_error('No file is found in index file ...')
                    return, ''
                endif
                file = files[0]
            endif else begin
                index = sort(files)
                file = files[idx[nfile-1]]
            endelse
            
            locffn = join_path([locdir,file])
            remffn = join_path([remdir,file])
        endelse
        
        ; now we have file, which is the final base name.
        ; Determine whether to download the file or not.
        sync_file = 0
        if keyword_set(download_file) then begin
            sync_file = download_file
        endif else begin
            remote_info = get_remote_info(remffn)
            if file_test(locffn) eq 0 then begin
                sync_file = 1
            endif else begin
                local_info = file_info(locffn)
                if remote_info.size ne local_info.size then sync_file = 1
                if remote_info.mtime gt local_info.mtime then sync_file = 1
            endelse
        endelse
        if sync_file then begin
            download_file, locffn, remffn
            fix_mtime, locffn, remote_info.mtime
            return, locffn[0]
        endif
        if file_test(locffn) eq 1 then return, locffn[0]
        ; program shouldn't really reach here.
        errmsg = handle_error('Unknown error in syncing from remote ...')
        return, ''
    endelse
    
end

time = time_double('2014-08-27/08:00')
local_pattern = '/Volumes/Research/data/themis/thg/l1/asi/atha/%Y/%m'
base_pattern = 'thg_l1_asf_atha_%Y%m%d%H_v01.cdf'
remote_pattern = 'http://themis.ssl.berkeley.edu/data/themis/thg/l1/asi/atha/%Y/%m'
print, find_file(time, base_pattern, local_pattern)
print, find_file(time, base_pattern, local_pattern, remote_pattern=remote_pattern)
end