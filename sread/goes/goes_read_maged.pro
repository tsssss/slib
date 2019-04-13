;+
; Read GOES MAGED data.
; Online data structure is messy, use goes_load_data first, implement later.
;-

pro goes_read_maged, time, id=datatype, probe=probe, print_datatype=print_datatype, errmsg=errmsg, $
    in_vars=in_vars, out_vars=out_vars, files=files, version=version, $
    local_root=local_root, remote_root=remote_root, $
    sync_after=sync_after, file_times=file_times, index_file=index_file, skip_index=skip_index, $
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
    if keyword_set(print_datatype) then probe = 'x'
    if n_elements(probe) eq 0 then begin
        errmsg = handle_error('No input probe ...')
        return
    endif
    if n_elements(out_vars) ne n_elements(in_vars) then out_vars = in_vars

;---Default settings.
    if n_elements(local_root) eq 0 then local_root = join_path([default_local_root(),'data','goes'])
    if n_elements(remote_root) eq 0 then remote_root = 'https://satdat.ngdc.noaa.gov/sem/goes/data'
    version = ''    ; dummy parameter.
    if n_elements(version) eq 0 then version = 'v[0-9]{2}'
    if n_elements(index_file) eq 0 then index_file = default_index_file()
    pre0 = 'g'+probe

end
