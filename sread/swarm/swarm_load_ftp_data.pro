;+
; Load the raw Swarm ftp data to a local disk, then unzip and keep the CDFs.
;-

pro swarm_load_ftp_data, time, id=datatype, probe=probe, $
    print_datatype=print_datatype, errmsg=errmsg, $
    local_root=local_root, remote_root=remote_root, $
    files=files, file_times=file_times, data_root=data_root

    compile_opt idl2
    on_error, 0
    errmsg = ''


;---Check inputs.
    if n_elements(probe) eq 0 then probe = 'x'

;---Default settings.
    if n_elements(local_root) eq 0 then local_root = join_path([default_local_root(),'data','swarm'])
    if n_elements(data_root) eq 0 then data_root = join_path([default_local_root(),'sdata','swarm'])
    if n_elements(remote_root) eq 0 then remote_root = 'ftp://swarm0555:othonwoo01@swarm-diss.eo.esa.int'
    if n_elements(version) eq 0 then version = '.*'
    if n_elements(coord) eq 0 then coord = 'gsm'

    type_dispatch = hash()
    ; Level 1b.
    base_name = 'SW_OPER_MAGC_LR_1B_%Y%m%dT.*_%Y%m%dT.*_'+version+'.CDF.ZIP'
    local_path = join_path([local_root,'swarm'+probe,'level1b','Current','MAGx_LR','%Y'])
    remote_path = join_path([remote_root,'Level1b','Latest_baselines','MAGx_LR','Sat_'+strupcase(probe)])

    type_dispatch['1b%mag'] = dictionary($
        'pattern', dictionary($
            'local_file',  join_path([local_path,base_name]), $
            'local_index_file', join_path([local_path,default_index_file()]), $
            'remote_file', join_path([remote_path,base_name]), $
            'remote_index_file', join_path([remote_path,''])), $
        'sync_threshold', 0, $      ; sync if mtime is after t_now-sync_threshold.
        'target_file', 'SW_OPER_MAGC_LR_1B_.*_MDR_MAG_LR.cdf', $
        'cadence', 'day')

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
    if ~type_dispatch.haskey(datatype) then begin
        errmsg = handle_error('Do not support type '+datatype+' yet ...')
        return
    endif
    request = type_dispatch[datatype]

;---Prepare files.
    files = prepare_files(request=request, errmsg=errmsg, local_files=files, $
        file_times=file_times, time=time)

;---Unzip the files to data_root, remove all other files than the CDFs.
    nfile = n_elements(files)
    pos = strlen(local_root)
    target_file = request.target_file
    index_files = list()
    foreach file, files, ii do begin
        new_file = join_path([data_root,strmid(file,pos)])
        if file_test(new_file) eq 1 then continue
        new_path = fgetpath(new_file)
        index_files.add, join_path([new_path, default_index_file()])
        if file_test(new_path,/directory) eq 0 then file_mkdir, new_path
        file_copy, file, new_file, /overwrite
        file_unzip, new_file, files=zip_files
        ; Delete files other than the target cdf.
        foreach file, [new_file,zip_files] do begin
            if stregex(file, target_file, /fold_case) ne -1 then continue
            file_delete, file, /allow_nonexistent
        endforeach
    endforeach

    index_files = index_files.toarray()
    gen_index_file, index_files

end

time = time_double(['2013-12-25','2013-12-26'])
swarm_load_ftp_data, time, probe='c', id='mag'
end
