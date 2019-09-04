;+
; Read Polar CDAWeb Hydra data.
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

pro polar_read_cdaweb_hydra, time, id= datatype, probe=probe, $
    print_datatype=print_datatype, errmsg=errmsg, $
    local_files=files, file_times=file_times, version=version, $
    local_root=local_root, remote_root=remote_root

    compile_opt idl2
    on_error, 0
    errmsg = ''


;---Check inputs.
    if n_elements(local_root) eq 0 then local_root = join_path([default_local_root(),'data','polar','hydra'])
    if n_elements(remote_root) eq 0 then remote_root = 'https://cdaweb.gsfc.nasa.gov/pub/data/polar/hydra'
    if n_elements(version) eq 0 then version = 'v[0-9]{2}'


;---Init settings.
    type_dispatch = hash()
    ; Ion moment data.
    valid_range = ['1996-03-20','2008-04-15']
    base_name = 'polar_hydra_moments-14sec_%Y%m%d_'+version+'.cdf'
    local_path = [local_root,'moments-14sec','%Y']
    remote_path = [remote_root,'moments-14sec','%Y']
    type_dispatch['ion_vel'] = dictionary($
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
                'in_vars', ['BULK_VELOCITY_ION'], $
                'out_vars', 'po_'+['u_gsm'], $
                'time_var_name', 'EPOCH', $
                'time_var_type', 'epoch')))
    type_dispatch['ion_density'] = dictionary($
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
                'in_vars', ['DENSITY_ION'], $
                'out_vars', 'po_'+['ion_n'], $
                'time_var_name', 'EPOCH', $
                'time_var_type', 'epoch')))
    ; Ele moment data.
    valid_range = ['1996-03-20','2008-03-31']
    base_name = 'po_k0_hyd_%Y%m%d_'+version+'.cdf'
    local_path = [local_root,'hyd_k0','%Y']
    remote_path = [remote_root,'hydra_k0','%Y']
    type_dispatch['ele_density'] = dictionary($
        'pattern', dictionary($
            'local_file', join_path([local_path,base_name]), $
            'local_index_file', join_path([local_path,default_index_file(/syn)]), $
            'remote_file', join_path([remote_path,base_name]), $
            'remote_index_file', join_path([remote_path,''])), $
        'valid_range', time_double(valid_range), $
        'cadence', 'day', $
        'extension', 'cdf', $
        'var_list', list($
            dictionary($
                'in_vars', ['ELE_DENSITY'], $
                'out_vars', 'po_'+['ele_n'], $
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


time = time_double(['1999-09-25','1999-09-26'])
polar_read_cdaweb_hydra, time, id='ele_moment'
end
