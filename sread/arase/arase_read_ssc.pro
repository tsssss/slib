;+
; Read Arase position data.
;-

pro arase_read_ssc, time, id=datatype, $
    print_datatype=print_datatype, errmsg=errmsg, $
    local_files=files, file_times=file_test, version=version, $
    local_root=local_root, remote_root=remote_root, $
    coordinate=coord

    compile_opt idl2
    on_error, 0
    errmsg = ''

;---Check inputs.
    sync_threshold = 1e7    ; sec of 4 months.
    if n_elements(local_root) eq 0 then local_root = join_path([default_local_root(),'data','arase'])
    if n_elements(remote_root) eq 0 then remote_root = 'https://ergsc.isee.nagoya-u.ac.jp/data/ergsc/satellite/erg'
    if n_elements(version) eq 0 then version = 'v[0-9.]{2}'
    if n_elements(coord) eq 0 then coord = 'gsm'

;---Init settings.
    type_dispatch = hash()
    ; Definitive.
    base_name = 'erg_orb_l2_%Y%m%d_'+version+'.cdf'
    local_path = [local_root,'orb','def','%Y']
    remote_path = [remote_root,'orb','def','%Y']
    type_dispatch['l2%def'] = dictionary($
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
            'in_vars', ['pos_'+coord], $
            'out_vars', ['arase_r_'+coord], $
            'time_var_name', 'epoch', $
            'time_var_type', 'tt2000')))
    ; Predicted.
    base_name = 'erg_orb_pre_l2_%Y%m%d_'+version+'.cdf'
    local_path = [local_root,'orb','pre','%Y']
    remote_path = [remote_root,'orb','pre','%Y']
    type_dispatch['l2%pre'] = dictionary($
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
            'in_vars', ['pos_'+coord], $
            'out_vars', ['arase_r_'+coord], $
            'time_var_name', 'epoch', $
            'time_var_type', 'tt2000')))

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

    myinfo = (type_dispatch[datatype]).tostruct()
    if n_elements(time_var_name) ne 0 then myinfo.time_var_name = time_var_name
    if n_elements(time_var_type) ne 0 then myinfo.time_var_type = time_var_type

end

arase_read_ssc, /print_datatype
time = time_double(['2019-01-01','2019-01-02'])
arase_read_ssc, time, id='l2%def'
end
