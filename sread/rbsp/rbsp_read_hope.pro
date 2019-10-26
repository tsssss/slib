;+
; Read RBSP HOPE data.
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
; release=. A string to set the release. Default is 'rel04'.
;-

pro rbsp_read_hope, time, id=datatype, probe=probe, $
    print_datatype=print_datatype, errmsg=errmsg, $
    local_files=files, file_times=file_times, version=version, $
    local_root=local_root, remote_root=remote_root, $
    release=release

    compile_opt idl2
    on_error, 0
    errmsg = ''


;---Check inputs.
    sync_threshold = 86400d*120
    if n_elements(probe) eq 0 then probe = 'x'
    if n_elements(local_root) eq 0 then local_root = join_path([default_local_root(),'data','rbsp'])
    if n_elements(remote_root) eq 0 then remote_root = 'https://cdaweb.gsfc.nasa.gov/pub/data/rbsp'
    if n_elements(version) eq 0 then version = 'v[0-9.]{5}'
    if n_elements(release) eq 0 then release = 'rel04'  ; updated 2019-06.


;--Init settings.
    type_dispatch = hash()
    ; Level 3 moments.
    case probe of
        'a': valid_range = ['2012-10-25']
        'b': valid_range = ['2012-10-26']
    endcase
    base_name = 'rbsp'+probe+'_'+release+'_ect-hope-mom-l3_%Y%m%d_'+version+'.cdf'
    local_path = [local_root,'rbsp'+probe,'hope','level3','mom_'+release,'%Y']
    remote_path = [remote_root,'rbsp'+probe,'l3','ect','hope','moments',release,'%Y']
    type_dispatch['l3%ele_n'] = dictionary($
        'pattern', dictionary($
            'local_file', join_path([local_path,base_name]), $
            'local_index_file', join_path([local_path,default_index_file(/sync)]), $
            'remote_file', join_path([remote_path,base_name]), $
            'remote_index_file', join_path([remote_path,''])), $
        'valid_range', time_double(valid_range), $
        'sync_threshold', sync_threshold, $
        'cadence', 'day', $
        'extension', fgetext(base_name), $
        'var_list', list($
            dictionary($
                'in_vars', 'Dens_e_200', $
                'out_vars', 'rbsp'+probe+'_ele_n', $
                'time_var_name', 'Epoch_Ele', $
                'time_var_type', 'Epoch')))
    ; Level 3 data.
    base_name = 'rbsp'+probe+'_'+release+'_ect-hope-pa-l3_%Y%m%d_'+version+'.cdf'
    local_path = [local_root,'rbsp'+probe,'hope','level3','pa_'+release,'%Y']
    remote_path = [remote_root,'rbsp'+probe,'l3','ect','hope','pitchangle',release,'%Y']
    type_dispatch['l3%pa'] = dictionary($
        'pattern', dictionary($
            'local_file', join_path([local_path,base_name]), $
            'local_index_file', join_path([local_path,default_index_file(/sync)]), $
            'remote_file', join_path([remote_path,base_name]), $
            'remote_index_file', join_path([remote_path,''])), $
        'valid_range', time_double(valid_range), $
        'sync_threshold', sync_threshold, $
        'cadence', 'day', $
        'extension', fgetext(base_name), $
        'var_list', list($
            dictionary($
                'in_vars', ['Epoch_Ele_DELTA','HOPE_ENERGY_Ele','FEDU'], $
                'out_vars', ['epoch_ele_delta','hope_energy_ele','fedu'], $
                'time_var_name', 'Epoch_Ele', $
                'time_var_type', 'Epoch'), $
            dictionary($
                'in_vars', ['Epoch_Ion_DELTA','HOPE_ENERGY_Ion','FPDU','FODU','FHEDU'], $
                'out_vars', ['epoch_ion_delta','hope_energy_ion','fpdu','fodu','fhedu'], $
                'time_var_name', 'Epoch_Ion', $
                'time_var_type', 'Epoch'), $
            dictionary($
                'in_vars', ['PITCH_ANGLE'], $
                'out_vars', ['pitch_angle'], $
                'generic_time', 1)))
    type_dispatch['l3%pa%electron'] = dictionary($
        'pattern', dictionary($
            'local_file', join_path([local_path,base_name]), $
            'local_index_file', join_path([local_path,default_index_file(/sync)]), $
            'remote_file', join_path([remote_path,base_name]), $
            'remote_index_file', join_path([remote_path,''])), $
        'valid_range', time_double(valid_range), $
        'sync_threshold', sync_threshold, $
        'cadence', 'day', $
        'extension', fgetext(base_name), $
        'var_list', list($
            dictionary($
                'in_vars', ['Epoch_Ele_DELTA','HOPE_ENERGY_Ele','FEDU'], $
                'out_vars', ['epoch_ele_delta','hope_energy_ele','fedu'], $
                'time_var_name', 'Epoch_Ele', $
                'time_var_type', 'Epoch'), $
            dictionary($
                'in_vars', ['PITCH_ANGLE'], $
                'out_vars', ['pitch_angle'], $
                'generic_time', 1)))
    type_dispatch['l3%pa%ion'] = dictionary($
        'pattern', dictionary($
            'local_file', join_path([local_path,base_name]), $
            'local_index_file', join_path([local_path,default_index_file(/sync)]), $
            'remote_file', join_path([remote_path,base_name]), $
            'remote_index_file', join_path([remote_path,''])), $
        'valid_range', time_double(valid_range), $
        'sync_threshold', sync_threshold, $
        'cadence', 'day', $
        'extension', fgetext(base_name), $
        'var_list', list($
            dictionary($
                'in_vars', ['Epoch_Ion_DELTA','HOPE_ENERGY_Ion','FPDU','FODU','FHEDU'], $
                'out_vars', ['epoch_ion_delta','hope_energy_ion','fpdu','fodu','fhedu'], $
                'time_var_name', 'Epoch_Ion', $
                'time_var_type', 'Epoch'), $
            dictionary($
                'in_vars', ['PITCH_ANGLE'], $
                'out_vars', ['pitch_angle'], $
                'generic_time', 1)))
    ; Level 2 data.
    case probe of
        'a': valid_range = ['2012-10-25']
        'b': valid_range = ['2012-10-25']
    endcase
    base_name = 'rbsp'+probe+'_'+release+'_ect-hope-sci-l2_%Y%m%d_'+version+'.cdf'
    local_path = [local_root,'rbsp'+probe,'hope','level2','sectors_'+release,'%Y']
    remote_path = [remote_root,'rbsp'+probe,'l2','ect','hope','sectors',release,'%Y']
    type_dispatch['l2%electron'] = dictionary($
        'pattern', dictionary($
            'local_file', join_path([local_path,base_name]), $
            'local_index_file', join_path([local_path,default_index_file(/sync)]), $
            'remote_file', join_path([remote_path,base_name]), $
            'remote_index_file', join_path([remote_path,''])), $
        'valid_range', time_double(valid_range), $
        'sync_threshold', sync_threshold, $
        'cadence', 'day', $
        'extension', fgetext(base_name), $
        'var_list', list($
            dictionary($
                'in_vars', ['Epoch_Ele_DELTA','HOPE_ENERGY_Ele','FEDU'], $
                'out_vars', ['epoch_ele_delta','hope_energy_ele','fedu'], $
                'time_var_name', 'Epoch_Ele', $
                'time_var_type', 'Epoch'), $
            dictionary($
                'in_vars', ['Sector_Collapse_Cntr','Energy_Collapsed','Epoch'], $
                'out_vars', ['sector_collapse_cntr','energy_collapsed','epoch'], $
                'generic_time', 1)))
    type_dispatch['l2%ion'] = dictionary($
        'pattern', dictionary($
            'local_file', join_path([local_path,base_name]), $
            'local_index_file', join_path([local_path,default_index_file(/sync)]), $
            'remote_file', join_path([remote_path,base_name]), $
            'remote_index_file', join_path([remote_path,''])), $
        'valid_range', time_double(valid_range), $
        'sync_threshold', sync_threshold, $
        'cadence', 'day', $
        'extension', fgetext(base_name), $
        'var_list', list($
            dictionary($
                'in_vars', ['Epoch_Ion_DELTA','HOPE_ENERGY_Ion','FPDU','FODU','FHEDU'], $
                'out_vars', ['epoch_ion_delta','hope_energy_ion','fpdu','fodu','fhedu'], $
                'time_var_name', 'Epoch_Ele', $
                'time_var_type', 'Epoch'), $
            dictionary($
                'in_vars', ['Sector_Collapse_Cntr','Energy_Collapsed','Epoch'], $
                'out_vars', ['sector_collapse_cntr','energy_collapsed','epoch'], $
                'generic_time', 1)))

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

end


time = time_double(['2013-03-14/00:00','2013-03-14/00:10'])
probe = 'a'
rbsp_read_hope, time, id='l2%electron', probe=probe
end
