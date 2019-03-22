;+
; Read RBSP EFW data.
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
;
;-
pro rbsp_read_efw, time, id=datatype, probe=probe, $
    print_datatype=print_datatype, errmsg=errmsg, $
    in_vars=in_vars, out_vars=out_vars, files=files, version=version, $
    local_root=local_root, remote_root=remote_root, $
    sync_after=sync_after, file_times=file_times, index_file=index_file, skip_index=skip_index, $
    sync_index=sync_index, sync_files=sync_files, stay_local=stay_loca, $
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
    if keyword_set(print_datatype) then probe = 'x'
    if n_elements(probe) eq 0 then begin
        errmsg = handle_error('No input probe ...')
        return
    endif
    if n_elements(out_vars) ne n_elements(in_vars) then out_vars = in_vars

;---Default settings.
    if n_elements(local_root) eq 0 then local_root = join_path([default_local_root(),'data','rbsp'])
    if n_elements(remote_root) eq 0 then remote_root = 'https://cdaweb.gsfc.nasa.gov/pub/data/rbsp'
    if n_elements(version) eq 0 then version = 'v[0-9]{2}'
    if n_elements(index_file) eq 0 then index_file = default_index_file()
    rbspx = 'rbsp'+probe

    type_dispatch = []
    type_dispatch = [type_dispatch, $
        {id: 'l1%vb1', $
        base_pattern: rbspx+'_l1_vb1_%Y%m%d_'+version+'.cdf', $
        remote_paths: ptr_new([remote_root,rbspx,'l1','efw','vb1','%Y']), $
        local_paths: ptr_new([local_root,rbspx,'efw','l1','vb1','%Y']), $
        ptr_in_vars: ptr_new(['vb1']), $
        ptr_out_vars: ptr_new(['vb1']), $
        time_var_name: 'epoch', $
        time_var_type: 'epoch16', $
        generic_time: 0, $
        cadence: 'day', $
        placeholder: 0b}]
    type_dispatch = [type_dispatch, $
        {id: 'l1%mscb1', $
        base_pattern: rbspx+'_l1_mscb1_%Y%m%d_'+version+'.cdf', $
        remote_paths: ptr_new([remote_root,rbspx,'l1','efw','mscb1','%Y']), $
        local_paths: ptr_new([local_root,rbspx,'efw','l1','mscb1','%Y']), $
        ptr_in_vars: ptr_new(['mscb1']), $
        ptr_out_vars: ptr_new(['mscb1']), $
        time_var_name: 'epoch', $
        time_var_type: 'epoch16', $
        generic_time: 0, $
        cadence: 'day', $
        placeholder: 0b}]
    type_dispatch = [type_dispatch, $
        {id: 'l2%euvw', $
        base_pattern: rbspx+'_efw-l2_e-hires-uvw_%Y%m%d_'+version+'.cdf', $
        remote_paths: ptr_new([remote_root,rbspx,'l2','efw','e-highres-uvw','%Y']), $
        local_paths: ptr_new([local_root,rbspx,'efw','l2','e-highres-uvw','%Y']), $
        ptr_in_vars: ptr_new(['e_hires_uvw']), $
        ptr_out_vars: ptr_new(['e_hires_uvw']), $
        time_var_name: 'epoch', $
        time_var_type: 'epoch16', $
        generic_time: 0, $
        cadence: 'day', $
        placeholder: 0b}]
    type_dispatch = [type_dispatch, $
        {id: 'l2%vsvy-highres', $
        base_pattern: rbspx+'_efw-l2_vsvy-hires_%Y%m%d_'+version+'.cdf', $
        remote_paths: ptr_new([remote_root,rbspx,'l2','efw','vsvy-highres','%Y']), $
        local_paths: ptr_new([local_root,rbspx,'efw','l2','vsvy-highres','%Y']), $
        ptr_in_vars: ptr_new(['vsvy']), $
        ptr_out_vars: ptr_new(['vsvy']), $
        time_var_name: 'epoch', $
        time_var_type: 'epoch16', $
        generic_time: 0, $
        cadence: 'day', $
        placeholder: 0b}]
    type_dispatch = [type_dispatch, $
        {id: 'l3%efw', $
        base_pattern: rbspx+'_efw-l3_%Y%m%d_'+version+'.cdf', $
        remote_paths: ptr_new([remote_root,rbspx,'l3','efw','%Y']), $
        local_paths: ptr_new([local_root,rbspx,'efw','l3','%Y']), $
        ptr_in_vars: ptr_new(['efield_inertial_frame_mgse']), $
        ptr_out_vars: ptr_new([rbspx+'_e_mgse']), $
        time_var_name: 'epoch', $
        time_var_type: 'epoch16', $
        generic_time: 0, $
        cadence: 'day', $
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
        skip_index=skip_index, $
        _extra=myinfo)
    if errmsg ne '' then begin
        errmsg = handle_error('Error in finding files ...')
        return
    endif

    read_and_store_var, files, time_info=time, errmsg=errmsg, $
        in_vars=in_vars, out_vars=out_vars, generic_time=generic_time, _extra=myinfo
    if errmsg ne '' then begin
        errmsg = handle_error('Error in reading or storing data ...')
        return
    endif

end


rbsp_read_efw, /print_datatype
utr0 = time_double(['2013-06-07/04:52','2013-06-07/05:02'])
rbsp_read_efw, utr0, 'efw', level='l3', 'b'
end
