;+
; Load high-resolution state info.
;-

function mms_ld_state_gen_file_v01, input_time_range, probe=probe, filename=file, errmsg=errmsg

    errmsg = ''
    retval = !null
    update = 0

    date = time_double(input_time_range[0])
    ep = stoepoch(date,'unix')
    ep0 = sepochfloor(ep,'mo')
    ep1 = sepochceil(ep,'mo')
    time_range = sfmepoch([ep0,ep1],'unix')
    stop



end

function mms_ld_state, input_time_range, probe=probe, id=datatype, $
    print_datatype=print_datatype, errmsg=errmsg, $
    local_files=files, file_times=file_times, version=version, $
    local_root=local_root, remote_root=remote_root, $
    return_request=return_request

    compile_opt idl2
    on_error, 0
    errmsg = ''

;---Check inputs.
    sync_threshold = 86400d*120
    if n_elements(probe) eq 0 then probe = 'x'
    if n_elements(local_root) eq 0 then local_root = join_path([default_local_root(),'mms'])
    if n_elements(version) eq 0 then version = 'v01'

    if size(input_time_range[0],type=1) eq 7 then begin
        time_range = time_double(input_time_range)
    endif else begin
        time_range = input_time_range
    endelse

;---Init settings.
    type_dispatch = hash()

    base_name = 'mms'+probe+'_state_srvy_l2_%Y%m_'+version+'.cdf'
    local_path = [local_root,'mms'+probe,'state','srvy','l2','%Y']
    valid_range = mms_valid_range('mec%l2%survey', probe=probe)
    type_dispatch['l2%survey'] = dictionary($
        'pattern', dictionary($
            'local_file', join_path([local_path,base_name]), $
            'local_index_file', join_path([local_path,default_index_file(/sync)]), $
            'remote_file', join_path([remote_path,base_name]), $
            'remote_index_file', join_path([remote_path,''])), $
        'valid_range', time_double(valid_range), $
        'sync_threshold', 0, $
        'cadence', 'month', $
        'extension', fgetext(base_name) )
    
    if keyword_set(print_datatype) then begin
        print, 'Suported data type: '
        ids = type_dispatch.keys()
        foreach id, ids do print, '  * '+id
        return, ids
    endif


;---Dispatch patterns.
    if n_elements(datatype) eq 0 then begin
        errmsg = handle_error('No input datatype ...')
        return, ''
    endif
    if not type_dispatch.haskey(datatype) then begin
        errmsg = handle_error('Do not support type '+datatype+' yet ...')
        return, ''
    endif
    request = type_dispatch[datatype]

;---Find files, read variables, and store them in memory.
    files = prepare_files(request=request, errmsg=errmsg, local_files=files, $
        file_times=file_times, time=time_range, nonexist_files=nonexist_files)
    if n_elements(nonexist_files) ne 0 then begin
        foreach file, request.nonexist_files do begin
            file_time = file.file_time
            local_file = file.local_file
            routine = 'mms_ld_state_gen_file_'+version
            local_file = call_function(routine, file_time, probe=probe, filename=local_file)
        endforeach
        files = prepare_files(request=request, errmsg=errmsg, $
            file_times=file_times, time=time, nonexist_files=nonexist_files)
    endif
    
    if n_elements(files) eq 0 then return, '' else return, files

end

time_range = time_double(['2016-10-13','2016-10-14'])
probe = '1'
file = mms_ld_state_gen_file_v01(time_range, probe=probe)
stop
files = mms_ld_state(time_range, probe=probe)
end