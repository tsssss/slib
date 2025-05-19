
function rbsp_ld_rbspice, input_time_range, id=datatype, probe=probe, $
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
    if n_elements(version) eq 0 then version = 'v.*'
    if n_elements(release) eq 0 then release = 'rel04'  ; updated 2019-06.

    if size(input_time_range[0],type=1) eq 7 then begin
        time_range = time_double(input_time_range)
    endif else begin
        time_range = input_time_range
    endelse


;---Init settings.
    type_dispatch = hash()
    rbspx = 'rbsp'+probe
    prefix = 'rbsp'+probe+'_'

    ; Level 2.
    level_str = 'l2'
    l2_types = ['esrhelt','esrleht','isrhelt',$
        'tofxeh','tofxeion','tofxenonh','tofxphhhelt','tofxphhleht']
    foreach type, l2_types do begin
        base_name = 'rbsp-'+probe+'-rbspice_lev-2_'+type+'_%Y%m%d_'+version+'.cdf'
        remote_path = [remote_root,rbspx,level_str,'rbspice',type,'%Y']
        local_path = [local_root,rbspx,'rbspice',level_str,type,'%Y']
        type_dispatch[level_str+'%'+type] = dictionary($
            'pattern', dictionary($
                'local_file', join_path([local_path,base_name]), $
                'local_index_file', join_path([local_path,default_index_file(/sync)]), $
                'remote_file', join_path([remote_path,base_name]), $
                'remote_index_file', join_path([remote_path,''])), $
            'sync_threshold', sync_threshold, $
            'cadence', 'day', $
            'extension', fgetext(base_name) )
    endforeach
    

    ; Level 3.
    level_str = 'l3'
    types = ['esrhelt','leht','tofxeh','tofxhe','tofxeion','tofxeo',$
        'tofxphhhelt','tofxphhleht','tofxphohelt','tofxpholeht']
    l3_types = ['esrhelt','esrlht','isrhelt',$
        'pap_'+types, 'papap_'+types, $
        'tofx'+['eh','eion','enonh','phhhelt','phhleft']]
    foreach type, l3_types do begin
        base_name = 'rbsp-'+probe+'-rbspice_lev-3_'+type+'_%Y%m%d_'+version+'.cdf'
        remote_path = [remote_root,rbspx,level_str,'rbspice',type,'%Y']
        local_path = [local_root,rbspx,'rbspice',level_str,type,'%Y']
        type_dispatch[level_str+'%'+type] = dictionary($
            'pattern', dictionary($
                'local_file', join_path([local_path,base_name]), $
                'local_index_file', join_path([local_path,default_index_file(/sync)]), $
                'remote_file', join_path([remote_path,base_name]), $
                'remote_index_file', join_path([remote_path,''])), $
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


time_range = ['2013-01-01','2013-01-02']
foreach probe, ['a','b'] do begin
    print, rbsp_ld_rbspice(time_range, probe=probe, id='l3%esrhelt')
endforeach
end