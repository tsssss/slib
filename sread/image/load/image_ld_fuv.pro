
function image_ld_fuv, input_time_range, id=datatype, probe=probe, $
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
    if n_elements(remote_root) eq 0 then remote_root = 'https://cdaweb.gsfc.nasa.gov/pub/data/image'
    if n_elements(local_root) eq 0 then local_root = join_path([default_local_root(),'image'])
    if n_elements(version) eq 0 then version = 'v.*'

    if size(input_time_range[0],type=1) eq 7 then begin
        time_range = time_double(input_time_range)
    endif else begin
        time_range = input_time_range
    endelse


;---Init settings.
    type_dispatch = hash()
    prefix = 'im_'

    ; k0.
    foreach type, ['sie','sip','wic'] do begin
        base_name = prefix+'k0_'+type+'_%Y%m%d_'+version+'cdf'
        type_str = type+'_k0'
        remote_path = [remote_root,'fuv',type_str,'%Y']
        local_path = [local_root,'fuv',type_str,'%Y']
        type_dispatch[type_str] = dictionary($
            'pattern', dictionary($
                'local_file', join_path([local_path,base_name]), $
                'local_index_file', join_path([local_path,default_index_file(/sync)]), $
                'remote_file', join_path([remote_path,base_name]), $
                'remote_index_file', join_path([remote_path,''])), $
            'sync_threshold', sync_threshold, $
            'cadence', 'day', $
            'extension', fgetext(base_name) )
        type_dispatch[type] = type_dispatch[type_str]
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

;---Find files, read  variables, and store them in memory.
    files = prepare_files(request=request, errmsg=errmsg, local_files=files, $
        file_times=file_times, time=time_range, nonexist_files=nonexist_files)

    if n_elements(files) eq 0 then return, '' else return, files

end


tr = ['2000-12-22/23:00','2000-12-22/23:30']
fn = image_ld_fuv(tr, id='wic_k0')
print, fn
end