;+
; Load MMS HPCA data.
;-

function mms_ld_hpca, input_time_range, id=datatype, probe=probe, $
    print_datatype=print_datatype, errmsg=errmsg, $
    local_files=files, file_times=file_times, version=version, $
    local_root=local_root, remote_root=remote_root, $
    return_request=return_request

    compile_opt idl2
    on_error, 0
    errmsg = ''
    retval = ''


;---Check inputs.
    sync_threshold = 0
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
    mission_str = 'mms'
    instr_str = 'hpca'

;---L2
    level_str = 'l2'

    ; survey.
    mode_str = 'srvy'
    valid_range = mms_valid_range([instr_str,level_str,mode_str], probe=probe)
    types = ['ion','moments','tof-counts']
    foreach type_str, types do begin
        keys = [level_str,mode_str,type_str]
        the_key = strjoin(keys,'%')
        base_name = mission_str+probe+'_'+instr_str+'_'+mode_str+'_'+level_str+'_'+type_str+'_%Y%m%d[0-9]{6}_'+version+'.cdf'
        local_path = [local_root,mission_str+probe,instr_str,mode_str,level_str,type_str,'%Y','%m']
        remote_path = [remote_root,mission_str+probe,instr_str,mode_str,level_str,type_str,'%Y','%m']
        type_dispatch[the_key] = dictionary($
            'pattern', dictionary($
                'local_file', join_path([local_path,base_name]), $
                'local_index_file', join_path([local_path,default_index_file(/sync)]), $
                'remote_file', join_path([remote_path,base_name]), $
                'remote_index_file', join_path([remote_path,''])), $
            'valid_range', time_double(valid_range), $
            'sync_threshold', 0, $
            'cadence', 'day', $
            'extension', fgetext(base_name) )
    endforeach

    ; burst.
    mode_str = 'brst'
    valid_range = mms_valid_range([instr_str,level_str,mode_str], probe=probe)
    types = ['ion','moments','tof-counts']
    foreach type_str, types do begin
        keys = [level_str,mode_str,type_str]
        the_key = strjoin(keys,'%')
        base_name = mission_str+probe+'_'+instr_str+'_'+mode_str+'_'+level_str+'_'+type_str+'_%Y%m%d0-9]{6}_'+version+'.cdf'
        local_path = [local_root,mission_str+probe,instr_str,mode_str,level_str,type_str,'%Y','%m']
        remote_path = [remote_root,mission_str+probe,instr_str,mode_str,level_str,type_str,'%Y','%m']
        type_dispatch[the_key] = dictionary($
            'pattern', dictionary($
                'local_file', join_path([local_path,base_name]), $
                'local_index_file', join_path([local_path,default_index_file(/sync)]), $
                'remote_file', join_path([remote_path,base_name]), $
                'remote_index_file', join_path([remote_path,''])), $
            'valid_range', time_double(valid_range), $
            'sync_threshold', 0, $
            'cadence', 'day', $
            'extension', fgetext(base_name) )
    endforeach


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
        file_times=file_times, time=time_range, nonexist_files=nonexist_files, get_all_match=get_all_match)
    
    if n_elements(files) eq 0 then return, '' else return, files

end


data_tr = time_double(['2016-08-04','2016-08-06'])
probe = '2'
files = mms_ld_hpca(data_tr, probe=probe, id='l2%srvy%ion')
end