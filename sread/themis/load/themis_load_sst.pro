;+
; Read THEMIS SST data.
;
; input_time_range. A time range in unix time or string. Set time to find files
;   automatically, or set files to read data in them directly.
; id=. A string sets the data type to read. Check supported ids by setting
;   print_datatype.
; print_datatype=. A boolean. Set to print all supported ids.
; local_root=. A string to set the local root directory.
; local_files=. A string or an array of N full file names. Set to fine
;   tuning the files to read data from.
; file_times=. An array of N times. Set to fine tuning the times of the files.
; return_request=. A boolean, set to return dispatched request.
;-

function themis_load_sst, input_time_range, id=datatype, probe=probe, $
    print_datatype=print_datatype, errmsg=errmsg, $
    local_files=files, file_times=file_times, version=version, $
    local_root=local_root, remote_root=remote_root, $
    return_request=return_request

    compile_opt idl2
    on_error, 0
    errmsg = ''

;---Check inputs.
    sync_threshold = 0
    probes = themis_get_probes()
    index = where(probes eq probe, count)
    if count eq 0 then begin
        errmsg = 'Invalid probe: '+probe[0]+' ...'
        return, ''
    endif
    if n_elements(local_root) eq 0 then local_root = join_path([default_local_root(),'themis'])
    if n_elements(remote_root) eq 0 then remote_root = 'http://themis.ssl.berkeley.edu/data/themis'
    if n_elements(version) eq 0 then version = 'v[0-9]{2}'

    if size(input_time_range[0],type=1) eq 7 then begin
        time_range = time_double(input_time_range)
    endif else begin
        time_range = input_time_range
    endelse

;---Init settings.
    thx = 'th'+probe

    ; Level 2, electron.
    base_name = thx+'_l2_sst_%Y%m%d_'+version+'.cdf'
    local_path = [local_root,thx,'l2','sst','%Y']
    remote_path = [remote_root,thx,'l2','sst','%Y']
    valid_range = [time_double('2007-03-09'),systime(1)]
    request = dictionary($
        'pattern', dictionary($
            'remote_file', join_path([remote_path,base_name]), $
            'remote_index_file', join_path([remote_path,'']), $
            'local_file', join_path([local_path,base_name]), $
            'local_index_file', join_path([local_path,default_index_file(/sync)])), $
        'valid_range', time_double(valid_range), $
        'sync_threshold', sync_threshold, $
        'cadence', 'day', $
        'extension', fgetext(base_name) )
    if keyword_set(return_request) then return, request

;---Find files, read variables, and store them in memory.
    files = prepare_files(request=request, errmsg=errmsg, local_files=files, $
        file_times=file_times, time=time_range, nonexist_files=nonexist_files)

    if n_elements(files) eq 0 then return, '' else return, files

end

time_range = ['2008-01-19','2008-01-21']
probe = 'a'
files = themis_load_sst(time_range, probe=probe, errmsg=errmsg)
end