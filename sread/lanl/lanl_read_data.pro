;+
;-
;

pro lanl_read_data, time, probe, print_datatype=print_datatype, $
    variable=vars, files=files, level=level, version=version
    
    nfile = n_elements(files)
    if n_elements(time) eq 0 and nfile eq 0 then begin
        message, 'no time or file is given ...', /continue
        if not keyword_set(print_datatype) then return
    endif
    if keyword_set(print_datatype) then probe = 'x'
    
    loc_root = join_path([sdiskdir('Research'),'data','lanl'])
    rem_root = 'https://www.ngdc.noaa.gov/stp/space-weather/satellite-data/satellite-systems/gps/data/'
    version = (n_elements(version) eq 0)? 'v[0-9.]{4}': version
    nsxx = 'ns'+probe
    
    type_dispatch = []
    type_dispatch = [type_dispatch, $
        {id: nsxx, $
        base_pattern: nsxx+'_%y%m%d_'+version+'.ascii', $
        remote_pattern: join_path([rem_root,nsxx]), $
        local_pattern: join_path([loc_root,nsxx]), $
        time_type: ''}]
    
    ; dispatch patterns.
    id = nsxx
    ids = type_dispatch.id
    idx = where(ids eq id, cnt)
    if cnt eq 0 then message, 'Do not support type '+id+' yet ...'
    myinfo = type_dispatch[idx[0]]
    
    ; find files to be read.
    file_cadence = 86400.
    if nfile eq 0 then begin
        update_t_threshold = 365.25d*86400  ; 1 year.
        index_file = 'remote-index.html'
        times = break_down_times(time, file_cadence)
        patterns = [myinfo.base_pattern, myinfo.local_pattern, myinfo.remote_pattern]
        files = find_data_file(time, patterns, index_file, $
            file_cadence=file_cadence, threshold=update_t_threshold)
    endif
    
end


utr0 = time_double(['2013-10-27','2013-10-28'])
lanl_read_data, utr0, '53'
end