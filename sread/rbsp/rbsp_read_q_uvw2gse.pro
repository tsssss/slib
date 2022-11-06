;+
; Read quaternion to rotate from UVW to GSE.
; This loads a better version than rbsp_read_quaternion.
;
; time. The time or time range in UT sec.
; probe=. A string of 'a' or 'b'.
;-
pro rbsp_read_q_uvw2gse, time, probe=probe, datatype=datatype, $
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
    if n_elements(version) eq 0 then version = 'v01'
    coord = 'gse'
    datatype = 'q_uvw2'+coord

;---Init settings.
    type_dispatch = hash()
    valid_range = rbsp_info('spice_data_range', probe=probe)
    rbspx = 'rbsp'+probe
    base_name = rbspx+'_q_uvw2gse_%Y_%m%d_'+version+'.cdf'
    local_path = [local_root,rbspx,'q_uvw2gse','%Y']
    ; Orbit variables.
    type_dispatch[datatype] = dictionary($
        'pattern', dictionary($
            'local_file', join_path([local_path,base_name]), $
            'local_index_file', join_path([local_path,default_index_file()])), $
        'valid_range', time_double(valid_range), $
        'cadence', 'day', $
        'extension', fgetext(base_name), $
        'var_list', list($
            dictionary($
                'in_vars', rbspx+'_q_uvw2'+coord, $
                'time_var_name', 'epoch', $
                'time_var_type', 'epoch')))

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
            rbsp_read_q_uvw2gse_gen_file, file_time, probe=probe, filename=local_file
        endforeach
        files = prepare_files(request=request, errmsg=errmsg, local_files=files, $
            file_times=file_times, time=time, nonexist_files=nonexist_files)
    endif

;---Read data from files and save to memory.
    read_files, time, files=files, request=request



    prefix = 'rbsp'+probe+'_'
    var = prefix+'q_uvw2'+coord
    settings = { $
        spin_tone: 'raw', $
        display_type: 'vector', $
        unit: '#', $
        short_name: 'Q', $
        coord: 'UVW2'+strupcase(coord), $
        coord_labels: ['a','b','c','d'], $
        colors: sgcolor(['red','green','blue','black'])}
    add_setting, var, settings, /smart

    ; Remove overlapping times.
    get_data, var, times, data
    index = uniq(times, sort(times))
    store_data, var, times[index], data[index,*]

end

probes = ['b']
full_time_range = time_double(['2012-09-01','2019-12-31'])
time_ranges = make_bins(full_time_range, 86400d)
ntime_range = n_elements(time_ranges)-1
foreach probe, probes do begin
    for ii=0,ntime_range-1 do begin
        time_range = time_ranges[ii:ii+1]
        rbsp_read_q_uvw2gse, time_range, probe=probe
    endfor
endforeach
end
