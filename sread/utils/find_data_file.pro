;+
; Find data file according to given time and pattern. Return '' if no file is found.
; 
; time. A time or a time range in ut time.
; patterns. An array of 3 strings: [base, local, remote] patterns.
; index_file. A string for the basename of the index file. Default is 'remote-index.html'
; file_cadence. A number specifies the cadence of data files. Default is 86400.
;   Or a string specifies the cadence, 'month', 'year'.
; threshold. A number in sec. For files within this amount of time from now,
;   they are synced with the remote server; otherwise the files are assumed to
;   be early enough that they are not updated remotely.
; files. A string or an array of full file names.
;-
function find_data_file, time, patterns, index_file, $
    file_cadence=file_cadence, threshold=threshold, files=files, month=month
    
    nfile = n_elements(files)
    if nfile eq 0 then begin
        times = break_down_times(time, file_cadence)
        
        ; replace pattern with times.
        basenames = apply_time_to_pattern(patterns[0], times)
        local_paths = apply_time_to_pattern(patterns[1], times)
        remote_paths = apply_time_to_pattern(patterns[2], times)
        
        ; if a local index file does not exist, download from remote.
        ; otherwise if the local index file is old, sync with remote.
        ; if remote index file does not exist, leave local index file non-exist.
        update_index_file, index_file, local_paths, remote_paths, $
            threshold=threshold, times=times
        
        ; look up the local index file to find the highest version file.
        ; if local index file doesn't exist, basename would be ''.
        basenames = lookup_index_file(basenames, local_paths, index_file)
        
        ; get file.
        update_data_file, basenames, local_paths, remote_paths, $
            threshold=threshold
        
        idx = where(basenames ne '', nfile)
        if nfile eq 0 then return, ''

        files = strarr(nfile)
        for i=0, nfile-1 do files[i] = join_path([local_paths[idx[i]], basenames[idx[i]]])
    endif
    
    flags = bytarr(nfile)
    for i=0, nfile-1 do flags[i] = file_test(files[i])
    idx = where(flags eq 1, nfile)
    if nfile eq 0 then return, '' else files = files[idx]
    
    ; only return unique files, do not sort b/c it may break the time order.
    files = files[uniq(files)]
    return, files
end
