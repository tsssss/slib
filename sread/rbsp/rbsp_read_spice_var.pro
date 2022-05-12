;+
; Read RBSP spice vars
;
; time. The time range in unix time.
; probe=. 'a' or 'b'.
; local_root=. The local root directory for saving rbsp data.
; remote_root=. The URL for grabing rbsp data.
; version=. Default is 'v08'.
;-

pro rbsp_read_spice_var, time, probe=probe, $
    version=version, local_root=local_root, remote_root=remote_root, $
    time_tag_offset=time_tag_offset, errmsg=errmsg

    compile_opt idl2
    on_error, 0
    errmsg = ''

;---Check inputs.
    sync_threshold = 0
    if n_elements(probe) eq 0 then probe = 'x'
    if n_elements(local_root) eq 0 then local_root = join_path([rbsp_efw_phasef_local_root()])
    if n_elements(remote_root) eq 0 then remote_root = join_path([rbsp_efw_phasef_get_server()])
    if n_elements(version) eq 0 then version = 'v08'
    if n_elements(coord) eq 0 then coord = 'gse'

;---Init settings.
    valid_range = rbsp_efw_phasef_get_valid_range('spice', probe=probe)
    rbspx = 'rbsp'+probe
    base_name = rbspx+'_spice_products_%Y_%m%d_'+version+'.cdf'
    local_path = [local_root,'efw_phasef','spice_var',rbspx,'%Y']
    remote_path = [remote_root,'efw_phasef','spice_var',rbspx,'%Y']


    prefix = 'rbsp'+probe+'_'
    in_vars = prefix+['r_gse', 'v_gse', $
        'q_uvw2gse', 'wsc_gse', $
        'mlt', 'mlat', 'lshell', $
        'sphase_ssha', 'spin_period', 'spin_phase']

    request = dictionary($
        'pattern', dictionary($
            'remote_file', join_path([remote_path,base_name]), $
            'remote_index_file', join_path([remote_path,'']), $
            'local_file', join_path([local_path,base_name]), $
            'local_index_file', join_path([local_path,default_index_file()])), $
        'valid_range', time_double(valid_range), $
        'cadence', 'day', $
        'extension', fgetext(base_name), $
        'var_list', list($
            dictionary($
                'in_vars', in_vars, $
                'time_var_name', 'Epoch', $
                'time_var_type', 'epoch')))

;---Find files, read variables, and store them in memory.
    files = prepare_files(request=request, errmsg=errmsg, local_files=files, $
        file_times=file_times, time=time, nonexist_files=nonexist_files)
    if n_elements(nonexist_files) ne 0 then begin
        foreach file, request.nonexist_files do begin
            file_time = file.file_time
            local_file = file.local_file
            rbsp_read_spice_gen_file, file_time, probe=probe, filename=local_file
        endforeach
        files = prepare_files(request=request, errmsg=errmsg, local_files=files, $
            file_times=file_times, time=time, nonexist_files=nonexist_files)
    endif

;---Read data from files and save to memory.
    read_files, time, files=files, request=request
    
;---Apply time tag correction.
    if n_elements(time_tag_offset) ne 0 then begin
        vars = request.var_list[0].in_vars
        foreach var, vars do begin
            get_data, var, times, data
            store_data, var, times+time_tag_offset, data
        endforeach
    endif

end


probe = 'b'
time_range = time_double(['2013-01-09','2013-01-12'])
rbsp_read_spice_var, time_range, probe=probe, time_tag_offset=0.5
stop
end
