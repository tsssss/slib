;+
; Read MMS FGM data.
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
; resolution=. A string for data resolution.
; coordinate=. A string to set vector coordinate, 'gsm' by default.
;-
pro mms_read_fgm, time, id=datatype, probe=probe, $
    print_datatype=print_datatype, errmsg=errmsg, $
    local_files=files, file_times=file_times, version=version, $
    local_root=local_root, remote_root=remote_root, $
    resolution=resolution, coordinate=coord

    compile_opt idl2
    on_error, 0
    errmsg = ''


;---Check inputs.
    if n_elements(probe) eq 0 then probe = 'x'
    if n_elements(local_root) eq 0 then local_root = join_path([default_local_root(),'mms'])
    if n_elements(remote_root) eq 0 then remote_root = 'https://cdaweb.gsfc.nasa.gov/pub/data/mms'
    if n_elements(version) eq 0 then version = 'v[0-9.]+'
    if n_elements(resolution) eq 0 then resolution = ''
    if n_elements(coord) eq 0 then coord = 'gsm'

    type_dispatch = hash()
    ; Level 2 survey.
    base_name = 'mms'+probe+'_fgm_srvy_l2_%Y%m%d_'+version+'.cdf'
    local_path = [local_root,'mms'+probe,'fgm','srvy','l2','%Y','%m']
    remote_path = [remote_root,'mms'+probe,'fgm','srvy','l2','%Y','%m']
    valid_range = ['2015-09-01']
    type_dispatch['l2%survey'] = dictionary($
        'pattern', dictionary($
            'local_file', join_path([local_path,base_name]), $
            'local_index_file', join_path([local_path,default_index_file(/sync)]), $
            'remote_file', join_path([remote_path,base_name]), $
            'remote_index_file', join_path([remote_path,''])), $
        'valid_range', time_double(valid_range), $
        'sync_threshold', 0, $
        'cadence', 'day', $
        'extension', fgetext(base_name), $
        'var_list', list($
            dictionary($
            'in_vars', ['mms'+probe+'_fgm_b_'+coord+'_srvy_l2'], $
            'out_vars', ['mms'+probe+'_b_'+coord], $
            'time_var_name', 'Epoch', $
            'time_var_type', 'tt2000')))
    ; Level 2 orbit data.
    base_name = 'mms'+probe+'_fgm_srvy_l2_%Y%m%d_'+version+'.cdf'
    local_path = [local_root,'mms'+probe,'fgm','srvy','l2','%Y','%m']
    remote_path = [remote_root,'mms'+probe,'fgm','srvy','l2','%Y','%m']
    type_dispatch['l2%orbit'] = dictionary($
        'pattern', dictionary($
            'local_file', join_path([local_path,base_name]), $
            'local_index_file', join_path([local_path,default_index_file()]), $
            'remote_file', join_path([remote_path,base_name]), $
            'remote_index_file', join_path([remote_path,''])), $
        'valid_range', time_double(valid_range), $
        'sync_threshold', 0, $
        'cadence', 'day', $
        'extension', fgetext(base_name), $
        'var_list', list($
            dictionary($
            'in_vars', ['mms'+probe+'_fgm_r_'+coord+'_srvy_l2'], $
            'out_vars', ['mms'+probe+'_r_'+coord], $
            'time_var_name', 'Epoch_state', $
            'time_var_type', 'tt2000')))

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

;---Read data from files and save to memory.
    read_files, time, files=files, request=request

end

mms_read_fgm, /print_datatype
time = time_double(['2016-10-28/22:30:00','2016-10-29/01:00:00'])
mms_read_fgm, time, probe='1', id='l2%survey'
end