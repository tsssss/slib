;+
; Read RBSP EMFISIS data.
;
; input_time_range. A time range in unix time or string. Set time to find files
;   automatically, or set files to read data in them directly.
; id=. A string sets the data type to read. Check supported ids by setting
;   print_datatype.
; print_datatype=. A boolean. Set to print all supported ids.
; probe=. A string set the probe to read data for.
; local_root=. A string to set the local root directory.
; local_files=. A string or an array of N full file names. Set to fine
; remote_root=. A string to set the remote root directory.
;   tuning the files to read data from.
; file_times=. An array of N times. Set to fine tuning the times of the files.
;-

function rbsp_load_emfisis, input_time_range, id=datatype, probe=probe, $
    print_datatype=print_datatype, errmsg=errmsg, $
    local_files=files, file_times=file_times, version=version, $
    local_root=local_root, $
    remote_root=remote_root, $
    resolution=resolution, $
    coord=coord

    compile_opt idl2
    on_error, 0
    errmsg = ''
    retval = ''


;---Check inputs.
    sync_threshold = 86400d*120
    if n_elements(probe) eq 0 then probe = 'a'
    if n_elements(remote_root) eq 0 then remote_root = 'https://cdaweb.gsfc.nasa.gov/pub/data/rbsp'
    if n_elements(local_root) eq 0 then local_root = join_path([default_local_root(),'rbsp'])
    if n_elements(version) eq 0 then version = 'v[0-9.]*'
    if n_elements(resolution) eq 0 then resolution = '4sec'
    if n_elements(coord) eq 0 then coord = 'gsm'


;---Init settings.
    type_dispatch = hash()
    rbspx = 'rbsp'+probe
    prefix = 'rbsp'+probe+'_'

    ; Level 2, B UVW.
    case probe of
        'a': valid_range = ['2012-08-30','2019-10-14/24:00']
        'b': valid_range = ['2012-08-31','2019-07-16/24:00']
    endcase
    base_name = 'rbsp-'+probe+'_magnetometer_uvw_emfisis-l2_%Y%m%d_'+version+'.cdf'
    local_path = [local_root,rbspx,'emfisis','%Y','l2','magnetometer','uvw']
    remote_path = [remote_root,rbspx,'l2','emfisis','magnetometer','uvw','%Y']
    type_dispatch['l2%magnetometer'] = dictionary($
        'pattern', dictionary($
            'local_file', join_path([local_path,base_name]), $
            'local_index_file', join_path([local_path,default_index_file(/sync)]), $
            'remote_file', join_path([remote_path,base_name]), $
            'remote_index_file', join_path([remote_path,''])), $
        'valid_range', time_double(valid_range), $
        'sync_threshold', sync_threshold, $
        'cadence', 'day', $
        'extension', fgetext(base_name) )
    
    ; Level 2, HFR.
    foreach the_id, ['waveform','spectra','spectra-burst','spectra-merged'] do begin
        base_name = 'rbsp-'+probe+'_hfr-'+the_id+'_emfisis-l2_%Y%m%d_'+version+'.cdf'
        local_path = [local_root,rbspx,'emfisis','%Y','l2','hfr',the_id]
        remote_path = [remote_root,rbspx,'l2','emfisis','hfr',the_id,'%Y']
        type_dispatch['l2%hfr%'+the_id] = dictionary($
            'pattern', dictionary($
                'local_file', join_path([local_path,base_name]), $
                'local_index_file', join_path([local_path,default_index_file(/sync)]), $
                'remote_file', join_path([remote_path,base_name]), $
                'remote_index_file', join_path([remote_path,''])), $
            'valid_range', time_double(valid_range), $
            'sync_threshold', sync_threshold, $
            'cadence', 'day', $
            'extension', fgetext(base_name) )
    endforeach

    ; Level 2, WFR.
    foreach the_id, ['spectral-matrix-diagonal-merged','spectral-matrix-diagonal','spectral-matrix','waveform','waveform-continuous-burst'] do begin
        base_name = 'rbsp-'+probe+'_wfr-'+the_id+'_emfisis-l2_%Y%m%d_'+version+'.cdf'
        local_path = [local_root,rbspx,'emfisis','%Y','l2','hfr',the_id]
        remote_path = [remote_root,rbspx,'l2','emfisis','wfr',the_id,'%Y']
        type_dispatch['l2%wfr%'+the_id] = dictionary($
            'pattern', dictionary($
                'local_file', join_path([local_path,base_name]), $
                'local_index_file', join_path([local_path,default_index_file(/sync)]), $
                'remote_file', join_path([remote_path,base_name]), $
                'remote_index_file', join_path([remote_path,''])), $
            'valid_range', time_double(valid_range), $
            'sync_threshold', sync_threshold, $
            'cadence', 'day', $
            'extension', fgetext(base_name) )
    endforeach


    ; Level 3, B in given coord.
    resolutions = ['1sec','4sec','hires']
    coords = ['gei','geo','gse','gsm','sm']
    index = where(coords eq coord, count)
    if count eq 0 then begin
        errmsg = 'Input coord: '+coord+' does not suppored ...'
        print, 'Supported coord: '+strjoin(coords,',')+' ...'
        return, retval
    endif
    index = where(resolutions eq resolution, count)
    if count eq 0 then begin
        errmsg = 'Input resolution: '+resolution+' does not suppored ...'
        print, 'Supported coord: '+strjoin(resolutions,',')+' ...'
        return, retval
    endif
    case probe of
        'a': valid_range = ['2012-08-30','2019-10-14/24:00']
        'b': valid_range = ['2012-08-31','2019-07-16/24:00']
    endcase
    base_name = 'rbsp-'+probe+'_magnetometer_'+resolution+'-'+coord+'_emfisis-l3_%Y%m%d_'+version+'.cdf'
    local_path = [local_root,rbspx,'emfisis','%Y','l3','magnetometer',resolution,coord]
    remote_path = [remote_root,rbspx,'l3','emfisis','magnetometer',resolution,coord,'%Y']
    type_dispatch['l3%magnetometer'] = dictionary($
        'pattern', dictionary($
            'local_file', join_path([local_path,base_name]), $
            'local_index_file', join_path([local_path,default_index_file(/sync)]), $
            'remote_file', join_path([remote_path,base_name]), $
            'remote_index_file', join_path([remote_path,''])), $
        'valid_range', time_double(valid_range), $
        'sync_threshold', sync_threshold, $
        'cadence', 'day', $
        'extension', fgetext(base_name) )

    ; Level 4, density.
    case probe of
        'a': valid_range = ['2012-09-15','2019-10-12/24:00']
        'b': valid_range = ['2012-09-15','2019-07-15/24:00']
    endcase
    base_name = 'rbsp-'+probe+'_density_emfisis-l4_%Y%m%d_'+version+'.cdf'
    local_path = [local_root,rbspx,'emfisis','%Y','l4','density']
    remote_path = [remote_root,rbspx,'l4','emfisis','density','%Y']
    type_dispatch['l4%density'] = dictionary($
        'pattern', dictionary($
            'local_file', join_path([local_path,base_name]), $
            'local_index_file', join_path([local_path,default_index_file(/sync)]), $
            'remote_file', join_path([remote_path,base_name]), $
            'remote_index_file', join_path([remote_path,''])), $
        'valid_range', time_double(valid_range), $
        'sync_threshold', sync_threshold, $
        'cadence', 'day', $
        'extension', fgetext(base_name) )

    if keyword_set(print_datatype) then begin
        print, 'Suported data type: '
        ids = type_dispatch.keys()
        foreach id, ids do print, '  * '+id
        return, ids
    endif
    
    
    if size(input_time_range[0],type=1) eq 7 then begin
        time_range = time_double(input_time_range)
    endif else begin
        time_range = input_time_range
    endelse


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

;---Find files, read variables, and store them in memory.
    files = prepare_files(request=request, errmsg=errmsg, local_files=files, $
        file_times=file_times, time=time_range, nonexist_files=nonexist_files)

    return, files

end


print, rbsp_load_emfisis(/print_datatype)
time_range = time_double(['2013-06-07/04:52','2013-06-07/05:02'])
time_range = time_double(['2015-03-17','2015-03-18'])
probe = 'a'

file = rbsp_load_emfisis(time_range, id='l2%wfr%spectral-matrix-diagonal-merged')
stop
file = rbsp_load_emfisis(time_range, id='l2%hfr%spectra')
stop

resolutions = ['1sec','4sec','hires']
foreach res, resolutions do begin
    print, rbsp_load_emfisis(time_range, id='l3%magnetometer', probe=probe, resolution=res)
endforeach

end
