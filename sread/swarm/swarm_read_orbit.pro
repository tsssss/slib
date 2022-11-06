;+
; Load Swarm MAG data.
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
;-


; Should use the mechanism of LANL, sync with remote first and then unzip and delete other cdfs.

pro swarm_read_orbit, time, id=datatype, probe=probe, $
    coord=coord, $
    print_datatype=print_datatype, errmsg=errmsg, $
    local_files=files, file_times=file_times, version=version, $
    local_root=local_root, remote_root=remote_root

    compile_opt idl2
    on_error, 0
    errmsg = ''


;---Check inputs.
    sync_threshold = 86400d*120
    if n_elements(probe) eq 0 then probe = 'x'
    if n_elements(local_root) eq 0 then local_root = join_path([default_local_root(),'sdata','swarm'])
    if n_elements(version) eq 0 then version = '.*'
    if n_elements(coord) eq 0 then coord = 'gsm'
    up_probe = strupcase(probe)

    type_dispatch = hash()
    ; Level 1b.
    base_name = 'SW_OPER_MAG'+up_probe+'_LR_1B_%Y%m%dT.*_%Y%m%dT.*_'+version+'_MDR_MAG_LR.cdf'
    local_path = join_path([local_root,'swarm'+probe,'level1b','Current','MAGx_LR','%Y'])

    type_dispatch['1b%orbit'] = dictionary($
        'pattern', dictionary($
            'local_file', join_path([local_path,base_name]), $
            'local_index_file', join_path([local_path,default_index_file()])), $
        'sync_threshold', sync_threshold, $      ; sync if mtime is after t_now-sync_threshold.
        'cadence', 'day', $
        'extension', fgetext(base_name), $
        'var_list', list($
            dictionary($
            'in_vars', ['Longitude','Latitude','Radius'], $
            'time_var_name', 'Timestamp', $
            'time_var_type', 'epoch')))

    if keyword_set(print_datatype) then begin
        print, 'Suported data type: '
        ids = type_dispatch.keys()
        foreach id, ids do print, '  * '+id
        return
    endif


;---Dispatch patterns.
    datatype = '1b%orbit'
    request = type_dispatch[datatype]

;---Prepare files.
    files = prepare_files(request=request, errmsg=errmsg, local_files=files, $
        file_times=file_times, time=time, nonexist_files=nonexist_files)
    if n_elements(nonexist_files) ne 0 then begin
        swarm_load_ftp_data, time, id=datatype, probe=probe, files=files, file_times=file_times, data_root=local_root
        all_files = [files,nonexist_files]
        files = list()
        foreach file, all_files do begin
            if file_test(file) eq 0 then continue
            if files.where(file) ne !null then continue
            files.add, file
        endforeach
        files = files.toarray()
    endif

;---Read data from files and save to memory.
    read_files, time, files=files, request=request


;---Convert lat/lon/r to r_coord.
    re1 = 1d/constant('re')
    rad = constant('rad')
    glat = get_var_data('Latitude', times=times)*rad
    glon = get_var_data('Longitude')*rad
    rr = get_var_data('Radius')*re1*1e-3
    ntime = n_elements(times)
    r_geo = [$
        [cos(glon)*cos(glat)*rr], $
        [sin(glon)*cos(glat)*rr], $
        [sin(glat)*rr] ]
    r_coord = cotran(r_geo, times, 'geo2'+coord)

    prefix = 'swarm'+probe+'_'
    r_var = prefix+'r_'+coord
    store_data, r_var, times, r_coord
    add_setting, r_var, /smart, dictionary($
        'display_type', 'vector', $
        'unit', 'Re', $
        'short_name', 'R', $
        'coord', strupcase(coord), $
        'coord_labels', constant('xyz') )


end

time = time_double(['2014-08-28/09:30','2014-08-28/11:30'])
probe = 'a'
swarm_read_orbit, time, probe=probe
swarm_read_orbit, time, probe=probe, coord='mag'
prefix = 'swarm'+probe+'_'
r_mag = get_var_data(prefix+'r_mag', times=times)
dis = snorm(r_mag)
deg = constant('deg')
mlat = asin(r_mag[*,2]/dis)*deg
mlon = atan(r_mag[*,1],r_mag[*,0])*deg
mlt = mlon2mlt(mlon, times)
store_data, prefix+'mlt', times, mlt, limits={ytitle:'(hr)', labels:'MLT'}
store_data, prefix+'mlat', times, mlat, limits={ytitle:'(deg)', labels:'MLat'}
tplot, prefix+['mlt','mlat','db_nec'], trange=time

end
