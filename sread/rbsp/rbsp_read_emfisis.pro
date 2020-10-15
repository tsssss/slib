;+
; Read RBSP EMFISIS data.
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
; resolution=. A string for data resolution. Default is 4sec.
; coordinate=. A string to set vector coordinate, 'gsm' by default.
;-
pro rbsp_read_emfisis, time, id=datatype, probe=probe, $
    print_datatype=print_datatype, errmsg=errmsg, $
    local_root=local_root, remote_root=remote_root, $
    resolution=resolution, coordinate=coord

    compile_opt idl2
    on_error, 0
    errmsg = ''


;---Check inputs.
    sync_threshold = 86400d*120
    if n_elements(probe) eq 0 then probe = 'x'
    if n_elements(local_root) eq 0 then local_root = join_path([default_local_root(),'data','rbsp'])
    if n_elements(remote_root) eq 0 then remote_root = 'http://cdaweb.gsfc.nasa.gov/pub/data/rbsp'
    if n_elements(version) eq 0 then version = 'v[0-9.]{5}'
    if n_elements(resolution) eq 0 then resolution = '4sec'
    if n_elements(coord) eq 0 then coord = 'gsm'


;---Init settings.
    type_dispatch = hash()
    rbspx = 'rbsp'+probe
    prefix = 'rbsp'+probe+'_'
    ; Level 2, B UVW.
    base_name = 'rbsp-'+probe+'_magnetometer_uvw_emfisis-l2_%Y%m%d_'+version+'.cdf'
    local_path = [local_root,rbspx,'emfisis','%Y','l2','magnetometer','uvw']
    remote_path = [remote_root,rbspx,'l2','emfisis','magnetometer','uvw','%Y']
    type_dispatch['l2%magnetometer'] = dictionary($
        'pattern', dictionary($
            'local_file', join_path([local_path,base_name]), $
            'local_index_file', join_path([local_path,default_index_file(/sync)]), $
            'remote_file', join_path([remote_path,base_name]), $
            'remote_index_file', join_path([remote_path,''])), $
        'sync_threshold', sync_threshold, $
        'cadence', 'day', $
        'extension', fgetext(base_name), $
        'var_list', list($
            ; cal_state = 1 for bad data, mag_valid = 1 for bad data.
            dictionary($
                'in_vars', ['Mag','range_flag','calState','magInvalid'], $
                'out_vars', prefix+['b_uvw','range_flag','cal_state','mag_valid'], $
                'time_var_name', 'Epoch', $
                'time_var_type', 'tt2000')))
    ; Level 3, B in given coord.
    base_name = 'rbsp-'+probe+'_magnetometer_'+resolution+'-'+coord+'_emfisis-l3_%Y%m%d_'+version+'.cdf'
    local_path = [local_root,rbspx,'emfisis','%Y','l3','magnetometer',resolution,coord]
    remote_path = [remote_root,rbspx,'l3','emfisis','magnetometer',resolution,coord,'%Y']
    type_dispatch['l3%magnetometer'] = dictionary($
        'pattern', dictionary($
            'local_file', join_path([local_path,base_name]), $
            'local_index_file', join_path([local_path,default_index_file(/sync)]), $
            'remote_file', join_path([remote_path,base_name]), $
            'remote_index_file', join_path([remote_path,''])), $
        'sync_threshold', sync_threshold, $
        'cadence', 'day', $
        'extension', fgetext(base_name), $
        'var_list', list($
            dictionary($
                'in_vars', ['Mag'], $
                'out_vars', [rbspx+'_b_'+coord], $
                'time_var_name', 'Epoch', $
                'time_var_type', 'tt2000')))

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
;   v1.6.2 is using a different time format from v1.6.1. So use spedas first.
    if n_elements(time) eq 2 then timespan, time[0], time[1]-time[0], /second
    cdf2tplot, file=files, varformat=varformat, all=1, prefix='', suffix='', $
        tplotnames=tns, /convert_int1_to_int2

    all_invars = list()
    all_outvars = list()
    foreach var_list, request.var_list do begin
        if ~var_list.haskey('in_vars') then continue
        in_vars = var_list.in_vars
        if n_elements(in_vars) eq 0 then continue
        out_vars = var_list.haskey('out_vars')? var_list.out_vars: !null
        if n_elements(out_vars) ne n_elements(in_vars) then out_vars = in_vars
        all_invars.add, in_vars, /extract
        all_outvars.add, out_vars, /extract
    endforeach
    in_vars = all_invars.toarray()
    out_vars = all_outvars.toarray()

    foreach tn, tns do begin
        index = where(tn eq in_vars, count)
        if count eq 0 then begin
            store_data, tn, /delete
        endif else begin
            rename_var, tn, to=out_vars[index]
        endelse
    endforeach
    
    foreach var, out_vars do begin
        get_data, var, times, data
        index = lazy_where(times, '[]', time, count=count)
        if count eq 0 then continue
        store_data, var, times[index], data[index,*]
    endforeach
end


rbsp_read_emfisis, /print_datatype
utr0 = time_double(['2013-06-07/04:52','2013-06-07/05:02'])
rbsp_read_emfisis, utr0, id='l3%magnetometer', probe='b', resolution='4sec'
end
