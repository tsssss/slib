;+
; This code is system dependent, rely on the request dictionary.
; Returns an array of strings of full file names that are locally exist.
;
; local_files. An array of strings. Set to fine tune the files for I/O.
;   Often, they are constructed from pattern containing format codes for
;   time and/or version.
;
;-


function prepare_files, request=request, errmsg=errmsg, $
    local_files=local_files, nonexist_files=nonexist_files, $
    file_times=file_times, time=time, cadence=cadence, version=version, $
    _extra=extra

    errmsg = ''
    retval = !null

;---Check inputs.
    if typename(request) ne strupcase('dictionary') then begin
        errmsg = handle_error('No input request ...')
        return, retval
    endif

    ; pattern are often set to automatically find files with time info,
    ; containing format codes for time and version.
    if ~request.haskey('pattern') then request.pattern = !null

    ; In most cases, data are organized by days.
    if n_elements(cadence) eq 0 then cadence = 'day'
    if request.haskey('cadence') then cadence = request['cadence']

    ; In most cases, file_times are calculated from time and cadence.
    ; One could set file_times directly for fine tuning.
    if n_elements(file_times) eq 0 then begin
        if n_elements(time) ne 0 then begin
            lprmsg, 'Construct file_times from time and cadeance ...'
            lprmsg, '    time: '+strjoin(time_string(time),' to ')
            lprmsg, '    cadence: '+string(cadence)
            file_times = break_down_times(time, cadence)
        endif
    endif
    ; Otherwise no time or file_times are set.
    ; We will refer time info to file_times, and check whether it is defined or not.
    if n_elements(file_times) eq 0 then file_times = !null
    request['file_times'] = file_times

    ; In most cases, we reach the file of the latest version,
    ; for fine tuning, set version to force reading certain version.
    ; In pattern, '%v' will be replaced by version, if it is not !null.
    if n_elements(version) ne 1 then version = !null
    request['version'] = version

    ; Sync time is checked to determine whether to download a file if it exists locally.
    if ~request.haskey('sync_time') then begin
        sync_time = !null
        sync_threshold = request.haskey('sync_threshold')? request.sync_threshold: 0
        if sync_threshold[0] gt 0 then sync_time = systime(1)-sync_threshold[0]
        request['sync_time'] = sync_time
    endif

    ; The extension for the files, e.g., 'cdf'.
    extension = request.haskey('extension')? request.extension: !null


;---1. String operations to construct filenames.
;   The effect is to add files to request, where files is a list of dictionaries
;   whose keys can be local_file, local_index, remote_file, remote_index, none to all.
    if n_elements(request.pattern) gt 0 then begin
        pattern = request.pattern
        files = list()
        foreach file_time, file_times do begin
            file = dictionary('file_time',file_time)
            foreach key, pattern.keys() do file[key] = construct_file(pattern[key],file_times=file_time, version=version)
            files.add, file
        endforeach
    endif

    ; Overwrite using the local_files if given for fine tuning.
    if n_elements(local_files) ne 0 then begin
        lprmsg, 'Use given local_files ...'
        files = list()
        foreach file, local_files do begin
            lprmsg, '    '+file+' ...'
            files.add, dictionary('local_file',file)
        endforeach
    endif

    ; To this point, if there is no file information, then nothing can be done.
    if n_elements(files) eq 0 then begin
        errmsg = handle_error('No local_file, do nothing but return ...')
        return, retval
    endif

    ; Only deal with uniq local_files.
    files = unique(files, at='local_file')

    ; Fill in the keys to make later operations easier.
    ; Add base_name, used in telling index lookup result.
    keys = ['file_time','local_file','local_index_file','remote_file','remote_index_file']
    foreach file, files, ii do begin
        if typename(file) ne strupcase('dictionary') then file = dictionary()
        foreach key, keys do if ~file.haskey(key) then file[key] = !null
        ; Force to have a local index file if there is a local file.
        if n_elements(file.local_file) eq 0 then continue
        file['base_name'] = fgetbase(file.local_file)
        if n_elements(file.local_index_file) eq 0 then begin
            lprmsg, 'Local index file is not set, construct it and delete existing ones ...'
            file.local_index_file = join_path([fgetpath(file.local_file),default_index_file()])
            ; Remove b/c otherwise it won't get updated.
            if file_test(file.local_index_file) eq 1 then file_delete, file.local_index_file
        endif
        files[ii] = file
    endforeach
    request['files'] = files


    ; Filter with valid range.
    ; If valid range has 2 elements, then it is the time range.
    ; If valid range has 1 element, then it is the start time range.
    if request.haskey('valid_range') then begin
        lprmsg, 'Check if file_time is within the valid time range ...'
        valid_range = request.valid_range
        if n_elements(valid_range) eq 1 then valid_range = [valid_range, systime(1)]
        valid_range = minmax(valid_range)
        lprmsg, '    Valid range: '+strjoin(time_string(valid_range),' to ')

        valid_files = list()
        foreach file, files do begin
            if n_elements(file.file_time) eq 0 then begin
                valid_files.add, file
                continue
            endif
            if file.file_time lt valid_range[0] then continue
            if file.file_time ge valid_range[1] then continue
            valid_files.add, file
        endforeach

        files = valid_files
        request['files'] = files
        ; To this point, if there is no file information, then nothing can be done.
        if n_elements(files) eq 0 then begin
            errmsg = handle_error('    No file is in the valid range ...')
            return, retval
        endif
    endif


;---2. Prepare index file.
    sync_time = request.sync_time
    files = request.files
    index_files = list()
    has_connection_to_remote = !null
    foreach file, files do begin
        if n_elements(file.local_index_file) eq 0 then continue
        index_files.add, dictionary($
            'local', file.local_index_file, $
            'remote', file.remote_index_file, $
            'file_time', file.file_time)
    endforeach

    if n_elements(index_files) ne 0 then begin
        index_files = unique(index_files, at='local')
        foreach file, index_files do begin
            lprmsg, 'Prepare local index file: '+file.local+' ...'
            if n_elements(file.remote) eq 0 then begin
                lprmsg, '    No remote info, stay local ...'
                sync_flag = 0

                if file_test(file.local) eq 0 then begin
                    lprmsg, '    File does not exist, try to update ...'
                    sync_flag = 1
                endif else lprmsg, '    File exists ...'

                if sync_flag then begin
                    lprmsg, '    Update the file ...'
                    gen_index_file, file.local, extension=extension, /delete_empty_folder
                endif else lprmsg, '    File is good to go ...'

                if file_test(file.local) eq 0 then lprmsg, '    Failed to generate the file ...'
            endif else begin
                lprmsg, '    Remote info is available: '+file.remote+' ...'
                sync_flag = 0

                if n_elements(sync_time) ne 0 then begin
                    lprmsg, '    Check sync_time: update if file_time is later than '+time_string(sync_time)+' ...'
                    ftime = file.file_time
                    if n_elements(ftime) ne 0 then if ftime ge sync_time then begin
                        lprmsg, '    The data file is new, need to update ...'
                        sync_flag = 1
                    endif else lprmsg, '    The data file is old, no need to update ...'
                endif
                if file_test(file.local) eq 0 then begin
                    lprmsg, '    File does not exist, try to update ...'
                    sync_flag = 1
                endif

                if sync_flag then begin
                    lprmsg, '    Sync the file ...'
                    if n_elements(has_connection_to_remote) eq 0 then begin
                        has_connection_to_remote = net_check_connection(file.remote)
                        msg = has_connection_to_remote? 'Have ': 'Does not have '
                        msg = '    '+msg+'connection to the remote server ...'
                        lprmsg, msg
                    endif
                    if has_connection_to_remote then begin
                        download_file, file.local, file.remote, errmsg=errmsg
                        test = lookup_index_file('not found', file.local)
                        if test ne '' then begin
                            lprmsg, '    Remote file is not found, cleaning up ...'
                            file_delete, file.local, /allow_nonexistent
                        endif
                    endif
                endif else lprmsg, '    File is good to go ...'

                if file_test(file.local) eq 0 then begin
                    lprmsg, '    Failed to sync the file, try to generate one ...'
                    gen_index_file, file.local, extension=extension, /delete_empty_folder
                    if file_test(file.local) eq 0 then lprmsg, '    Failed to generate the file ...'
                endif
            endelse
        endforeach
    endif
    request['index_files'] = index_files


;---3. Look up base_name in the index files.
    ; base_name = '' means failed to find the local_file.
    foreach file, files do begin
        lprmsg, 'Specify the data file: '+file.local_file+' ...'
        ; Do not expect an index file, check file availability directly.
        if n_elements(file.local_index_file) eq 0 then begin
            lprmsg, '    Skip to lookup data file in an index file ...'
            if file_test(file.local_file) eq 0 then begin
                file.base_name = ''
            endif else begin
                file.base_name = fgetbase(file.local_file)
            endelse
            continue
        endif

        ; Expect an index file, but it does not exist somehow.
        if file_test(file.local_index_file) eq 0 then begin
            lprmsg, '    Expect an index file but it does not exist, skipping ...'
            if file_test(file.local_file) eq 0 then begin
                file.base_name = ''
            endif else begin
                file.base_name = fgetbase(file.local_file)
            endelse
            continue
        endif

        ; Expect an index file, and it exists.
        lprmsg, '    Look up the index file: '+file.local_index_file+' ...'
        the_file = lookup_index_file(file.local_file, file.local_index_file)
        if the_file eq '' then begin
            ; Generate if the local index file is expected, and we stay local.
            if n_elements(file.remote_index_file) eq 0 then begin
                gen_index_file, file.local_index_file, extension=extension, /delete_empty_folder
                the_file = lookup_index_file(file.local_file, file.local_index_file)
            endif
        endif
        if the_file eq '' then begin
            file.base_name = ''  ; use this as a signature to tell results of looking up index.
        endif else begin
            file.local_file = the_file
            file.base_name = fgetbase(the_file)
        endelse

        if file.base_name eq '' then begin
            lprmsg, '    Data file is not found ...'
        endif else begin
            lprmsg, '    Data file is found: '+file.local_file+' ...'
        endelse

        if n_elements(file.remote_file) eq 0 then continue
        file_base = fgetbase(file.local_file)
        file.remote_file = join_path([fgetpath(file.remote_file),file_base])
        lprmsg, '    Remote data file should be: '+file.remote_file+' ...'
    endforeach
    request['files'] = files


;---4. Prepare file.
    foreach file, files do begin
        lprmsg, 'Prepare the data file: '+file.local_file+' ...'
        ; File is not found in the index file, do not download.
        if file.base_name eq '' then begin
            lprmsg, '    File is not found ...'
            continue
        endif

        if n_elements(file.remote_file) eq 0 then begin
            lprmsg, '    No remote info, stay local ...'
            ; Nothing can be done, will collect non-existing files for other operations, like call a generating routine.
        endif else begin
            lprmsg, '    Remote info is available: '+file.remote_file+' ...'
            sync_flag = 0

            if n_elements(sync_time) ne 0 then begin
                lprmsg, '    Check sync_time: update if file_time is later than '+time_string(sync_time)+' ...'
                ftime = file.file_time
                if n_elements(ftime) ne 0 then if ftime ge sync_time then begin
                    lprmsg, '    The data file is new, need to update ...'
                    sync_flag = 1
                endif else lprmsg, '    The data file is old, no need to update ...'
            endif
            if file_test(file.local_file) eq 0 then begin
                lprmsg, '    File does not exist, try to update ...'
                sync_flag = 1
            endif

            if sync_flag then begin
                lprmsg, '    Sync the file ...'
                if n_elements(has_connection_to_remote) eq 0 then begin
                    has_connection_to_remote = net_check_connection(file.remote_file)
                    msg = has_connection_to_remote? 'Have ': 'Does not have '
                    msg = '    '+msg+'connection to the remote server ...'
                    lprmsg, msg
                endif
                if has_connection_to_remote then begin
                    download_flag = 0
                    if file_test(file.local_file) eq 1 then begin
                        finfo = file_info(file.local_file)
                        rinfo = get_remote_info(file.remote_file)
                        if finfo.size ne rinfo.size then download_flag = 1
                        if finfo.mtime ne rinfo.mtime then download_flag = 1
                        msg = '    Local file is identical to remote, done ...'
                        lprmsg, msg
                    endif else download_flag = 1
                    if download_flag then $
                        download_file, file.local_file, file.remote_file, errmsg=errmsg
;                    if errmsg ne '' then begin
;                        lprmsg, '    Remote file is not found, cleaning up ...'
;                        file_delete, file.local_file, /allow_nonexistent
;                    endif
                endif
            endif else lprmsg, '    File is good to go ...'

        endelse
        if file_test(file.local_file) eq 0 then begin
            lprmsg, '    Failed to find the file ...'
            continue
        endif
        if n_elements(mtime) eq 0 then continue
        ftouch, file.local_file, mtime=mtime
    endforeach


    local_files = list()
    nonexist_files = list()
    ne_files = list()
    foreach file, files do begin
        if file_test(file.local_file) eq 0 then begin
            nonexist_files.add, file.local_file, /extract
            ne_files.add, file
        endif else begin
            local_files.add, file.local_file, /extract
        endelse
    endforeach
    local_files = local_files.toarray()
    nonexist_files = nonexist_files.toarray()
    request['nonexist_files'] = ne_files
    
    if n_elements(local_files) eq 0 then begin
        errmsg = 'No file found ...'
        return, retval
    endif
    
    return, local_files
end

probe = 'c'
local_root = join_path([default_local_root(),'swarm'])
remote_root = 'ftp://swarm0555:othonwoo01@swarm-diss.eo.esa.int'
version = '.*'
local_base = 'SW_OPER_MAGC_LR_1B_%Y%m%dT.*_%Y%m%dT.*_'+version+'.CDF'
local_path = join_path([local_root,'swarm'+probe,'level1b','Current','MAGx_LR','%Y'])
remote_base = local_base+'.zip'
remote_path = join_path([remote_root,'Level1b','Latest_baselines','MAGx_LR','Sat_'+strupcase(probe)])
request = dictionary($
    'pattern', dictionary($
        'local_file', join_path([local_path,local_base]), $
        'local_index_file', join_path([local_path,default_index_file()]), $
        'remote_file', join_path([remote_path,remote_base]), $
        'remote_index_file', join_path([remote_path,''])), $
    'sync_threshold', 0, $      ; sync if mtime is after t_now-sync_threshold.
    'cadence', 'day')


;files = prep_file()
;files = prep_file(request=request)
time = time_double(['2013-11-26','2013-11-28'])
files = prepare_files(request=request, time=time)

end
