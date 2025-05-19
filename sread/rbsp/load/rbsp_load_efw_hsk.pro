;+
; Read RBSP EFW data.
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
;-
function rbsp_load_efw_hsk, input_time_range, id=datatype, probe=probe, $
    print_datatype=print_datatype, errmsg=errmsg, $
    local_files=files, file_times=file_times, version=version, $
    local_root=local_root, $
    remote_root=remote_root

    compile_opt idl2
    on_error, 0
    errmsg = ''
    retval = ''


;---Check inputs.
    sync_threshold = 86400d*120
    if n_elements(probe) eq 0 then probe = 'a'
    if n_elements(remote_root) eq 0 then remote_root = 'http://themis.ssl.berkeley.edu/data/rbsp'
    if n_elements(local_root) eq 0 then local_root = join_path([default_local_root(),'rbsp'])
    if n_elements(version) eq 0 then version = 'v[0-9]{2}'


;---Init settings.
    type_dispatch = hash()
    rbspx = 'rbsp'+probe
    prefix = 'rbsp'+probe+'_'

    ; Level 1.
    case probe of
        'a': valid_range = ['2012-09-05','2019-10-14/24:00']
        'b': valid_range = ['2012-09-05','2019-07-16/24:00']
    endcase
    foreach key, ['beb_analog'] do begin
        type = 'hsk_'+key
        base_name = prefix+'l1_'+type+'_%Y%m%d_'+version+'.cdf'
        local_path = [local_root,rbspx,'efw','l1',type,'%Y']
        remote_path = [remote_root,rbspx,'l1',type,'%Y']
        type_dispatch[type] = dictionary($
            'pattern', dictionary($
                'local_file', join_path([local_path,base_name]), $
                'local_index_file', join_path([local_path,default_index_file(/sync)]), $
                'remote_file', join_path([remote_path,base_name]), $
                'remote_index_file', join_path([remote_path,''])), $
            'valid_range', time_double(valid_range), $
            'sync_threshold', sync_threshold, $
            'cadence', 'day', $
            'extension', fgetext(base_name) )
    endforeach

    if keyword_set(print_datatype) then begin
        print, 'Suported data type: '
        ids = type_dispatch.keys()
        foreach id, ids do print, '  * '+id
        return, ids
    endif


    if size(input_time_range[0],type=1) eq 7 then begin
        time_range = time_double(input_time_range)
    endif else begin
        time_range = input_time_range
    endelse

;---Dispatch patterns.
    if n_elements(datatype) eq 0 then begin
        errmsg = handle_error('No input datatype ...')
        return, retval
    endif
    if not type_dispatch.haskey(datatype) then begin
        errmsg = handle_error('Do not support type '+datatype+' yet ...')
        return, retval
    endif
    request = type_dispatch[datatype]

;---Find files, read variables, and store them in memory.
    files = prepare_files(request=request, errmsg=errmsg, local_files=files, $
        file_times=file_times, time=time_range, nonexist_files=nonexist_files)

    return, files

end

print, rbsp_load_efw(print_datatype=1)
time_range = time_double(['2013-06-07/04:52','2013-06-07/05:02'])
probe = 'b'

print, rbsp_load_efw_hsk(time_range, id='hsk_beb_analog', probe=probe)

end
