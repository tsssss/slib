;+
; Read THEMIS ASI data.
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

function themis_load_asi, input_time_range, site=site, id=datatype, $
    print_datatype=print_datatype, errmsg=errmsg, $
    local_files=files, file_times=file_times, version=version, $
    local_root=local_root, remote_root=remote_root, $
    return_request=return_request

    compile_opt idl2
    on_error, 0
    errmsg = ''
    retval = !null


;---Check inputs.
    sync_threshold = 0
    if n_elements(site) eq 0 then begin
        errmsg = 'No input site ...'
        return, retval
    endif
    sites = themis_read_asi_sites()
    index = where(sites eq site, count)
    if count eq 0 then begin
        errmsg = 'Invalid site: '+site[0]+' ...'
        return, retval
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
    type_dispatch = hash()

    ; L1 ASF.
    valid_range = [time_double('2005'),systime(1)]
    base_name = 'thg_l1_asf_'+site+'_%Y%m%d%H_'+version+'.cdf'
    local_path = [local_root,'thg','l1','asi',site,'%Y','%m']
    remote_path = [remote_root,'thg','l1','asi',site,'%Y','%m']
    type_dispatch['l1%asf'] = dictionary($
        'pattern', dictionary($
            'local_file', join_path([local_path,base_name]), $
            'local_index_file', join_path([local_path,default_index_file(/sync)]), $
            'remote_file', join_path([remote_path,base_name]), $
            'remote_index_file', join_path([remote_path,''])), $
        'valid_range', time_double(valid_range), $
        'sync_threshold', sync_threshold, $
        'cadence', 'hour', $
        'extension', fgetext(base_name) )

    ; L1 AST.
    valid_range = [time_double('2005'),systime(1)]
    base_name = 'thg_l1_ast_'+site+'_%Y%m%d_'+version+'.cdf'
    local_path = [local_root,'thg','l1','asi',site,'%Y','%m']
    remote_path = [remote_root,'thg','l1','asi',site,'%Y','%m']
    type_dispatch['l1%ast'] = dictionary($
        'pattern', dictionary($
            'local_file', join_path([local_path,base_name]), $
            'local_index_file', join_path([local_path,default_index_file(/sync)]), $
            'remote_file', join_path([remote_path,base_name]), $
            'remote_index_file', join_path([remote_path,''])), $
        'valid_range', time_double(valid_range), $
        'sync_threshold', sync_threshold, $
        'cadence', 'day', $
        'extension', fgetext(base_name) )

    ; L2 Calibration data.
    base_name = 'thg_l2_asc_'+site+'_19700101_'+version+'.cdf'
    local_path = [local_root,'thg','l2','asi','cal']
    remote_path = [remote_root,'thg','l2','asi','cal']
    type_dispatch['l2%asc'] = dictionary($
        'pattern', dictionary($
            'local_file', join_path([local_path,base_name]), $
            'local_index_file', join_path([local_path,default_index_file(/sync)]), $
            'remote_file', join_path([remote_path,base_name]), $
            'remote_index_file', join_path([remote_path,''])), $
        'sync_threshold', sync_threshold, $
        'cadence', 'day', $
        'extension', fgetext(base_name) )


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
    if keyword_set(return_request) then return, request

;---Find files, read variables, and store them in memory.
    files = prepare_files(request=request, errmsg=errmsg, local_files=files, $
        file_times=file_times, time=time_range, nonexist_files=nonexist_files)

    if n_elements(files) eq 0 then return, retval else return, files

end


time_range = time_double(['2013-01-01','2013-01-01/01:00'])
site = 'atha'
files = themis_load_asi(time_range, site=site, id='l2%asc')
files = themis_load_asi(time_range, site=site, id='l1%ast')
;files = themis_load_asi(time_range, site=site, id='l1%asf')
end
