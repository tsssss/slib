;+
; This code is system dependent, rely on the request dictionary.
; Returns an array of strings of full file names that are locally exist.
;
; local_files. An array of strings. Set to fine tune the files for I/O.
;   Often, they are constructed from patterns containing format codes for
;   time and/or version.
;
;-

function prepare_files_construct_files, request, local_files=local_files, $
    file_times=file_times, version=version, errmsg=errmsg

    errmsg = ''
    retval = !null

    if request.haskey('pattern') then begin
    ;---Treat patterns containing format codes for version and time.
    ;   Return a dictionary of lists.
        files = construct_file(request.pattern, version=version, file_times=file_times)
        foreach key, files.keys() do request[key] = files[key]
    endif
    if n_elements(local_files) ne 0 then request['local_files'] = local_files


    if ~request.haskey('local_files') then begin
        errmsg = handle_error('No local files ...')
        return, retval
    endif

    return, request.local_files

end

; Prepare local_index_files, and local_sync_files.
function prepare_files_prepare_index_files, request, $
    remote_files=remote_index_files, $
    sync_basename=sync_basename, sync_time=sync_time, mtime=mtime

    retval = !null

;---Check inputs.
    ; No index file, do nothing.
    if ~request.haskey('local_index_files') then return, retval
    index_files = request.local_index_files

    sync_map = 'file_copy'
    if request.haskey('sync_map_index') then $
        if typename(request.sync_map_index) eq strupcase('string') then $
            sync_map = request.sync_map_index

    ; Wrong index file, remove the wrong info.
    files = request.local_files
    nfile = n_elements(files)
    if n_elements(index_files) ne nfile then begin
        request.remove, 'local_index_files'
        return, retval
    endif

    ; Try to get remote_index_files.
    if n_elements(remote_index_files) eq 0 then $
        if request.haskey('remote_index_files') then $
            remote_index_files = request.remote_index_files

    if n_elements(remote_index_files) eq 0 then begin
        ; local_data. Generate the index file.
        gen_index_file, index_files, sync_time=sync_time, mtime=mtime
    endif else begin
        ; Get the sync_files, use sync_index_base if provided.
        sync_files = index_files
        if request.haskey('sync_index_base') then begin
            sync_base = request.sync_index_base
            foreach file, sync_files, ii do begin
                sync_files[ii] = join_path([fgetpath(index_files[ii]),sync_base[ii]])
            endforeach
        endif
        sync_file, local_files=sync_files, remote_files=remote_index_files, $
            sync_time=sync_time, mtime=mtime
        sync_list = list()
        foreach file, sync_files, ii do begin
            if file_test(file) eq 0 then continue
            if file eq index_files[ii] then continue
            if sync_list.where(file) ne !null then continue
            sync_list.add, file
            if file_test(index_files[ii]) then file_delete, index_files[ii]
            call_procedure, sync_map, file, index_files[ii]
            if n_elements(mtime) then stouch, index_files[ii], mtime=mtime
        endforeach
    endelse

    uniq_files = list()
    foreach file, index_files do begin
        if file_test(file) eq 0 then continue
        if uniq_files.where(file) ne !null then continue
        uniq_files.add, file
    endforeach

    return, uniq_files

end

function prepare_files_lookup_files, request

    local_files = request.local_files    ; Assume that they are already unique.
    nfile = n_elements(local_files)
    if ~request.haskey('local_index_files') then return, local_files
    index_files = request.local_index_files

    ; remote_files must have nfile elements, or undefined.
    if request.haskey('remote_files') then begin
        remote_files = request.remote_files
        if n_elements(remote_files) ne nfile then remote_files = !null
        if request.haskey('sync_index_base') then sync_base = request.sync_index_base
        if n_elements(sync_base) ne nfile then sync_base = !null
    endif

    if n_elements(index_files) ne nfile then return, local_files

    ; Loop through each file.
    for ii=0, nfile-1 do begin
        lines = read_all_lines(index_files[ii])
        pattern = '('+fgetbase(local_files[ii])+')'
        the_files = list()
        foreach line, lines do begin
            result = stregex(line, pattern, /fold_case, /extract)
            if result[0] eq '' then continue
            the_files.add, result
        endforeach
        the_files = the_files.toarray()
        base = (the_files.sort())[-1]
        local_files[ii] = join_path([fgetpath(local_files[ii]),base])

        ; Get the remote file.
        if n_elements(remote_files) eq 0 then continue
        sync_index_file = index_files[ii]
        if n_elements(sync_base) ne 0 then sync_index_file = join_path([fgetpath(sync_index_file),sync_base[ii]])
        if file_test(sync_index_file) eq 0 then continue

        lines = read_all_lines(sync_index_file)
        pattern = '('+fgetbase(remote_files[ii])+')'
        the_files = list()
        foreach line, lines do begin
            result = stregex(line, pattern, /fold_case, /extract)
            if result[0] eq '' then continue
            the_files.add, result
        endforeach
        the_files = the_files.toarray()
        base = (the_files.sort())[-1]
        remote_files[ii] = join_path([fgetpath(remote_files[ii]),base])
    endfor

    request.local_files = local_files
    request.remote_files = remote_files
    return, local_files

end


function prepare_files_prepare_local_files, request, $
    remote_files=remote_files, $
    sync_basename=sync_basename, sync_time=sync_time

    retval = !null

;---Check inputs.
    ; No local file, do nothing.
    if ~request.haskey('local_files') then return, retval
    local_files = request.local_files

    sync_map = 'file_copy'
    if request.haskey('sync_map_file') then $
        if typename(request.sync_map_file) eq strupcase('string') then $
            sync_map = request.sync_map_file

    ; Try to get remote_files.
    if n_elements(remote_files) eq 0 then $
        if request.haskey('remote_files') then $
            remote_files = request.remote_files

    if n_elements(remote_files) eq 0 then begin
        ; local_data. Do nothing.
    endif else begin
        ; Get the sync_files, use sync_file_base if provided.
        sync_files = local_files
        foreach file, sync_files, ii do begin
            sync_files[ii] = join_path([fgetpath(local_files[ii]),fgetbase(remote_files[ii])])
        endforeach
        sync_file, local_files=sync_files, remote_files=remote_files, $
            sync_time=sync_time, mtime=mtime
        sync_list = list()
        foreach file, sync_files, ii do begin
            if file_test(file) eq 0 then continue
            if file eq local_files[ii] then continue
            if sync_list.where(file) ne !null then continue
            sync_list.add, file
            if file_test(local_files[ii]) then file_delete, local_files[ii]
            call_procedure, sync_map, file, local_files[ii]
            if n_elements(mtime) then stouch, index_files[ii], mtime=mtime
            if file_test(file) then file_delete, file
        endforeach

    endelse

    uniq_files = list()
    foreach file, local_files do begin
        if file_test(file) eq 0 then continue
        if uniq_files.where(file) ne !null then continue
        uniq_files.add, file
    endforeach

    return, uniq_files
end




function prepare_files, request=request, errmsg=errmsg, $
    local_files=local_files, $
    file_times=file_times, time=time, cadence=cadence, version=version, $
    _extra=extra

    errmsg = ''
    retval = !null

;---Check inputs.
    if typename(request) ne strupcase('dictionary') then begin
        errmsg = handle_error('No input request ...')
        return, retval
    endif

    ; In most cases, data are organized by days.
    if n_elements(cadence) eq 0 then cadence = 'day'
    if ~request.haskey('cadence') then request['cadence'] = 'day'

    ; In most cases, file_times are calculated from time and cadence.
    ; One could set file_times directly for fine tuning.
    if n_elements(file_times) eq 0 then begin
        if n_elements(time) ne 0 then begin
            file_times = break_down_times(time, cadence)
        endif
    endif
    ; Otherwise no time or file_times are set.
    ; We will refer time info to file_times, and check whether it is defined or not.
    if n_elements(file_times) eq 0 then file_times = !null
    request['file_times'] = file_times

    ; In most cases, we reach the file of the latest version,
    ; for fine tuning, set version to force reading certain version.
    ; In patterns, '%v' will be replaced by version, if it is not !null.
    if n_elements(version) ne 1 then version = !null
    request['version'] = version



;---1. String operations to construct filenames.
;   The effect is to add local_files in request.
    files = prepare_files_construct_files(request, errmsg=errmsg, $
        file_times=file_times, version=version, local_files=local_files)
    if errmsg ne '' then return, retval

;---2. Prepare local_index_files in request.
    index_files = prepare_files_prepare_index_files(request, sync_time=sync_time)

;---3. Lookup local_files in local_index_files.
    files = prepare_files_lookup_files(request)

;---4. Prepare local_files.
    files = prepare_files_prepare_local_files(request, sync_time=sync_time)

    return, files
end

probe = 'c'
local_root = join_path([default_local_root(),'data','swarm'])
remote_root = 'ftp://swarm0555:othonwoo01@swarm-diss.eo.esa.int'
version = '%v'
local_base = 'SW_OPER_MAGC_LR_1B_%Y%m%dT.*_%Y%m%dT.*_'+version+'.CDF'
local_path = join_path([local_root,'swarm'+probe,'level1b','Current','MAGx_LR','%Y'])
remote_base = local_base+'.zip'
remote_path = join_path([remote_root,'Level1b','Latest_baselines','MAGx_LR','Sat_'+strupcase(probe)])
request = dictionary($
    'pattern', dictionary($
        'local_files', join_path([local_path,local_base]), $
        'local_index_files', join_path([local_path,default_index_file()]), $
        'remote_files', join_path([remote_path,remote_base]), $
        'remote_index_files', join_path([remote_path,'']), $
        'sync_file_base', remote_base, $
        'sync_index_base', default_index_file(/sync)), $
    'sync_threshold', 0, $      ; sync if mtime is after t_now-sync_threshold.
    'sync_map_file', 'funzip', $
    'index_gen_routine', 'gen_index_file', $
    'time_independent', 0, $    ; 1: perform a replacement of time format code.
    'cadence', 'day', $
    'in_vars', [], $
    'out_vars', [], $
    'time_var_name', 'Epoch', $
    'time_var_type', 'tt2000', $
    'generic_time', 0)


;files = prep_file()
;files = prep_file(request=request)
time = time_double(['2013-11-26','2013-11-28'])
files = prepare_files(request=request, time=time)

end
