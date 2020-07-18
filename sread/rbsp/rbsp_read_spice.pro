;+
; Read RBSP spice products, including orbit and quaternion.
; c.f. rbsp_gen_spice_product if data for given times do not exist.
;
; time. A time or a time range in ut time. Set time to find files
;   automatically, or set files to read data in them directly.
; id=. A string sets the data type to read. Check supported ids by setting
;   print_datatype.
; print_datatype=. A boolean. Set to print all supported ids.
; probe=. A string set the probe to read data for.
; local_root=. A string to set the local root directory.
; remote_root=. A string to set the remote root directory.
; local_files=. A string or an array of N full file names. Set to fine
;   tuning the files to read data from.
; file_times=. An array of N times. Set to fine tuning the times of the files.
; version=. A string to set specific version of files. By default, the
;   program finds the files of the highest version.
;-
pro rbsp_read_spice, time, id=datatype, probe=probe, coord=coord, $
    print_datatype=print_datatype, errmsg=errmsg, $
    local_files=files, file_times=file_times, version=version, $
    local_root=local_root, remote_root=remote_root

    compile_opt idl2
    on_error, 0
    errmsg = ''

;---Check inputs.
    sync_threshold = 0
    if n_elements(probe) eq 0 then probe = 'x'
    if n_elements(local_root) eq 0 then local_root = join_path([default_local_root(),'sdata','rbsp'])
    if n_elements(version) eq 0 then version = 'v04'
    if n_elements(coord) eq 0 then coord = 'gsm'

;---Init settings.
    type_dispatch = hash()
    valid_range = rbsp_info('spice_data_range', probe=probe)
    rbspx = 'rbsp'+probe
    base_name = rbspx+'_spice_products_%Y_%m%d_'+version+'.cdf'
    local_path = [local_root,rbspx,'spice_product','%Y']
    ; Orbit variables.
    type_dispatch['orbit'] = dictionary($
        'pattern', dictionary($
            'local_file', join_path([local_path,base_name]), $
            'local_index_file', join_path([local_path,default_index_file()])), $
        'valid_range', time_double(valid_range), $
        'cadence', 'day', $
        'extension', fgetext(base_name), $
        'var_list', list($
            dictionary($
                'in_vars', rbspx+'_r_'+coord, $
                'time_var_name', 'time', $
                'time_var_type', 'unix')))
    ; Velocity variables.
    type_dispatch['sc_vel'] = dictionary($
        'pattern', dictionary($
            'local_file', join_path([local_path,base_name]), $
            'local_index_file', join_path([local_path,default_index_file()])), $
        'valid_range', time_double(valid_range), $
        'cadence', 'day', $
        'extension', fgetext(base_name), $
        'var_list', list($
            dictionary($
                'in_vars', rbspx+'_v_'+coord, $
                'time_var_name', 'time', $
                'time_var_type', 'unix')))
    ; Quaternion.
    type_dispatch['quaternion'] = dictionary($
        'pattern', dictionary($
            'local_file', join_path([local_path,base_name]), $
            'local_index_file', join_path([local_path,default_index_file()])), $
        'valid_range', time_double(valid_range), $
        'cadence', 'day', $
        'extension', fgetext(base_name), $
        'var_list', list($
            dictionary($
                'in_vars', rbspx+'_q_uvw2'+coord, $
                'time_var_name', 'time', $
                'time_var_type', 'unix')))

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

end



probes = ['a']
secofday = constant('secofday')
local_root = join_path([default_local_root(),'sdata','rbsp'])
foreach probe, probes do begin
    rbspx = 'rbsp'+probe
    local_path = [local_root,rbspx,'spice_product_v08','YYYY']
    valid_range = rbsp_info('spice_data_range', probe=probe)
    days = make_bins(valid_range+[0,-1], secofday, /inner)
    foreach day, days do begin
        lprmsg, 'Processing '+time_string(day)+' ...'
        base_name = rbspx+'_spice_products_YYYY_MMDD_v08.cdf'
        data_file = time_string(day, tformat=join_path([local_path,base_name]))
        if file_test(data_file) eq 1 then continue
        rbsp_read_spice_gen_file, day, probe=probe, filename=data_file
    endforeach
endforeach
end