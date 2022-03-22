;+
; Read Polar CDAWeb MFE data.
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
;-

pro polar_read_mfe, time, id=datatype, probe=probe, $
    print_datatype=print_datatype, errmsg=errmsg, $
    local_files=files, file_times=file_times, version=version, $
    local_root=local_root, remote_root=remote_root

    compile_opt idl2
    on_error, 0
    errmsg = ''


;---Check inputs.
    if n_elements(local_root) eq 0 then local_root = join_path([default_local_root(),'polar','mfe'])
    if n_elements(remote_root) eq 0 then remote_root = 'https://cdaweb.gsfc.nasa.gov/pub/data/polar/mfe'
    if n_elements(version) eq 0 then version = 'v.*'


;---Init settings.
    type_dispatch = hash()
    ; B GSM.
    valid_range = ['1996-03-16','2006-05-31']
    base_name = 'po_k0_mfe_%Y%m%d_'+version+'.cdf'
    local_path = [local_root,'%Y']
    remote_path = [remote_root,'%Y']
    type_dispatch['k0%bgsm'] = dictionary($
        'pattern', dictionary($
            'local_file', join_path([local_path,base_name]), $
            'local_index_file', join_path([local_path,default_index_file(/sync)]), $
            'remote_file', join_path([remote_path,base_name]), $
            'remote_index_file', join_path([remote_path,''])), $
        'valid_range', time_double(valid_range), $
        'cadence', 'day', $
        'extension', 'cdf', $
        'var_list', list($
            dictionary($
                'in_vars', ['B_GSM'], $
                'out_vars', ['po_b_gsm'], $
                'time_var_name', 'Epoch', $
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
    read_files, time, files=files, request=request

end

time = time_double(['2000-01-01','2000-01-03'])
polar_read_mfe, time, id='k0%bgsm'
end