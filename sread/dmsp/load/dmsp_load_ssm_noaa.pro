;+
; Load SSM data from noaa server.
;-

function dmsp_load_ssm_noaa_gen_file, file_time, probe=probe, filename=local_file, remote_root=remote_root, errmsg=errmsg

    retval = !null
    if file_test(local_file) ne 0 then file_delete, local_file
    prefix = 'dmsp'+probe+'_'

    ; The online data.
    local_path = fgetpath(local_file)
    remote_pattern = join_path([remote_root,probe,'ssm','%Y','%m'])
    remote_path = apply_time_to_pattern(remote_pattern, file_time)
    remote_index_file = remote_path
    local_index_file = join_path([local_path,'remote_index.html'])
    if file_test(local_index_file) eq 0 then download_file, local_index_file, remote_index_file
    
    ; Get the actual base file name.
    base_pattern = apply_time_to_pattern('PS.CKGWC_SC.U_DI.A_GP.SSMXX-'+$
        strupcase(probe)+'-R99990-B9999090-APSM_AR.GLOBAL_DD.%Y%m%d_TP.[0-9-]*_DF.MFR', file_time)
    base_name = fgetbase(lookup_index_file(base_pattern, local_index_file))
    local_file_unzip = join_path([local_path,base_name])
    local_file_zip = local_file_unzip+'.gz'
    remote_file = join_path([remote_path,base_name])+'.gz'
    
    ; Download file and unzip.
    download_file, local_file_zip, remote_file, errmsg=errmsg
    if errmsg ne '' then begin
        if file_test(local_file_zip) eq 1 then file_delete, local_file_zip
        return, retval
    endif
    file_gunzip, local_file_zip
    if file_test(local_file_unzip) eq 0 then begin
        errmsg = 'No data ...'
        return, retval
    endif


    ; Read data.
    nheader = 6
    lines = read_all_lines(local_file_unzip,skip_header=nheader)
    ntime = n_elements(lines)
    times = strarr(ntime)
    glats = strarr(ntime)
    glons = strarr(ntime)
    alts = strarr(ntime)
    ndim = 3
    b_xyz = strarr(ntime,ndim)
    db_xyz = strarr(ntime,ndim)
    for ii=0,ntime-1 do begin
        info = strsplit(lines[ii],' ',extract=1)
        times[ii] = info[0]
        glats[ii] = info[4]
        glons[ii] = info[5]
        alts[ii] = info[6]
        b_xyz[ii,*] = info[9:11]
        db_xyz[ii,*] = info[13:15]
    endfor
    times = time_double(times, tformat='YYYYDOYhhmmss.ffff')
    glats = float(glats)
    glons = float(glons)
    alts = float(alts)
    stop
    b_xyz = float(b_xyz)
    db_xyz = float(db_xyz)
    
    ;; Get SC position.
    ;rad = constant('rad')
    ;re = constant('re')
    ;diss = alts/re+1
    ;r_geo = [$
        ;[diss*cos(glats*rad)*cos(glons*rad)],$
        ;[diss*cos(glats*rad)*sin(glons*rad)],$
        ;[diss*sin(glats*rad)]]
    ;step = 20
    ;r_geo = sinterpol(r_geo[0:*:step,*], times[0:*:step], times)

    
    ;; Get the rotation matrix b/w GEO and XYZ (X is down, Y is velocity, Z is orbit normal.)
    ;v_geo = r_geo
    ;for ii=0,ndim-1 do v_geo[*,ii] = deriv(times,r_geo[*,ii])*re
    ;x_hat = -sunitvec(r_geo)    ; approx x.
    ;;x_hat = sinterpol(x_hat[0:*:step,*], times[0:*:step], times)
    ;y_hat = sunitvec(v_geo)     ; y.
    ;y_hat = sinterpol(y_hat[0:*:step,*], times[0:*:step], times)
    ;z_hat = sunitvec(vec_cross(x_hat,y_hat))    ; z.
    ;;x_hat = sunitvec(vec_cross(y_hat,z_hat))    ; make sure x,y,z are orthogonal.
    ;y_hat = sunitvec(vec_cross(z_hat,x_hat))    ; make sure x,y,z are orthogonal.
    ;m_xyz2geo = fltarr(ntime,ndim,ndim)
    ;m_xyz2geo[*,*,0] = x_hat
    ;m_xyz2geo[*,*,1] = y_hat
    ;m_xyz2geo[*,*,2] = z_hat
    ;b_geo = rotate_vector(b_xyz, m_xyz2geo)
    ;b_gsm = cotran(b_geo, times, 'geo2gsm')
    ;b_var = prefix+'b_gsm_noaa'
    ;store_data, b_var, times, b_gsm
    ;add_setting, b_var, smart=1, dictionary($
        ;'display_type', 'vector', $
        ;'short_name', 'B', $
        ;'unit', 'nT', $
        ;'coord', 'GSM' )
        
    ;r_gsm = cotran(r_geo, times, 'geo2gsm')
    ;r_var = prefix+'r_gsm_noaa'
    ;store_data, r_var, times, r_gsm
    ;add_setting, r_var, smart=1, dictionary($
        ;'display_type', 'vector', $
        ;'short_name', 'R', $
        ;'unit', 'Re', $
        ;'coord', 'GSM' )
    ;bmod_var = geopack_read_bfield(r_var=r_var, models='igrf')
    ;get_data, bmod_var, times, bmod_gsm
    ;db_gsm = b_gsm-bmod_gsm
    ;db_var = prefix+'db_gsm'
    ;store_data, db_var, times, db_gsm
    ;add_setting, db_var, smart=1, dictionary($
        ;'display_type', 'vector', $
        ;'short_name', 'dB', $
        ;'unit', 'nT', $
        ;'coord', 'GSM' )
        
        
    ;db_var = prefix+'db_xyz'
    ;store_data, db_var, times, db_xyz
    ;add_setting, db_var, smart=1, dictionary($
        ;'display_type', 'vector', $
        ;'short_name', 'dB', $
        ;'unit', 'nT', $
        ;'coord', 'XYZ' )
        
        
        
    ;db_var = prefix+'db_gsm_noaa'
    ;store_data, db_var, times, cotran(rotate_vector(db_xyz, m_xyz2geo),times,'geo2gsm')
    ;add_setting, db_var, smart=1, dictionary($
        ;'display_type', 'vector', $
        ;'short_name', 'dB', $
        ;'unit', 'nT', $
        ;'coord', 'GSM' )


    ; Save data to cdf.
    file_delete, local_file_zip, allow_nonexistent=1
    cdf_touch, local_file
    settings = dictionary($
        'text', 'Generated from NOAA ascii data, by Sheng Tian, ts0110@atmos.ucla.edu' )
    
    time_var = 'ut'
    cdf_save_var, time_var, value=times, filename=local_file
    cdf_save_setting, varname=time_var, filename=local_file, dictionary($
        'unit', 'sec', $
        'var_type', 'support_data' )

    var = prefix+'glat'
    val = glats
    settings = dictionary($
        'depend_0', time_var, $
        'unit', 'deg', $
        'short_name', 'GLat' )
    cdf_save_var, var, value=val, filename=local_file
    cdf_save_setting, varname=var, filename=local_file, settings

    var = prefix+'glon'
    val = glons
    settings = dictionary($
        'depend_0', time_var, $
        'unit', 'deg', $
        'short_name', 'GLon' )
    cdf_save_var, var, value=val, filename=local_file
    cdf_save_setting, varname=var, filename=local_file, settings

    var = prefix+'alt'
    val = alts
    settings = dictionary($
        'depend_0', time_var, $
        'unit', 'km', $
        'short_name', 'altitude' )
    cdf_save_var, var, value=val, filename=local_file
    cdf_save_setting, varname=var, filename=local_file, settings

    var = prefix+'b_xyz'
    val = b_xyz
    settings = dictionary($
        'depend_0', time_var, $
        'unit', 'nT', $
        'short_name', 'B', $
        'coord', 'XYZ', $
        'text', 'X is down, Y is velocity, Z is orbit normal.' )
    cdf_save_var, var, value=val, filename=local_file
    cdf_save_setting, varname=var, filename=local_file, settings

    var = prefix+'db_xyz'
    val = db_xyz
    settings = dictionary($
        'depend_0', time_var, $
        'unit', 'nT', $
        'short_name', 'dB', $
        'coord', 'XYZ', $
        'text', 'X is down, Y is velocity, Z is orbit normal.' )
    cdf_save_var, var, value=val, filename=local_file
    cdf_save_setting, varname=var, filename=local_file, settings

end



function dmsp_load_ssm_noaa, input_time_range, id=datatype, probe=probe, $
    print_datatype=print_datatype, errmsg=errmsg, $
    local_files=files, file_times=file_times, version=version, $
    local_root=local_root, remote_root=remote_root, $
    return_request=return_request


    compile_opt idl2
    on_error, 0
    errmsg = ''

;---Check inputs.
    sync_threshold = 0
    probes = dmsp_probes()
    index = where(probes eq probe, count)
    if count eq 0 then begin
        errmsg = 'Invalid probe: '+probe[0]+' ...'
        return, ''
    endif
    if n_elements(local_root) eq 0 then local_root = join_path([default_local_root(),'dmsp','noaa'])
    if n_elements(remote_root) eq 0 then remote_root = 'https://www.ncei.noaa.gov/data/dmsp-space-weather-sensors/access/'
    if n_elements(version) eq 0 then version = 'v01'

    if size(input_time_range[0],type=1) eq 7 then begin
        time_range = time_double(input_time_range)
    endif else begin
        time_range = input_time_range
    endelse

;---Init settings.
    type_dispatch = hash()

    valid_range = time_double('1990')
    base_name = 'dmsp-'+probe+'_ssm_%Y%m%d_'+version+'.cdf'
    local_path = [local_root,'dmsp'+probe,'ssm','%Y']
    type_dispatch['l2'] = dictionary($
        'pattern', dictionary($
            'local_file', join_path([local_path,base_name]), $
            'local_index_file', join_path([local_path,default_index_file(/sync)])), $
        'valid_range', time_double(valid_range), $
        'sync_threshold', sync_threshold, $
        'cadence', 'day', $
        'extension', fgetext(base_name) )

    if keyword_set(print_datatype) then begin
        print, 'Suported data type: '
        ids = type_dispatch.keys()
        foreach id, ids do print, '  * '+id
        return, ''
    endif

;---Dispatch patterns.
    if n_elements(datatype) eq 0 then datatype = 'l2'
    if not type_dispatch.haskey(datatype) then begin
        errmsg = handle_error('Do not support type '+datatype+' yet ...')
        return, ''
    endif
    request = type_dispatch[datatype]
    if keyword_set(return_request) then return, request

;---Find files, read variables, and store them in memory.
    files = prepare_files(request=request, errmsg=errmsg, local_files=files, $
        file_times=file_times, time=time_range, nonexist_files=nonexist_files)
    if n_elements(nonexist_files) ne 0 then begin
        foreach file, request.nonexist_files do begin
            file_time = file.file_time
            local_file = file.local_file
            local_file = dmsp_load_ssm_noaa_gen_file(file_time, probe=probe, filename=local_file, remote_root=remote_root)
        endforeach
        files = prepare_files(request=request, errmsg=errmsg, local_files=files, $
            file_times=file_times, time=time_range, nonexist_files=nonexist_files)
    endif

    if n_elements(files) eq 0 then return, '' else return, files

end


time_range = ['2013-05-01','2013-05-02']
probe = 'f18'
b_var = dmsp_read_bfield(time_range, probe=probe)
r_var = dmsp_read_orbit(time_range, probe=probe)
files = dmsp_load_ssm_noaa(time_range, probe=probe)
end