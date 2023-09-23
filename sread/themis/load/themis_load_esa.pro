;+
; Read Themis ESA data.
;-

function themis_load_esa, input_time_range, id=datatype, probe=probe, $
    print_datatype=print_datatype, errmsg=errmsg, $
    local_files=files, file_times=file_times, version=version, $
    local_root=local_root, remote_root=remote_root, $
    return=return_request

    compile_opt idl2
    on_error, 0
    errmsg = ''
    retval = ''

;---Check inputs.
    sync_threshold = 0
    if ~themis_probe_is_valid(probe) then begin
        errmsg = 'Invalid probe: '+probe+' ...'
        return, retval
    endif
    if n_elements(local_root) eq 0 then local_root = join_path([default_local_root(),'themis'])
    if n_elements(remote_root) eq 0 then remote_root = 'https://cdaweb.gsfc.nasa.gov/pub/data/themis'
    if n_elements(version) eq 0 then version = 'v[0-9]{2}'

    if size(input_time_range[0],type=1) eq 7 then begin
        time_range = time_double(input_time_range)
    endif else begin
        time_range = input_time_range
    endelse

;---Init settings.
    thx = 'th'+probe
    type_dispatch = hash()

    ; Level 2.
    valid_range = ['2007-03-07']    ; the start date applies to tha-the.
    base_name = thx+'_l2_esa_%Y%m%d_'+version+'.cdf'
    local_path = [local_root,thx,'l2','esa','%Y']
    remote_path = [remote_root,thx,'l2','esa','%Y']
    type_dispatch['l2'] = dictionary($
        'pattern', dictionary($
            'remote_file', join_path([remote_path,base_name]), $
            'remote_index_file', join_path([remote_path,'']), $
            'local_file', join_path([local_path,base_name]), $
            'local_index_file', join_path([local_path,default_index_file(/sync)])), $
        'valid_range', time_double(valid_range), $
        'sync_threshold', sync_threshold, $
        'cadence', 'day', $
        'extension', fgetext(base_name) )

    if keyword_set(print_datatype) then begin
        print, 'Suported data type: '
        ids = type_dispatch.keys()
        foreach id, ids do print, '  * '+id
        return, ids
    endif


;---Dispatch patterns.
    if n_elements(datatype) eq 0 then datatype = 'l2'
    if not type_dispatch.haskey(datatype) then begin
        errmsg = handle_error('Do not support type '+datatype+' yet ...')
        return, retval
    endif
    request = type_dispatch[datatype]
    if keyword_set(return_request) then return, request

;---Find files, read variables, and store them in memory.
    files = prepare_files(request=request, errmsg=errmsg, local_files=files, $
        file_times=file_times, time=time_range, nonexist_files=nonexist_files)

    if n_elements(files) eq 0 then return, '' else return, files

end
