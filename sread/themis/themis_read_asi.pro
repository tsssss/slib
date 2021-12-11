;+
; Read Themis ASI data.
;
; in_vars. An array of strings to set varnames in data files, for fine-tuning.
; out_vars. An array of strings to set varnames saved in memory, for fine-tuning.
;-

pro themis_read_asi, time, id=datatype, site=site, $
    print_datatype=print_datatype, errmsg=errmsg, $
    local_files=files, file_times=file_times, version=version, $
    local_root=local_root, remote_root=remote_root, $
    in_vars=in_vars, out_vars=out_vars

    compile_opt idl2
    on_error, 0
    errmsg = ''

;---Check inputs.
    sync_threshold = 86400d*120
    if n_elements(probe) eq 0 then probe = 'x'
    if n_elements(local_root) eq 0 then local_root = join_path([default_local_root(),'data','themis'])
    if n_elements(remote_root) eq 0 then remote_root = 'http://themis.ssl.berkeley.edu/data/themis'
    if n_elements(version) eq 0 then version = 'v[0-9]{2}'

;---Init settings.
    type_dispatch = hash()
    thx = 'thg'
    ; full-resolution, 3 sec resolution.
    base_name = thx+'_l1_asf_'+site+'_%Y%m%d%H_'+version+'.cdf'
    local_path = [local_root,thx,'l1','asi',site,'%Y','%m']
    remote_path = [remote_root,thx,'l1','asi',site,'%Y','%m']
    type_dispatch['asf'] = dictionary($
        'pattern', dictionary($
            'local_file', join_path([local_path,base_name]), $
            'local_index_file', join_path([local_path,default_index_file(/sync)]), $
            'remote_file', join_path([remote_path,base_name]), $
            'remote_index_file', join_path([remote_path,''])), $
        'sync_threshold', sync_threshold, $
        'cadence', 'hour', $
        'extension', fgetext(base_name), $
        'var_list', list($
            dictionary($
                'in_vars', ['thg_asf_'+site], $
                'out_vars', ['thg_'+site+'_asf'], $
                'time_var_name', 'thg_asf_'+site+'_time', $
                'time_var_type', 'unix')))
    ; thumnail resolution, 1024 pixels in total.
    base_name = thx+'_l1_ast_'+site+'_%Y%m%d_'+version+'.cdf'
    local_path = [local_root,thx,'l1','asi',site,'%Y','%m']
    remote_path = [remote_root,thx,'l1','asi',site,'%Y','%m']
    type_dispatch['ast'] = dictionary($
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
                'in_vars', ['thg_ast_'+site], $
                'out_vars', ['thg_'+site+'_ast'], $
                'time_var_name', 'thg_ast_'+site+'_time', $
                'time_var_type', 'unix')))
    ; calibration data.
    base_name = thx+'_l2_asc_'+site+'_19700101_'+version+'.cdf'
    local_path = [local_root,thx,'l2','asi','cal']
    remote_path = [remote_root,thx,'l2','asi','cal']
    type_dispatch['asc'] = dictionary($
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
                'in_vars', ['thg_asc_'+site+'_'+['mlon','mlat']], $
                'out_vars', ['thg_'+site+'_asc_'+['mlon','mlat']], $
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
    if n_elements(in_vars) ne 0 then begin
        var_list = request.var_list[0]
        var_list.in_vars = in_vars
        if n_elements(out_vars) eq n_elements(in_vars) then var_list.out_vars = out_vars
        request.var_list = list(var_list)
    endif
    files = prepare_files(request=request, errmsg=errmsg, local_files=files, $
        file_times=file_times, time=time, nonexist_files=nonexist_files)

;---Read data from files and save to memory.
    read_files, time, files=files, request=request

end

themis_read_asi, /print_datatype
time = time_double(['2014-08-28/10:00','2014-08-28/10:03'])
;themis_read_asi, time, id='cal', site='whit'
themis_read_asi, time, id='ast', site='whit'
themis_read_asi, time, id='asf', site='whit'
end
