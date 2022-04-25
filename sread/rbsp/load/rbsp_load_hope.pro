;+
; Read RBSP HOPE data.
;
; input_time_range. A time range in unix time or string. Set time to find files
;   automatically, or set files to read data in them directly.
; id=. A string sets the data type to read. Check supported ids by setting
;   print_datatype.
; print_datatype=. A boolean. Set to print all supported ids.
; probe=. A string set the probe to read data for.
; local_root=. A string to set the local root directory.
; local_files=. A string or an array of N full file names. Set to fine
;   tuning the files to read data from.
; file_times=. An array of N times. Set to fine tuning the times of the files.
; release=. A string to set the release. Default is 'rel04'.
;-

function rbsp_load_hope, input_time_range, id=datatype, probe=probe, $
    print_datatype=print_datatype, errmsg=errmsg, $
    local_files=files, file_times=file_times, version=version, $
    local_root=local_root, $
    release=release

    compile_opt idl2
    on_error, 0
    errmsg = ''


;---Check inputs.
    sync_threshold = 86400d*120
    if n_elements(probe) eq 0 then probe = 'x'
    if n_elements(remote_root) eq 0 then remote_root = 'https://cdaweb.gsfc.nasa.gov/pub/data/rbsp'
    if n_elements(local_root) eq 0 then local_root = join_path([default_local_root(),'rbsp'])
    if n_elements(version) eq 0 then version = 'v[0-9.]{5}'
    if n_elements(release) eq 0 then release = 'rel04'  ; updated 2019-06.

    if size(input_time_range[0],type=1) eq 7 then begin
        time_range = time_double(input_time_range)
    endif else begin
        time_range = input_time_range
    endelse


;---Init settings.
    type_dispatch = hash()
    ; Level 3 moments.
    case probe of
        'a': valid_range = ['2012-10-25','2019-10-14/24:00']
        'b': valid_range = ['2012-10-26','2019-07-16/24:00']
    endcase
    base_name = 'rbsp'+probe+'_'+release+'_ect-hope-mom-l3_%Y%m%d_'+version+'.cdf'
    local_path = [local_root,'rbsp'+probe,'hope','level3','mom_'+release,'%Y']
    remote_path = [remote_root,'rbsp'+probe,'l3','ect','hope','moments',release,'%Y']
    type_dispatch['l3%mom'] = dictionary($
        'pattern', dictionary($
            'local_file', join_path([local_path,base_name]), $
            'local_index_file', join_path([local_path,default_index_file(/sync)]), $
            'remote_file', join_path([remote_path,base_name]), $
            'remote_index_file', join_path([remote_path,''])), $
        'valid_range', time_double(valid_range), $
        'sync_threshold', sync_threshold, $
        'cadence', 'day', $
        'extension', fgetext(base_name) )

    ; Level 3 pitch angle.
    base_name = 'rbsp'+probe+'_'+release+'_ect-hope-pa-l3_%Y%m%d_'+version+'.cdf'
    local_path = [local_root,'rbsp'+probe,'hope','level3','pa_'+release,'%Y']
    remote_path = [remote_root,'rbsp'+probe,'l3','ect','hope','pitchangle',release,'%Y']
    type_dispatch['l3%pa'] = dictionary($
        'pattern', dictionary($
            'local_file', join_path([local_path,base_name]), $
            'local_index_file', join_path([local_path,default_index_file(/sync)]), $
            'remote_file', join_path([remote_path,base_name]), $
            'remote_index_file', join_path([remote_path,''])), $
        'valid_range', time_double(valid_range), $
        'sync_threshold', sync_threshold, $
        'cadence', 'day', $
        'extension', fgetext(base_name) )

    ; Level 2 data.
    case probe of
        'a': valid_range = ['2012-09-07','2019-10-14/24:00']
        'b': valid_range = ['2012-09-06','2019-07-16/24:00']
    endcase
    base_name = 'rbsp'+probe+'_'+release+'_ect-hope-sci-l2_%Y%m%d_'+version+'.cdf'
    local_path = [local_root,'rbsp'+probe,'hope','level2','sectors_'+release,'%Y']
    remote_path = [remote_root,'rbsp'+probe,'l2','ect','hope','sectors',release,'%Y']
    type_dispatch['l2%sector'] = dictionary($
        'pattern', dictionary($
            'local_file', join_path([local_path,base_name]), $
            'local_index_file', join_path([local_path,default_index_file(/sync)]), $
            'remote_file', join_path([remote_path,base_name]), $
            'remote_index_file', join_path([remote_path,''])), $
        'valid_range', time_double(valid_range), $
        'sync_threshold', sync_threshold, $
        'cadence', 'day', $
        'extension', fgetext(base_name) )

    if keyword_set(print_datatype) then begin
        print, 'Suported data type: '
        ids = type_dispatch.keys()
        foreach id, ids do print, '  * '+id
        return, ids
    endif


;---Dispatch patterns.
    if n_elements(datatype) eq 0 then begin
        errmsg = handle_error('No input datatype ...')
        return, ''
    endif
    if not type_dispatch.haskey(datatype) then begin
        errmsg = handle_error('Do not support type '+datatype+' yet ...')
        return, ''
    endif
    request = type_dispatch[datatype]

;---Find files, read variables, and store them in memory.
    files = prepare_files(request=request, errmsg=errmsg, local_files=files, $
        file_times=file_times, time=time_range, nonexist_files=nonexist_files)
    
    if n_elements(files) eq 0 then return, '' else return, files

end


time_range = time_double(['2013-01-01','2015-01-01'])
foreach probe, ['a','b'] do files = rbsp_load_hope(time_range, id='l3%pa', probe=probe)
end
