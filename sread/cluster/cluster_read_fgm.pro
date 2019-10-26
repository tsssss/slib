;+
; Read FGM data.
;-
pro cluster_read_fgm, time, id=datatype, probe=probe, $
    print_datatype=print_datatype, errmsg=errmsg, $
    local_files=files, file_times=file_times, version=version, $
    local_root=local_root, remote_root=remote_root

    compile_opt idl2
    on_error, 0
    errmsg = ''

;---Check inputs.
    sync_threshold = 86400d*120
    if n_elements(probe) eq 0 then probe = 'x'
    if n_elements(local_root) eq 0 then local_root = join_path([default_local_root(),'data','cluster'])
    if n_elements(remote_root) eq 0 then remote_root = 'https://cdaweb.gsfc.nasa.gov/pub/data/cluster'
    if n_elements(version) eq 0 then version = 'v[0-9]{2}'
    if n_elements(coord) eq 0 then coord = 'gse'

;---Init settings.
    type_dispatch = hash()
    cx = 'c'+probe
    ; spin resolution.
    valid_range = ['2001-01-30']
    base_name = cx+'_cp_fgm_spin_%Y%m%d_'+version+'.cdf'
    local_path = [local_root,cx,'fgm','%Y']
    remote_path = [remote_root,cx,'cp','%Y']
    type_dispatch['fgm_spin'] = dictionary($
        'pattern', dictionary($
                'local_file', join_path([local_path,base_name]), $
                'local_index_file', join_path([local_path,default_index_file(/sync)]), $
                'remote_file', join_path([remote_path,base_name]), $
                'remote_index_file', join_path([remote_path,''])), $
            'valid_range', time_double(valid_range), $
            'sync_threshold', sync_threshold, $
            'cadence', 'day', $
            'extension', 'cdf', $
            'var_list', list($
                dictionary($
                    'in_vars', 'B_vec_xyz_gse__'+strupcase(cx+'_cp_fgm_spin'), $
                    'out_vars', cx+'_b_gse', $
                    'time_var_name', 'time_tags__'+strupcase(cx+'_cp_fgm_spin'), $
                    'time_var_type', 'epoch')))
    ; orbit data.
    type_dispatch['orbit'] = dictionary($
        'pattern', dictionary($
                'local_file', join_path([local_path,base_name]), $
                'local_index_file', join_path([local_path,default_index_file(/sync)]), $
                'remote_file', join_path([remote_path,base_name]), $
                'remote_index_file', join_path([remote_path,''])), $
            'valid_range', time_double(valid_range), $
            'sync_threshold', sync_threshold, $
            'cadence', 'day', $
            'extension', 'cdf', $
            'var_list', list($
                dictionary($
                    'in_vars', 'sc_pos_xyz_gse__'+strupcase(cx+'_cp_fgm_spin'), $
                    'out_vars', cx+'_r_gse', $
                    'time_var_name', 'time_tags__'+strupcase(cx+'_cp_fgm_spin'), $
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

cluster_read_fgm, /print_datatype
time = time_double(['2013-10-30/23:00','2013-10-31/06:00'])
cluster_read_fgm, time, id='fgm_spin', probe='1'
end
