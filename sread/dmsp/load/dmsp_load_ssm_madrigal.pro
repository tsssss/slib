;+
; Load SSM data from Madrigal server.
;-

function dmsp_load_ssm_madrigal, input_time_range, probe=probe, id=datatype, $
    print_datatype=print_datatype, errmsg=errmsg, $
    local_files=files, file_times=file_times, version=version, $
    local_root=local_root, remote_root=remote_root, $
    return_request=return_request

    compile_opt idl2
    on_error, 0
    errmsg = ''

;---Check inputs.
    probes = dmsp_probes()
    index = where(probes eq probe, count)
    if count eq 0 then begin
        errmsg = 'Invalid probe: '+probe[0]+' ...'
        return, ''
    endif
    time_range = time_double(input_time_range)


;---Settings for local files.
    if n_elements(local_root) eq 0 then local_root = join_path([default_local_root(),'dmsp','madrigal'])
    probe_code = strmid(probe,1,2)
    local_path = [local_root,'dmsp'+probe,'%Y']
    local_base_name = 'dms_%Y%m%d_'+probe_code+'s1.*.hdf5'
    file_request = dictionary($
        'time_range', time_range, $
        'local_file_pattern', join_path([local_path,local_base_name]), $
        'cadence', 'day' )
        
    ; Try to search for files locally.
    local_files = prepare_local_file(file_request)
    if file_request.local_file_is_ready then return, local_files
    
    ; Try to search for files remotely.    
    madurl = 'http://cedar.openmadrigal.org'
    probe_code = strmid(probe, 1,2)
    instr_id = 8100  ; for DMSP, found by the block below.
    exp_id = 10100d +long64(probe_code)
    resolution_code = 's1'
    tr_jd = convert_time(time_range, from='unix', to='jd')    
    mad_path = join_path([local_root,'dmsp'+probe,'madrigal_tmp'])
    if file_test(mad_path) eq 0 then file_mkdir, mad_path
    madglobaldownload, madurl, mad_path, $
        'Sheng+Tian', 'ts0110@atmost.ucla.edu', 'UCLA', $
        tr_jd[0],tr_jd[1], instr_id, exp_id, 'hdf5'
    index_infos = file_search(mad_path, '*.hdf5')
    foreach file_info, file_request.local_file_list do begin
        ; We need to move the files over to the wanted path.
        local_files = lookup_index_per_file(file_info.local_file, lines=index_infos)
        foreach target_file, local_files, file_id do begin
            base = fgetbase(target_file)
            source_file = join_path([mad_path,base])
            ; Remove the redundant suffix.
            index = strpos(target_file, '.hdf5.hdf5')
            if index[0] ne -1 then begin
                target_file = strmid(target_file,0,index[0]+5)
                local_files[file_id] = target_file
            endif
            target_path = fgetpath(target_file)
            if file_test(target_path) eq 0 then file_mkdir, target_path
            file_move, source_file, target_file, overwrite=1
        endforeach
        file_info.local_files = local_files
    endforeach
    ; Cleanup.
    foreach file, index_infos do if file_test(file) eq 1 then file_delete, file
    file_delete, mad_path
    
    
    ; Done.
    local_files = list()
    foreach file_info, file_request.local_file_list do begin
        local_files.add, file_info.local_files, extract=1
    endforeach
    local_files = local_files.toarray()
    return, local_files
    
end


time_range = ['2013-06-01','2013-06-03']
probe = 'f18'
files = dmsp_load_ssm_madrigal(time_range, probe=probe)
end