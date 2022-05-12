;+
; Read MMS FGM data.
;-

function mms_load_fgm, input_time_range, id=datatype, probe=probe, $
    print_datatype=print_datatype, errmsg=errmsg, $
    local_files=files, file_times=file_times, version=version, $
    local_root=local_root

    compile_opt idl2
    on_error, 0
    errmsg = ''


;---Check inputs.
    sync_threshold = 86400d*120
    if n_elements(probe) eq 0 then probe = 'x'
    if n_elements(local_root) eq 0 then local_root = join_path([default_local_root(),'mms'])
    if n_elements(remote_root) eq 0 then remote_root = 'https://cdaweb.gsfc.nasa.gov/pub/data/mms'
    if n_elements(version) eq 0 then version = 'v[0-9.]+'

    if size(input_time_range[0],type=1) eq 7 then begin
        time_range = time_double(input_time_range)
    endif else begin
        time_range = input_time_range
    endelse

;---Init settings.
    type_dispatch = hash()
    ; L2 survey.
    base_name = 'mms'+probe+'_fgm_srvy_l2_%Y%m%d_'+version+'.cdf'
    local_path = [local_root,'mms'+probe,'fgm','srvy','l2','%Y','%m']
    remote_path = [remote_root,'mms'+probe,'fgm','srvy','l2','%Y','%m']
    valid_range = mms_valid_range('fgm%l2%survey', probe=probe)
    type_dispatch['l2%survey'] = dictionary($
        'pattern', dictionary($
            'local_file', join_path([local_path,base_name]), $
            'local_index_file', join_path([local_path,default_index_file(/sync)]), $
            'remote_file', join_path([remote_path,base_name]), $
            'remote_index_file', join_path([remote_path,''])), $
        'valid_range', time_double(valid_range), $
        'sync_threshold', 0, $
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

time_range = time_double(['2016-10-13','2016-10-14'])
probe = '1'
files = mms_load_fgm(time_range, probe=probe, id='l2%survey')
end