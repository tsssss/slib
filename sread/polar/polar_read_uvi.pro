;+
; Read Polar UIV data.
;
; time. A time or a time range in ut time. Set time to find files
;   automatically, or set files to read data in them directly.
; datatype. A string set which set of variable to read. Use
;   print_datatype to see supported types.
; probe. A string set the probe to read data for.
; level. A string set the level of data, e.g., 'l1'.
; variable. An array of variables to read. Users can omit this keyword
;   unless want to fine tune the behaviour.
; files. A string or an array of N full file names. Set this keyword
;   will set files directly.
; version. A string sets the version of data. Default behaviour is to read
;   the highest version. Set this keyword to read specific version.
; id. A string for type dispatch. This is for low-level manipulations.
; errmsg. A flag. 1 for error in loading data, 0 for ok.
;-
;

pro polar_read_uvi, time, id=datatype, $
    print_datatype=print_datatype, errmsg=errmsg, $
    local_files=files, file_times=file_times, version=version, $
    local_root=local_root, remote_root=remote_root

    compile_opt idl2
    on_error, 0
    errmsg = ''

;---Check inputs.
    if n_elements(local_root) eq 0 then local_root = join_path([default_local_root(),'polar','uvi'])
    if n_elements(remote_root) eq 0 then remote_root = 'https://cdaweb.sci.gsfc.nasa.gov/pub/data/polar/uvi'
    if n_elements(version) eq 0 then version = 'v[0-9]{2}'

;---Init settings.
    type_dispatch = hash()
    index_file = 'SHA1SUM'
    ; Level 1 data.
    base_name = 'po_level1_uvi_%Y%m%d_'+version+'.cdf'
    local_path = [local_root,'uvi_level1','%Y']
    remote_path = [remote_root,'uvi_level1','%Y']
    valid_range = ['1996-03-20','2008-02-11']
    type_dispatch['l1'] = dictionary($
        'pattern', dictionary($
            'local_file', join_path([local_path,base_name]), $
            'local_index_file', join_path([local_path,index_file]), $
            'remote_file', join_path([remote_path,base_name]), $
            'remote_index_file', join_path([remote_path,index_file])), $
        'valid_range', time_double(valid_range), $
        'cadence', 'day', $
        'extension', fgetext(base_name), $
        'var_list', list($
            dictionary($
                'in_vars', ['INT_IMAGE','FILTER','FRAMERATE','SYSTEM'], $
                'time_var_name', 'EPOCH', $
                'time_var_type', 'epoch')))

    if keyword_set(print_datatype) then begin
        print, 'Suported data type: '
        ids = type_dispatch.keys()
        foreach id, ids do print, '  * '+id
        return
    endif


;---Dispatch patterns.
    if n_elements(datatype) eq 0 then begin
        errmsg = handle_error('No input datatype ...')
        return
    endif
    if not type_dispatch.haskey(datatype) then begin
        errmsg = handle_error('Do not support type '+datatype+' yet ...')
        return
    endif
    request = type_dispatch[datatype]

;---Find files, read variables, and store them in memory.
    files = prepare_files(request=request, errmsg=errmsg, local_files=files, $
        file_times=file_times, time=time, nonexist_files=nonexist_files)

;---Read data from files and save to memory.
    read_files, time, files=files, request=request, errmsg=errmsg

end

time = time_double(['1997-05-01/20:22','1997-05-01/20:25'])
polar_read_uvi, time, id='l1'
end
