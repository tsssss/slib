function prepare_local_file, request, $
    local_files=local_files, $
    time_range=input_time_range, file_times=file_times, cadence=cadence, $
    local_file_pattern=local_file_pattern, local_file_index=local_file_index, $
    version=version, errmsg=errmsg, $
    _extra=extra

    errmsg = ''
    retval = !null


    if n_elements(request) eq 0 then request = dictionary()

;---Get local_files
    if ~request.haskey('local_files') then request.local_files = []
    if n_elements(local_files) ne 0 then request.local_files = local_files
    if n_elements(request.local_files) eq 0 then begin
    ;---Get local_files from pattern.
        if ~request.haskey('local_file_pattern') then request.local_file_pattern = !null
        if n_elements(local_file_pattern) ne 0 then request.local_file_pattern = local_file_pattern
        if n_elements(request.local_file_pattern) ne 0 then begin
        ;---Check file_times.
            if ~request.haskey('file_times') then request.file_times = []
            if n_elements(file_times) ne 0 then request.field_times = file_times
            if n_elements(request.file_times) eq 0 then begin
                ; Get from time_range and cadence.
                if ~request.haskey('time_range') then request.time_range = []
                if n_elements(input_time_range) ne 0 then request.time_range = time_double(input_time_range)
                if ~request.haskey('cadence') then request.cadence = 'day'
                if n_elements(cadence) ne 0 then request.cadence = cadence
                request.file_times = break_down_times(request.time_range,request.cadence)
            endif

            if n_elements(request.file_times) ne 0 then begin
                request.local_files = apply_time_to_pattern(request.local_file_pattern, request.file_times)
            endif else begin
                request.local_files = request.local_file_pattern
            endelse
        endif
    endif
    nlocal_file = n_elements(request.local_files)
    if nlocal_file eq 0 then begin
        errmsg = 'No local_files ...'
        return, retval
    endif
    

    ; Loop through each local_file.
    request.local_file_list = list()
    index_infos = orderedhash()
    nfile_time = n_elements(request.file_times)

    foreach local_file, request.local_files, file_id do begin
        local_path = file_dirname(local_file)
        
        ; Register the current local_path and prepare the index.
        if ~request.haskey('local_file_index') then request.local_file_index = !null
        if n_elements(local_file_index) ne 0 then request.local_file_index = local_file_index
        if ~index_infos.haskey(local_path) then begin
            index_infos[local_path] = []
            if n_elements(request.local_file_index) eq 0 then begin
                index_infos[local_path] = file_search(local_path,'*')
            endif else begin
                local_index = join_path([local_path,request.local_file_index])
                if file_test(local_index) eq 0 then gen_index_file, local_index
                index_infos[local_path] = read_all_lines(local_index)
            endelse
        endif

        file_info = dictionary($
            'local_file', local_file, $
            'local_files', lookup_index_per_file(local_file, lines=index_infos[local_path]), $
            'file_time', !null )
        if nfile_time ne 0 then file_info.file_time = request.file_times[file_id]
        request.local_file_list.add, file_info
    endforeach

    request.local_file_is_ready = check_if_files_are_ready(request.local_file_list, files=local_files)
    
    if request.local_file_is_ready eq 1 then return, local_files else return, retval

end

