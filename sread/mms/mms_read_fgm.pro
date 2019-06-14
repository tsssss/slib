;+
; Read MMS FGM data.
;
; time. A time or a time range in ut time. Set time to find files
;   automatically, or set files to read data in them directly.
; probe. A string set the probe to read data for.
; files. A string or an array of N full file names. Set this keyword
;   will set files directly.
; resolution. A string. Default is '4sec', can be '1sec','4sec','hires'.
;-
pro mms_read_fgm, time, id=datatype, probe=probe, $
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
    if n_elements(local_root) eq 0 then local_root = join_path([default_local_root(),'data','mms'])
    if n_elements(remote_root) eq 0 then remote_root = 'https://cdaweb.gsfc.nasa.gov/pub/data/mms'
    if n_elements(version) eq 0 then version = 'v[0-9.]{6}'
    if n_elements(index_file) eq 0 then index_file = default_index_file()
    mmsx = 'mms'+probe
    if n_elements(coord) eq 0 then coord = 'gsm'

    type_dispatch = hash()
    ; Level 2 survey.
    type_dispatch['l2%survey'] = dictionary($
        'base_pattern', 'mms'+probe+'_fgm_srvy_l2_%Y%m%d_'+version+'.cdf', $
        'remote_paths', [remote_root,'mms'+probe,'fgm','srvy','l2','%Y','%m'], $
        'local_paths', [local_root,'mms'+probe,'fgm','srvy','l2','%Y','%m'], $
        'in_vars', ['mms'+probe+'_fgm_b_'+coord+'_srvy_l2'], $
        'out_vars', ['mms'+probe+'_b_'+coord], $
        'time_var_name', 'Epoch', $
        'time_var_type', 'tt2000', $
        'generic_time', 0, $
        'cadence', 'day')
    ; Level 2 orbit data.
    type_dispatch['l2%orbit'] = dictionary($
        'base_pattern', 'mms'+probe+'_fgm_srvy_l2_%Y%m%d_'+version+'.cdf', $
        'remote_paths', [remote_root,'mms'+probe,'fgm','srvy','l2','%Y','%m'], $
        'local_paths', [local_root,'mms'+probe,'fgm','srvy','l2','%Y','%m'], $
        'in_vars', ['mms'+probe+'_fgm_r_'+coord+'_srvy_l2'], $
        'out_vars', ['mms'+probe+'_r_'+coord], $
        'time_var_name', 'Epoch_state', $
        'time_var_type', 'tt2000', $
        'generic_time', 0, $
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
    if not type_dispatch.haskey(datatype) then begin
        errmsg = handle_error('Do not support type '+datatype+' yet ...')
        return
    endif
    myinfo = (type_dispatch[datatype]).tostruct()
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

    in_vars = myinfo.in_vars
    out_vars = myinfo.out_vars
    read_and_store_var, files, time_info=time, errmsg=errmsg, $
        in_vars=in_vars, out_vars=out_vars, generic_time=generic_time, _extra=myinfo
    if errmsg ne '' then begin
        errmsg = handle_error('Error in reading or storing data ...')
        return
    endif


end

mms_read_fgm, /print_datatype
time = time_double(['2016-10-28/22:30:00','2016-10-29/01:00:00'])
mms_read_fgm, time, probe='1', id='l2%survey'
end
