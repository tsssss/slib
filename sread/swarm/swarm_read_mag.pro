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

pro swarm_read_mag, time, id=datatype, probe=probe, $
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

    type_dispatch['1b%mag'] = dictionary($
        'pattern', dictionary($
            'local_file', join_path([local_path,base_name]), $
            'local_index_file', join_path([local_path,default_index_file()])), $
        'sync_threshold', sync_threshold, $      ; sync if mtime is after t_now-sync_threshold.
        'cadence', 'day', $
        'extension', fgetext(base_name), $
        'var_list', list($
            dictionary($
            'in_vars', ['B_NEC'], $
            'time_var_name', 'Timestamp', $
            'time_var_type', 'epoch')))

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
    if ~type_dispatch.haskey(datatype) then begin
        errmsg = handle_error('Do not support type '+datatype+' yet ...')
        return
    endif
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
    
    
    ; NEC (North-East-Center ITRF): (x, y, z)
    ; The x and y components lie in the horizontal plane, 
    ; pointing northward and eastward, respectively. 
    ; z points to the centre of gravity of the Earth.
    swarm_read_orbit, time, probe=probe
    prefix = 'swarm'+probe+'_'
    r_gsm = get_var_data(prefix+'r_gsm', times=times)
    ntime = n_elements(times)
    ndim = 3
    bmod_gsm = fltarr(ntime,ndim)
    for ii=0,ntime-1 do begin
        tilt = geopack_recalc(times[ii])
        rx = r_gsm[ii,0]
        ry = r_gsm[ii,1]
        rz = r_gsm[ii,2]

        ; in-situ B field.
        geopack_igrf_gsm, rx,ry,rz, bx,by,bz
        bmod_gsm[ii,*] = [bx,by,bz]
    endfor
    bmod_var = prefix+'bmod_gsm'
    store_data, bmod_var, times, bmod_gsm
    xyz = constant('xyz')
    add_setting, bmod_var, /smart, dictionary($
        'display_type', 'vector', $
        'unit', 'nT', $
        'short_name', 'Model B', $
        'coord', 'GSM', $
        'coord_labels', xyz )

    ; Convert B NEC to GSM.
    chat = -sunitvec(r_gsm)
    bmod_c = vec_dot(bmod_gsm, chat)
    zhat = fltarr(ntime,ndim)
    zhat[*,2] = 1
    zhat = cotran(zhat, times, 'geo2gsm')
    ehat = sunitvec(vec_cross(chat, zhat))
    nhat = vec_cross(ehat,chat)
    bmod_e = vec_dot(bmod_gsm, ehat)
    bmod_n = vec_dot(bmod_gsm, nhat)
    bmod_nec = [[bmod_n],[bmod_e],[bmod_c]]
    bmod_nec_var = prefix+'bmod_nec'
    store_data, bmod_nec_var, times, bmod_nec
    add_setting, bmod_var, /smart, dictionary($
        'display_type', 'vector', $
        'unit', 'nT', $
        'short_name', 'Model B', $
        'coord', 'NEC', $
        'coord_labels', xyz )
    
    db_nec = get_var_data('B_NEC')-bmod_nec
    db_var = prefix+'db_nec'
    store_data, db_var, times, db_nec
    add_setting, db_var, /smart, dictionary($
        'display_type', 'vector', $
        'unit', 'nT', $
        'short_name', 'dB', $
        'coord', 'NEC', $
        'coord_labels', xyz )
        

end

swarm_read_mag, /print_datatype
time = time_double(['2014-08-28/09:30','2014-08-28/11:30'])
swarm_read_mag, time, probe='a', id='1b%mag'

end
