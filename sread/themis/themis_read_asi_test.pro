
pro themis_read_asi_test, time, files=files, file_times=file_times

;---Constants.
    secofday = 86400d
    
    
;---Information for later steps.
    time = time_double('2006-01-01/01:00')
    site = 'atha'
    time = time_double(['2014-08-28/10:00','2014-08-28/10:03'])
    site = 'whit'
    ;time = time_double('2014-08-28/10:03')
    ;site = 'whit'

    time_type = default_time_type()
    time_var = 'thg_asf_'+site+'_time'
    time_var_type = 'unix'
    in_vars = ['thg_asf_'+site]
    out_vars = ['thg_'+site+'_asf']
    local_root = join_path([default_local_root(),'data','themis','thg'])
    remote_root = 'http://themis.ssl.berkeley.edu/data/themis/thg'
    base_pattern = 'thg_l1_asf_'+site+'_%Y%m%d%H_v[0-9]{2}.cdf'
    local_paths = ptr_new([local_root,'l1','asi',site,'%Y','%m'])
    remote_paths = ptr_new([remote_root,'l1','asi',site,'%Y','%m'])
    local_pattern = join_path(*local_paths)
    remote_pattern = join_path(*remote_paths)
    cadence = 'hour'

    ; Times used to search files.
    if n_elements(file_times) eq 0 then begin
        file_times = break_down_times(time, cadence)
    endif
    nfile_time = n_elements(file_times)
    
    ; A time threshold. For file time before this time (old files),
    ; if a file exists locally, then it is assumed to be synced with server.
    if n_elements(sync_threshold) eq 0 then begin
        sync_threshold = systime(/second)-365*secofday
    endif
    
    if n_elements(index_file) eq 0 then index_file = default_index_file()
    
    ; A flag, stay local if there is no remote pattern, or if there is no
    ; connection to the server.
    if n_elements(remote_pattern) eq 0 then remote_pattern = ''
    if remote_pattern eq '' then local_only = 1 else begin
        local_only = (check_internet_connection(remote_pattern) eq 0)? 1: 0
    endelse

    
;---Update index file, only for smart search.
;   Need file_times, base_pattern, index_file, local_only.
    nfile = n_elements(files)
    if nfile eq 0 then begin
        local_paths = strarr(nfile_time)
        for i=0, nfile_time-1 do local_paths[i] = apply_time_to_pattern(local_pattern, file_times[i])
        remote_paths = strarr(nfile_time)
        for i=0, nfile_time-1 do remote_paths[i] = apply_time_to_pattern(remote_pattern, file_times[i])
    endif
    index = uniq(local_paths)
    local_paths = local_paths[index]
    remote_paths = remote_paths[index]
    nlocal_path = n_elements(local_paths)
    for i=0, nlocal_path-1 do begin
        if local_only then begin
            ; There is no remote server.
            if remote_pattern eq '' then begin
                index_ffn = join_path([local_paths[i],index_file])
                if file_test(index_ffn) eq 0 then begin
                    files = file_search(local_paths[i], '*')
                    openw, lun, index_ffn, /get_lun
                    printf, lun, files
                    free_lun, lun
                endif
            endif
        endif else begin
            download_file, join_path([local_paths[i],index_file]), remote_paths[i]
        endelse
    endfor
    
    
;---Find files. Need file_times, base_pattern, local_pattern.
;   Optional: remote_pattern, index_file, download_file, local_only.
;   Note: download_index is not needed since we've updated index files.
    nfile = n_elements(files)
    if nfile eq 0 then begin
        files = strarr(nfile_time)
        for i=0, nfile_time-1 do begin
            file_time = file_times[i]
            download_file = (file_time le sync_threshold)? 0: 1
            files[i] = find_file(file_time, base_pattern, local_pattern, $
                remote_pattern=remote_pattern, index_file=index_file, $
                download_file=download_file, local_only=local_only)
        endfor
        nfile = n_elements(files)
    endif
    
    flags = bytarr(nfile)
    for i=0, nfile-1 do flags[i] = file_test(files[i])
    index = where(flags eq 1, nfile)
    if nfile eq 0 then begin
        errmsg = handle_error('No file is found ...')
        return
    endif
    files = files[index]
    
;---Read variables. Need files, in_vars,
;   Optional: time, time_var, time_var_type

    ; Coerce to nptr_dat, dep_vars, indp_var.
    if n_elements(time_var) eq 0 then begin
        nptr_dat = n_elements(in_vars)
        dep_vars = in_vars
        indp_var = []
    endif else begin
        index = where(in_vars ne time_var, count)
        indp_var = time_var[0]
        dep_vars = in_vars[index]
        nptr_dat = count+1
    endelse
    ndep_var = n_elements(dep_vars)
    
    ; Find a rec_infos using time info.
    rec_infos = intarr(nfile,2)-1
    check_rec_info = n_elements(time) ne 0 and $
        n_elements(time_var) ne 0 and n_elements(time_var_type) ne 0
    if check_rec_info then begin
        time_info = convert_time(time, from=time_type, to=time_var_type)
        ptr_times = read_data(files, time_var, errmsg=errmsg, /no_merge)
        times = []
        time_ranges = dblarr(nfile,2)
        for i=0, nfile-1 do begin
            tmp = *ptr_times[i]
            times = [times,tmp]
            time_ranges[i,*] = [tmp[0],tmp[-1]]
        endfor
        if n_elements(time_info) eq 1 then begin
            tmp = min(times-time_info[0], index, /absolute)
            rec_infos[*] = index
        endif else begin
            time_ranges = time_info[1]<time_ranges>time_info[0]
            for i=0, nfile-1 do begin
                index = where(times ge time_ranges[i,0] and times le time_ranges[i,1], count)
                rec_infos[i,*] = index[0]+[0,count]
            endfor
            ; Deal with when files connect.
            for i=1, nfile-1 do $
                if time_range[i-1,1] eq time_range[i,0] then rec_infos[i,1] += 1
        endelse
        times = read_data(files, time_var, rec_info=rec_infos, /data, errmsg=errmsg)
    endif
    
    ptr_dats = ptrarr(ndep_var)
    for i=0, ndep_var-1 do ptr_dats[i] = read_data(files, dep_vars[i], rec_info=rec_infos, errmsg=errmsg)
    
;---Save variables.
; Now we have ptr_dats, and maybe times.
    if n_elements(times) eq 0 then begin
        for i=0, ndep_var-1 do begin
            store_data, dep_vars[i], temporary(*ptr_dats[i])
            ptr_free, ptr_dats[i]
        endfor
    endif else begin
        times = convert_time(times, from=time_var_type, to=time_type)
        for i=0, ndep_var-1 do begin
            store_data, dep_vars[i], times, temporary(*ptr_dats[i])
            ptr_free, ptr_dats[i]
        endfor
    endelse

end