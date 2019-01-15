;+
; Read Themis ASI data.
; 
; time. A time or a time range in ut time. Set time to find files
;   automatically, or set files to read data in them directly.
; id. A string set which set of variable to read. Use
;   print_datatype to see supported types.
; site. A string set the site to read data for.
; print_datatype. A boolean, set it to get all available datatype.
; errmsg. A string as output. '' for no error, otherwise it carries the error message.
; in_vars. A string array [n]. Input variables that must exist in files.
; out_vars. A string array [n]. Output variables used when storeing data.
; files. A string array [m]. Set files directly for fine-tuning.
; version. A string to specify version. Set it for fine-tuning.
; local_root. A string for the root directory in local disks. Must exist.
; remote_root. A string for the server. Must exist.
; sync_after. A number for time. Check to sync if time is newer than this time.
; file_times. A string [m]. Set the times for finding files, for fine-tuning.
; index_file. A string for base name of the index file.
; sync_index. A boolean, set it to force syncing the index file.
; sync_files. A boolean, set it to force syncing the files.
; stay_local. A boolean, set it to search locally only.
;-

pro themis_read_asi, time, id=datatype, site=site, $
    print_datatype=print_datatype, errmsg=errmsg, $
    in_vars=in_vars, out_vars=out_vars, files=files, version=version, $
    local_root=local_root, remote_root=remote_root, $
    sync_after=sync_after, file_times=file_times, index_file=index_file, $
    sync_index=sync_index, sync_files=sync_files, stay_local=stay_local, $
    time_var_name=time_var_name, time_var_type=time_var_type, generic_time=generic_time

    compile_opt idl2
    on_error, 0
    errmsg = ''


;---Check inputs.
    nfile = n_elements(files)
    if n_elements(time) eq 0 and nfile eq 0 and ~keyword_set(print_datatype) then begin
        errmsg = handle_error('No time or file is given ...')
        return
    endif
    if keyword_set(print_datatype) then site = 'x'
    if n_elements(site) eq 0 then begin
        errmsg = handle_error('No input site ...')
        return
    endif
    if n_elements(out_vars) ne n_elements(in_vars) then out_vars = in_vars

;---Default settings.
    if n_elements(local_root) eq 0 then local_root = join_path([default_local_root(),'data','themis'])
    if n_elements(remote_root) eq 0 then remote_root = 'http://themis.ssl.berkeley.edu/data/themis'
    if n_elements(version) eq 0 then version = 'v[0-9]{2}'
    if n_elements(index_file) eq 0 then index_file = default_index_file()
    thx = 'thg'
    
    type_dispatch = []
    ; full-resolution, 3 sec resolution.
    type_dispatch = [type_dispatch, $
        {id: 'asf', $
        base_pattern: thx+'_l1_asf_'+site+'_%Y%m%d%H_'+version+'.cdf', $
        remote_paths: ptr_new([remote_root,thx,'l1','asi',site,'%Y','%m']), $
        local_paths: ptr_new([local_root,thx,'l1','asi',site,'%Y','%m']), $
        ptr_in_vars: ptr_new(['thg_asf_'+site]), $
        ptr_out_vars: ptr_new(['thg_'+site+'_asf']), $
        time_var_name: 'thg_asf_'+site+'_time', $
        time_var_type: 'unix', $
        generic_time: 0, $
        cadence: 'hour', $
        placeholder: 0b}]
    ; thumnail.
    type_dispatch = [type_dispatch, $
        {id: 'ast', $
        base_pattern: thx+'_l1_ast_'+site+'_%Y%m%d_'+version+'.cdf', $
        remote_paths: ptr_new([remote_root,thx,'l1','asi',site,'%Y','%m']), $
        local_paths: ptr_new([local_root,thx,'l1','asi',site,'%Y','%m']), $
        ptr_in_vars: ptr_new(['thg_ast_'+site]), $
        ptr_out_vars: ptr_new(['thg_'+site+'_ast']), $
        time_var_name: 'thg_ast_'+site+'_time', $
        time_var_type: 'unix', $
        generic_time: 0, $
        cadence: 'day', $
        placeholder: 0b}]
    ; calibration data.
    type_dispatch = [type_dispatch, $
        {id: 'asc', $
        base_pattern: thx+'_l2_asc_'+site+'_19700101_'+version+'.cdf', $
        remote_paths: ptr_new([remote_root,thx,'l2','asi','cal']), $
        local_paths: ptr_new([local_root,thx,'l2','asi','cal']), $
        ptr_in_vars: ptr_new(['thg_asc_'+site+'_'+['mlon','mlat']]), $
        ptr_out_vars: ptr_new(['thg_'+site+'_asc_'+['mlon','mlat']]), $
        time_var_name: '', $
        time_var_type: '', $
        generic_time: 0, $
        cadence: 'year', $
        placeholder: 0b}]
    if keyword_set(print_datatype) then begin
        print, 'Suported data type: '
        ids = type_dispatch.id
        foreach id, ids do print, '  * '+id
        return
    endif

;---Dispatch patterns.
    if n_elements(datatype) eq 0 then begin
        errmsg = handle_error('No input datatype ...')
        return
    endif
    ids = type_dispatch.id
    index = where(ids eq datatype, count)
    if count eq 0 then begin
        errmsg = handle_error('Do not support type '+datatype+' yet ...')
        return
    endif
    myinfo = type_dispatch[index[0]]
    if n_elements(time_var_name) ne 0 then myinfo.time_var_name = time_var_name
    if n_elements(time_var_type) ne 0 then myinfo.time_var_type = time_var_type


;---Find files, read variables, and store them in memory.
    files = prepare_file(files=files, errmsg=errmsg, $
        file_times=file_times, index_file=index_file, time=time, $
        stay_local=stay_local, sync_index=sync_index, $
        sync_files=sync_files, sync_after=sync_time, $
        _extra=myinfo)
    if errmsg ne '' then begin
        errmsg = handle_error('Error in finding files ...')
        return
    endif
    read_and_store_var, files, time_info=time, times=times, errmsg=errmsg, $
        in_vars=in_vars, out_vars=out_vars, generic_time=generic_time, _extra=myinfo
    if errmsg ne '' then begin
        errmsg = handle_error('Error in reading or storing data ...')
        return
    endif
end

themis_read_asi, /print_datatype
time = time_double(['2014-08-28/10:00','2014-08-28/10:03'])
;themis_read_asi, time, 'cal', site='whit'
themis_read_asi, time, 'ast', site='whit'
themis_read_asi, time, 'asf', site='whit'
end