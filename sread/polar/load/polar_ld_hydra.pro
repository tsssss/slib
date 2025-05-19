
function polar_ld_hydra, input_time_range, id=datatype, $
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
    if n_elements(local_root) eq 0 then local_root = join_path([default_local_root(),'polar'])
    if n_elements(remote_root) eq 0 then remote_root = 'https://cdaweb.gsfc.nasa.gov/pub/data/polar'
    if n_elements(version) eq 0 then version = 'v[0-9.]+'

    if size(input_time_range[0],type=1) eq 7 then begin
        time_range = time_double(input_time_range)
    endif else begin
        time_range = input_time_range
    endelse

;---Init settings.
    type_dispatch = hash()
    mission_str = 'polar'
    instr_str = 'hyd'


    valid_range = polar_valid_range()

    ; h0.
    the_key = 'h0'
    base_name = 'po_h0_'+instr_str+'_%Y%m%d_'+version+'.cdf'
    local_path = [local_root,'hydra','hyd_h0','%Y']
    remote_path = [remote_root,'hydra','hyd_h0','%Y']
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

    ; k0.
    the_key = 'k0'
    base_name = 'po_k0_'+instr_str+'_%Y%m%d_'+version+'.cdf'
    local_path = [local_root,'hydra','hydra_k0','%Y']
    remote_path = [remote_root,'hydra','hydra_k0','%Y']
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
    
    ; moments.
    the_key = 'mom'
    base_name = 'polar_hydra_moments-14sec_%Y%m%d_'+version+'.cdf'
    local_path = [local_root,'hydra','moments-14sec','%Y']
    remote_path = [remote_root,'hydra','moments-14sec','%Y']
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


time_range = ['1998-10-05','1998-10-06']
print, polar_ld_hydra(time_range, id='k0')
print, polar_ld_hydra(time_range, id='h0')
print, polar_ld_hydra(time_range, id='mom')
end