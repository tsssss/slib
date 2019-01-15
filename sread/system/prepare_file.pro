;+
; Do a smart search of fils for <mission>_read_<instrument>.
; 
; If files are not provided, find them using file_times and patterns,
; and an index file. If file_times is not given, we find it using 
; time and cadence.
;-


function prepare_file, files=files, errmsg=errmsg, $
    file_times=file_times, time=time, cadence=cadence, $
    base_pattern=base_pattern, local_paths=local_paths, index_file=index_file, $
    stay_local=stay_local, remote_paths=remote_paths, $
    sync_index=sync_index, skip_index=skip_index, $
    sync_files=sync_files, sync_after=sync_time
    
    nfile = n_elements(files)
    if nfile ne 0 then begin
        flags = bytarr(nfile)
        for i=0, nfile-1 do flags[i] = file_test(files[i])
        index = where(flags ne 0, count)
        if count eq 0 then begin
            errmsg = handle_error('No file is found ...')
            return, ''
        endif
        return, files[index]
    endif

    
;---Find files using file_times and patterns.
    lprmsg, 'Find files using file times and patterns ...'
    
;---Prepare file_times.
    if n_elements(file_times) eq 0 then begin
        ; Find file_times using time and cadence.
        lprmsg, 'Find file times using input time and cadence ...'
        if n_elements(time) eq 0 then begin
            errmsg = handle_error('No input time ...')
            return, ''
        endif
        if n_elements(cadence) eq 0 then cadence = 'day'
        file_times = break_down_times(time, cadence)
    endif
    
    ; Prepare patterns.
    if n_elements(base_pattern) eq 0 then begin
        errmsg = handle_error('No input pattern for base names ...')
        return, ''
    endif
    if n_elements(local_paths) eq 0 then begin
        errmsg = handle_error('No input pattern for local paths ...')
        return, ''
    endif
    if size(local_paths,/type) eq 10 then begin
        local_pattern = join_path(*local_paths)
    endif else begin
        local_pattern = join_path(local_paths)
    endelse
    
    ; Prepare index file.
    if n_elements(index_file) eq 0 then index_file = default_index_file()
    
;---Determine to stay local or sync with the remote server.
    if keyword_set(stay_local) then begin
        local_only = 1
    endif else begin
        if n_elements(remote_paths) eq 0 then begin
            local_only = 1
        endif else begin
            if size(remote_paths,/type) eq 10 then begin
                remote_pattern = join_path(*remote_paths)
            endif else begin
                remote_pattern = join_path(remote_paths)
            endelse
            local_only = check_internet_connection(remote_pattern) eq 0
        endelse
    endelse
    
;---Prepare index file.
    if ~keyword_set(skip_index) then begin
        nfile_time = n_elements(file_times)
        loc_paths = strarr(nfile_time)
        for i=0, nfile_time-1 do loc_paths[i] = apply_time_to_pattern(local_pattern, file_times[i])
        index = uniq(local_paths)
        loc_paths = loc_paths[index]
        nloc_path = n_elements(loc_paths)
        index_ffns = strarr(nloc_path)
        for i=0, nloc_path-1 do index_ffns[i] = join_path([loc_paths[i],index_file])
        
    ;---Find locally, if it doesn't exist, then make one using existing files.
        if local_only then begin
            for i=0, nloc_path-1 do begin
                if file_test(index_ffns[i]) eq 0 then continue
                make_index_file, index_ffn[i]
            endfor
    ;---Sync with remote.
        endif else begin
            rem_paths = strarr(nfile_time)
            for i=0, nfile_time-1 do rem_paths[i] = apply_time_to_pattern(remote_pattern, file_times[i])
            rem_paths = rem_paths[index]
            for i=0, nloc_path-1 do begin
                download_index = 0
                if file_test(index_ffns[i]) eq 0 then download_index = 1
                if keyword_set(sync_index) then download_index = 1
                if ~download_index then continue
                ; Download the html by default, in other case,
                ; usually download the checksum file.
                if index_file ne default_index_file() then begin
                    rem_ffn = join_path(rem_paths[i],index_file)
                endif else begin
                    rem_ffn = rem_paths[i]
                endelse
                download_file, index_ffns[i], rem_ffn
            endfor
        endelse
    endif
    
;---Find files with file_times, patterns, and index_file.
    files = strarr(nfile_time)
    if n_elements(sync_time) eq 0 then sync_time = systime(1)-86400d*365.25
    for i=0, nfile_time-1 do begin
        file_time = file_times[i]
        download_file = file_time gt sync_time
        files[i] = find_file(file_time, base_pattern, local_pattern, $
            remote_pattern=remote_pattern, index_file=index_file, $
            download_file=download_file, local_only=local_only)
    endfor
    
    return, files
    
end