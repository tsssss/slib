;+
; Load Arase MGF data.
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
;-

function arase_load_mgf, input_time_range, probe=probe, id=datatype, $
    print_datatype=print_datatype, errmsg=errmsg, $
    local_files=files, file_times=file_times, version=version, $
    local_root=local_root, remote_root=remote_root, $
    coord=coord
    

    compile_opt idl2
    on_error, 0
    errmsg = ''

;---Check inputs.
    sync_threshold = 0
    if n_elements(local_root) eq 0 then local_root = join_path([default_local_root(),'arase'])
    if n_elements(remote_root) eq 0 then remote_root = 'https://ergsc.isee.nagoya-u.ac.jp/data/ergsc/satellite/erg'
    if n_elements(version) eq 0 then version = 'v[0-9.]{5}'
    if n_elements(datatype) eq 0 then datatype = 'l2%8sec'


    if size(input_time_range[0],type=1) eq 7 then begin
        time_range = time_double(input_time_range)
    endif else begin
        time_range = input_time_range
    endelse

    if n_elements(coord) eq 0 then coord = 'gsm'

;---Init settings.
    type_dispatch = hash()
    valid_range = time_double(['2017-03-01'])

    ; Level 2.
    base_name = 'erg_mgf_l2_8sec_%Y%m%d_'+version+'.cdf'
    remote_path = [remote_root,'mgf','l2','8sec','%Y','%m']
    local_path = [local_root,'mgf','l2','8sec','%Y','%m']
    type_dispatch['l2%8sec'] = dictionary($
        'pattern', dictionary($
            'local_file', join_path([local_path,base_name]), $
            'local_index_file', join_path([local_path,default_index_file(/sync)]), $
            'remote_file', join_path([remote_path,base_name]), $
            'remote_index_file', join_path([remote_path,''])), $
        'valid_range', time_double(valid_range), $
        'sync_threshold', sync_threshold, $
        'cadence', 'day', $
        'extension', fgetext(base_name) )

    base_name = 'erg_mgf_l2_256hz_'+coord+'_%Y%m%d%H_'+version+'.cdf'
    remote_path = [remote_root,'mgf','l2','256hz','%Y','%m']
    local_path = [local_root,'mgf','l2','256hz','%Y']
    type_dispatch['l2%256hz'] = dictionary($
        'pattern', dictionary($
            'local_file', join_path([local_path,base_name]), $
            'local_index_file', join_path([local_path,default_index_file(/sync)]), $
            'remote_file', join_path([remote_path,base_name]), $
            'remote_index_file', join_path([remote_path,''])), $
        'valid_range', time_double(valid_range), $
        'sync_threshold', sync_threshold, $
        'cadence', 'hour', $
        'extension', fgetext(base_name) )
    
    base_name = 'erg_mgf_l2_64hz_'+coord+'_%Y%m%d%H_'+version+'.cdf'
    remote_path = [remote_root,'mgf','l2','64hz','%Y','%m']
    local_path = [local_root,'mgf','l2','64hz','%Y']
    type_dispatch['l2%64hz'] = dictionary($
        'pattern', dictionary($
        'local_file', join_path([local_path,base_name]), $
        'local_index_file', join_path([local_path,default_index_file(/sync)]), $
        'remote_file', join_path([remote_path,base_name]), $
        'remote_index_file', join_path([remote_path,''])), $
        'valid_range', time_double(valid_range), $
        'sync_threshold', sync_threshold, $
        'cadence', 'hour', $
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

time_range = time_double(['2019-01-01','2019-01-03'])
files = arase_load_mgf(time_range, id='l2%8sec', probe=probe)
end