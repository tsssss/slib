;+
; Read omni data.
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
; version=. A string to set specific version of files. By default, the
;   program finds the files of the highest version.
; resolution=. A string for data resolution. Can be '1min','5min'. 1min by default.
;-
pro omni_read, time, id=datatype, $
    print_datatype=print_datatype, errmsg=errmsg, $
    local_files=files, file_times=file_times, version=version, $
    local_root=local_root, remote_root=remote_root, $
    resolution=resolution

    compile_opt idl2
    on_error, 0
    errmsg = ''

;---Check inputs.
    sync_threshold = 86400*365.25
    if n_elements(local_root) eq 0 then local_root = join_path([default_local_root(),'omni','omni_cdaweb'])
    if n_elements(remote_root) eq 0 then remote_root = 'https://cdaweb.gsfc.nasa.gov/pub/data/omni/omni_cdaweb'
    if n_elements(version) eq 0 then version = 'v[0-9]{2}'
    if n_elements(resolution) eq 0 then resolution = '1min'

;---Init settings.
    type_dispatch = hash()
    base_name = 'omni_hro_'+resolution+'_%Y%m01_'+version+'.cdf'
    local_path = [local_root,'hro_'+resolution,'%Y']
    remote_path = [remote_root,'hro_'+resolution,'%Y']
    types = dictionary()
    ; AE and Dst.
    types['ae_dst'] = dictionary($
        'in_vars', ['AE_INDEX','SYM_H'], $
        'out_vars', ['ae','dst'])
    types['sw'] = dictionary($
        'in_vars', ['BX_GSE','BY_GSM','BZ_GSM','Vx','Vy','Vz','proton_density','T','Pressure'], $
        'out_vars',['bx_gsm','by_gsm','bz_gsm','vx_gse','vy_gse','vz_gse','n','t','p'])
    types['pdyn'] = dictionary($
        'in_vars', ['Pressure'], $  ; Yes, this is dynamic pressure.
        'out_vars',['p'])


    foreach key, types.keys() do begin
        type_dispatch[key] = dictionary($
            'pattern', dictionary($
                'local_file', join_path([local_path,base_name]), $
                'local_index_file', join_path([local_path,default_index_file(/sync)]), $
                'remote_file', join_path([remote_path,base_name]), $
                'remote_index_file', join_path([remote_path,''])), $
            'sync_threshold', sync_threshold, $
            'cadence', 'month', $
            'extension', fgetext(base_name), $
            'var_list', list($
                dictionary($
                'in_vars', types[key].in_vars, $
                'out_vars', types[key].out_vars, $
                'time_var_name', 'Epoch', $
                'time_var_type', 'epoch')))
    endforeach

    if keyword_set(print_datatype) then begin
        print, 'Suported data type: '
        ids = type_dispatch.keys()
        foreach id, ids do print, '  * '+id
        return
    endif

;---Dispatch patterns.
    if n_elements(datatype) eq 0 then begin
        errmsg = handle_error('No input datatype ...')
        return
    endif
    if not type_dispatch.haskey(datatype) then begin
        errmsg = handle_error('Do not support type '+datatype+' yet ...')
        return
    endif
    request = type_dispatch[datatype]

;---Find files, read variables, and store them in memory.
    files = prepare_files(request=request, errmsg=errmsg, local_files=files, $
        file_times=file_times, time=time, nonexist_files=nonexist_files)

;---Read data from files and save to memory.
    read_files, time, files=files, request=request
    
    out_vars = list()
    foreach var_list, request.var_list do out_vars.add, var_list.out_vars, /extract
    foreach var, out_vars do begin
        get_data, var, times, data
        case var of
            'n': fillval = 999
            'p': fillval = 99
            't': fillval = 9999999
            else: fillval = 9999
        endcase
        index = where(data ge fillval, count)
        if count eq 0 then continue
        data[index] = !values.f_nan
        store_data, var, times, data
    endforeach

end


time = time_double(['2014-08-25','2014-09-05'])
omni_read, time, id='ae_dst'
omni_read, time, id='sw'

end
