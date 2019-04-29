;+
; Read RBSP EMFISIS data.
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
; resolution. A string. Default is '4sec', can be '1sec','4sec','hires'.
;-
pro rbsp_read_emfisis, time, id=datatype, probe=probe, $
    resolution=resolution, coordinate=coord, $
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
    if n_elements(version) eq 0 then version = 'v[0-9.]{5}'
    if n_elements(index_file) eq 0 then index_file = default_index_file()
    rbspx = 'rbsp'+probe
    if n_elements(resolution) eq 0 then resolution = '4sec'
    if n_elements(coord) eq 0 then coord = 'gsm'

    type_dispatch = []
    ; Level 2, B UVW.
    type_dispatch = [type_dispatch, $
        {id: 'l2%magnetometer', $
        base_pattern: 'rbsp-'+probe+'_magnetometer_uvw_emfisis-l2_%Y%m%d_'+version+'.cdf', $
        remote_paths: ptr_new([remote_root,rbspx,'l2','emfisis','magnetometer','uvw','%Y']), $
        local_paths: ptr_new([local_root,rbspx,'emfisis','%Y','l2','magnetometer','uvw']), $
        ptr_in_vars: ptr_new(['Mag']), $
        ptr_out_vars: ptr_new([rbspx+'_b_uvw']), $
        time_var_name: 'Epoch', $
        time_var_type: 'tt2000', $
        generic_time: 0, $
        cadence: 'day', $
        placeholder: 0b}]
    ; Level 3, B in given coord.
    type_dispatch = [type_dispatch, $
        {id: 'l3%magnetometer', $
        base_pattern: 'rbsp-'+probe+'_magnetometer_'+resolution+'-'+coord+'_emfisis-l3_%Y%m%d_'+version+'.cdf', $
        remote_paths: ptr_new([remote_root,rbspx,'l3','emfisis','magnetometer',resolution,coord,'%Y']), $
        local_paths: ptr_new([local_root,rbspx,'emfisis','%Y','l3','magnetometer',resolution,coord]), $
        ptr_in_vars: ptr_new(['Mag']), $
        ptr_out_vars: ptr_new([rbspx+'_b_'+coord]), $
        time_var_name: 'Epoch', $
        time_var_type: 'tt2000', $
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

    if n_elements(time) eq 2 then timespan, time[0], time[1]-time[0], /second
    cdf2tplot, file=files, varformat=varformat, all=0, prefix='', suffix='', $
        tplotnames=tns, /convert_int1_to_int2
    in_vars = *myinfo.ptr_in_vars
    out_vars = *myinfo.ptr_out_vars
    foreach tn, tns do begin
        index = where(tn eq in_vars, count)
        if count eq 0 then store_data, tn, /delete else rename_var, tn, to=out_vars[index]
    endforeach

;   v1.6.2 is using a different time format from v1.6.1. So use spedas first.
;    in_vars = *myinfo.ptr_in_vars
;    out_vars = *myinfo.ptr_out_vars
;    read_and_store_var, files, time_info=time, errmsg=errmsg, $
;        in_vars=in_vars, out_vars=out_vars, generic_time=generic_time, _extra=myinfo
;    if errmsg ne '' then begin
;        errmsg = handle_error('Error in reading or storing data ...')
;        return
;    endif
end


rbsp_read_emfisis, /print_datatype
utr0 = time_double(['2013-06-07/04:52','2013-06-07/05:02'])
rbsp_read_emfisis, utr0, id='l3%magnetometer', probe='b', resolution='hires'
end
