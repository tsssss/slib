;+
; Read RBSP MAGEIS data.
;
; time. A time or a time range in ut time. Set time to find files
;   automatically, or set files to read data in them directly.
; id=. A string sets the data type to read. Check supported ids by setting
;   print_datatype.
; print_datatype=. A boolean. Set to print all supported ids.
; probe=. A string set the probe to read data for.
; local_root=. A string to set the local root directory.
; remote_root=. A string to set the remote root directory.
; local_files=. A string or an array of N full file names. Set to fine
;   tuning the files to read data from.
; file_times=. An array of N times. Set to fine tuning the times of the files.
; release=. A string to set the release. Default is 'rel04'.
;-
pro rbsp_read_mageis, time, id=datatype, probe=probe, $
    print_datatype=print_datatype, errmsg=errmsg, $
    local_files=files, file_times=file_times, version=version, $
    local_root=local_root, remote_root=remote_root, $
    release=release

    compile_opt idl2
    on_error, 0
    errmsg = ''


;---Check inputs.
    sync_threshold = 86400d*120
    if n_elements(probe) eq 0 then probe = 'x'
    if n_elements(local_root) eq 0 then local_root = join_path([default_local_root(),'rbsp'])
    if n_elements(remote_root) eq 0 then remote_root = 'https://cdaweb.gsfc.nasa.gov/pub/data/rbsp'
    ;remote_root = 'https://cdaweb.gsfc.nasa.gov/pub/data/rbsp'
    if n_elements(version) eq 0 then version = 'v[0-9.]{5}'
    if n_elements(release) eq 0 then release = 'rel04'  ; updated 2019-06.

;---Init settings.
    type_dispatch = hash()
    rbspx = 'rbsp'+probe
    ; Level 3.
    base_name = 'rbsp'+probe+'_'+release+'_ect-mageis-l3_%Y%m%d_'+version+'.cdf'
    local_path = [local_root,rbspx,'mageis','%Y','l3',release]
    remote_path = [remote_root,rbspx,'l3','ect','mageis','sectors',release,'%Y']
    type_dispatch['l3%ion'] = dictionary($
        'pattern', dictionary($
            'local_file', join_path([local_path,base_name]), $
            'local_index_file', join_path([local_path,default_index_file(/sync)]), $
            'remote_file', join_path([remote_path,base_name]), $
            'remote_index_file', join_path([remote_path,''])), $
        'sync_threshold', sync_threshold, $
        'cadence', 'day', $
        'extension', fgetext(base_name), $
        'var_list', list($
            dictionary($
                'in_vars', ['Epoch','FPDU'], $
                'time_var_name', 'Epoch', $
                'time_var_type', 'epoch'), $
            dictionary($
                'in_vars', ['FPDU_Alpha','FPDU_Energy'], $
                'generic_time', 1)))
    type_dispatch['l3%electron'] = dictionary($
        'pattern', dictionary($
            'local_file', join_path([local_path,base_name]), $
            'local_index_file', join_path([local_path,default_index_file(/sync)]), $
            'remote_file', join_path([remote_path,base_name]), $
            'remote_index_file', join_path([remote_path,''])), $
        'sync_threshold', sync_threshold, $
        'cadence', 'day', $
        'extension', fgetext(base_name), $
        'var_list', list($
            dictionary($
                'in_vars', ['Epoch','FEDU'], $
                'time_var_name', 'Epoch', $
                'time_var_type', 'epoch'), $
            dictionary($
                'in_vars', ['FEDU_Alpha','FEDU_Energy'], $
                'generic_time', 1)))

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
    read_files, time, files=files, request=request

end


rbsp_read_mageis, /print_datatype
time = time_double(['2013-06-07/04:52','2013-06-07/05:02'])
rbsp_read_mageis, time, id='l3', probe='b'
end
