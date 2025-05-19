;+
;-

function mms_ld_fpi_pad_ion_gen_file, input_time_range, probe=probe, filename=cdf_file, errmsg=errmsg

    errmsg = ''
    retval = !null

    date = time_double(input_time_range[0])
    secofday = constant('secofday')
    time_range = date+[0,secofday]

    prefix = 'mms'+probe+'_'
    mission_probe = 'mms'+probe
    instr_str = 'fpi'
    species = 'e'
    species_str = 'ion'
    mode_str = 'fast'
    level_str = 'l2'
    datatype_str = 'dis-dist'
    id = strjoin([level_str,mode_str,datatype_str],'%')
    files = mms_ld_fpi(time_range, probe=probe, id=id, errmsg=errmsg)
    if errmsg ne '' then return, retval
    
    
    ; Read data.
    prefix2 = prefix+'dis_'
    var_list = list()
    in_vars = [prefix2+['dist','energy','startdelphi_count']+'_'+mode_str]
    flux_var = in_vars[0]
    energy_var = in_vars[1]
    spin_var = in_vars[2]
    var_list.add, dictionary($
        'in_vars', in_vars, $
        'time_var_name', 'Epoch', $
        'time_var_type', 'tt2000' )
    read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg    
    if errmsg ne '' then return, retval

    ; Get the fluxs.
    fluxs = get_var_data(flux_var, times=times) ; in [ntime,nphi,ntheta,nen], in s^3/cm^6.
    ntime = n_elements(times)
    index = where(fluxs le 0, count)
    if count ne 0 then fluxs[index] = 0
    
    phi_var = prefix2+'phi_'+mode_str
    theta_var = prefix2+'theta_'+mode_str
    phis = cdf_read_var(phi_var, filename=files[0])     ; 0-360 deg.
    thetas = cdf_read_var(theta_var, filename=files[0]) ; 0-180 deg, co-lat.
    nphi = n_elements(phis)
    ntheta = n_elements(thetas)
    
    ; To uniform energy bins.
    en_bins = get_var_data(energy_var)  ; in [ntime,nen]
    nen_bin = n_elements(en_bins[0,*])
    en_centers = dblarr(nen_bin)
    for ii=0,nen_bin-1 do en_centers[ii] = median(en_bins[*,ii])
    de0 = mean(en_centers[1:nen_bin-1]/en_centers[0:nen_bin-2])
    tmp_fluxs = transpose(reform(fluxs,[ntime,nphi*ntheta,nen_bin]),[0,2,1])
    for ii=0,ntime-1 do begin
        interp_range = minmax(en_bins[ii,*])*[1d/de0,de0]
        tmp_fluxs[ii,*,*] = sinterpol(reform(tmp_fluxs[ii,*,*]),reform(en_bins[ii,*]),en_centers, interp_range=interp_range)
    endfor
    fluxs = transpose(tmp_fluxs,[0,2,1])    ; in [ntime,nphi*ntheta,nen]
    
    

    ; Rotate to FAC.
    rad = constant('rad')
    deg = constant('deg')
    
    
    cosp = cos(phis*rad)
    sinp = sqrt(1-cosp^2)
    cost = cos(thetas*rad)
    sint = sqrt(1-cost^2)

    ndim = 3
    flux_r_coords = fltarr(nphi,ntheta,ndim)
    for ii=0,nphi-1 do begin
        for jj=0,ntheta-1 do begin
            flux_r_coords[ii,jj,*] = -[sint[jj]*[cosp[ii],sinp[ii]],cost[jj]]
        endfor
    endfor
    
    
    coord = 'gse'
    data_time_range = time_range+[-1,1]*60  ; to ensure data coverage at the beginning and end of the day.
    b_var = lets_read_this(func='mms_read_bfield', data_time_range, probe=mission_probe, coord=coord)
    r_var = lets_read_this(func='mms_read_orbit', data_time_range, probe=mission_probe, coord=coord)
    options, [b_var,r_var], mission='mms'
    q_fac = lets_define_fac(b_var=b_var, r_var=r_var, time_var=flux_var)
    m_xxx2fac = qtom(get_var_data(q_fac))
    
    nsensor = nphi*ntheta
    r_coords = reform(flux_r_coords, [nsensor,ndim])    ; in [nsensor,ndim]
    r_fac = fltarr(ntime,nsensor,ndim)
    tmp_r_var = prefix+'tmp_r_'+coord
    for sid=0,nsensor-1 do begin
        the_r_coord = (fltarr(ntime)+1) # reform(r_coords[sid,*])
        r_fac[*,sid,*] = rotate_vector(the_r_coord, m_xxx2fac)
    endfor
    
    ; fac: [b,w,o], maps to [z,x,y]
    fac_phis = atan(r_fac[*,*,2],r_fac[*,*,1])*deg  ; in [ntime,nsensor]
    fac_thetas = acos(r_fac[*,*,0])*deg     ; colat, in [0,180].
    index = where(fac_phis lt 0, count)
    if count ne 0 then fac_phis[index] += 360  
    
    
    ; interp flux to uniform fac phi and theta.
    phi_grids = (phis # (fltarr(ntheta)+1))[*]
    theta_grids = ((fltarr(nphi)+1) # thetas)[*]
    ngrid = n_elements(phi_grids)
    full_fluxs = fltarr(ntime,ngrid,nen_bin)
    method = 'NearestNeighbor'
    method = 'InverseDistance'  ; this works much better.
    for tid=0,ntime-1 do begin
        the_fluxs = reform(fluxs[tid,*,*])    ; in [nsensor,nen]
        the_fac_phi = reform(fac_phis[tid,*])
        the_fac_theta = reform(fac_thetas[tid,*])
        index = where(finite(the_fac_phi,nan=1),count)
        if count eq 0 then begin
            qhull, the_fac_phi, the_fac_theta, triangles, sphere=dummy
            for eid=0,nen_bin-1 do full_fluxs[tid,*,eid] = $
                griddata(the_fac_phi, the_fac_theta, the_fluxs[*,eid], method=method, sphere=1, degree=1, triangles=triangles, $
                xout=phi_grids, yout=theta_grids)
        endif
    endfor
    
    ; Convert unit.
    mp = 1.67e-27   ; kg.
    qe = 1.6d-19    ; C.
    ;mm = me/(qe*1e6)
    ;cc = ((2*en_centers/mm)*1e5)^2    ; sqrt(2E/m) is velocity, the coefs are to make velocity in cm/s.
    cc = (sqrt(2*en_centers*qe/mp)*1e2)^4    ; sqrt(2E/m) is velocity, the coefs are to make velocity in cm/s.
    cc = cc/(4*!dpi)    ; this is from s^3/cm^6 to eV/cm^2-s-sr-eV
    ;cc = cc/2           ; to be consistent with mms_convert_flux_units Line 85, 97, and 106.
    for ii=0,nen_bin-1 do full_fluxs[*,*,ii] *= cc[ii]   ; fluxs in eV/cm^2-s-sr-eV.
    ;for ii=0,nen_bin-1 do full_fluxs[*,*,ii] /= (en_centers[ii]*1e-3)
    full_fluxs = reform(full_fluxs,[ntime,nphi,ntheta,nen_bin])


;---Save data
    pa_centers = thetas
    phi_centers = phis
;    spin_sectors = get_var_data(spin_var)

    gatt = dictionary($
        'title', 'MMS '+strupcase(instr_str)+' pitch angle distribution, calculated based on l2 data', $
        'text', 'Calculated by Sheng Tian at UCLA, email:ts0110@atmos.ucla.edu' )
    cdf_save_setting, gatt, filename=cdf_file

    time_var = 'time'
    vatt = dictionary($
        'FIELDNAM', 'Unix time', $
        'UNITS', 'sec', $
        'VAR_TYPE', 'support_data' )
    cdf_save_var, time_var, value=times, filename=cdf_file, cdf_type='CDF_DOUBLE'
    cdf_save_setting, vatt, varname=time_var, filename=cdf_file

    phi_var = prefix+'phi_centers'
    phi_unit = 'deg'
    vatt = dictionary($
        'FIELDNAM', 'Gyro phase at the center of each bin', $
        'UNITS', phi_unit, $
        'VAR_TYPE', 'support_data' )
    cdf_save_var, phi_var, value=phi_centers, filename=cdf_file, save_as_one=1
    cdf_save_setting, vatt, varname=phi_var, filename=cdf_file

    pa_var = prefix+'pa_centers'
    pa_unit = 'deg'
    vatt = dictionary($
        'FIELDNAM', 'Pitch angle at the center of each bin', $
        'UNITS', pa_unit, $
        'VAR_TYPE', 'support_data' )
    cdf_save_var, pa_var, value=pa_centers, filename=cdf_file, save_as_one=1
    cdf_save_setting, vatt, varname=pa_var, filename=cdf_file

    en_var = prefix+'en_centers'
    en_unit = 'eV'
    vatt = dictionary($
        'FIELDNAM', 'Energy at the center of each bin', $
        'UNITS', en_unit, $
        'VAR_TYPE', 'support_data' )
    cdf_save_var, en_var, value=en_centers, filename=cdf_file, save_as_one=1
    cdf_save_setting, vatt, varname=en_var, filename=cdf_file

    pad_var = prefix+'pad_'+instr_str+'_'+species_str
    pad_unit = 'eV/cm!U2!N-s-sr-eV'
    vatt = dictionary($
        'FIELDNAM', 'flux', $
        'UNITS', pad_unit, $
        'VAR_TYPE', 'data', $
        'DEPEND_0', time_var, $ ; in sec.
        'DEPEND_1', phi_var, $  ; in deg.
        'DEPEND_2', pa_var, $   ; in deg.
        'DEPEND_3', en_var, $   ; in eV.
        'species', species_str )
    cdf_save_var, pad_var, value=full_fluxs, filename=cdf_file
    cdf_save_setting, vatt, varname=pad_var, filename=cdf_file

    return, cdf_file

end


function mms_ld_fpi_pad_ion, input_time_range, id=datatype, probe=probe, $
    print_datatype=print_datatype, errmsg=errmsg, $
    local_files=files, file_times=file_times, version=version, $
    local_root=local_root, remote_root=remote_root, $
    return_request=return_request

    compile_opt idl2
    on_error, 0
    errmsg = ''
    retval = ''


;---Check inputs.
    sync_threshold = 0
    if n_elements(probe) eq 0 then probe = 'x'
    if n_elements(local_root) eq 0 then local_root = join_path([default_local_root(),'sdata','mms'])
;    if n_elements(remote_root) eq 0 then remote_root = 'https://cdaweb.gsfc.nasa.gov/pub/data/mms'
    if n_elements(remote_root) eq 0 then remote_root = !null
    if n_elements(version) eq 0 then version = 'v01'

    if size(input_time_range[0],type=1) eq 7 then begin
        time_range = time_double(input_time_range)
    endif else begin
        time_range = input_time_range
    endelse

;---Init settings.
    type_dispatch = hash()
    mission_str = 'mms'
    instr_str = 'fpi'
    level_str = 'l2'
    species_str = 'ion'
    type_str = 'pad_'+species_str
    mode_str = 'srvy'
    valid_range = mms_valid_range([instr_str,level_str,mode_str], probe=probe)
    keys = [level_str,mode_str,type_str]
    the_key = strjoin(keys,'%')

    base_name = mission_str+probe+'_'+instr_str+'_'+mode_str+'_'+level_str+'_'+type_str+'_%Y%m%d_'+version+'.cdf'
    local_path = [local_root,mission_str+probe,instr_str,mode_str,level_str,type_str,'%Y','%m']
    type_dispatch[the_key] = dictionary($
        'pattern', dictionary($
            'local_file', join_path([local_path,base_name]), $
            'local_index_file', join_path([local_path,default_index_file(/sync)])), $
        'valid_range', time_double(valid_range), $
        'sync_threshold', 0, $
        'cadence', 'day', $
        'extension', fgetext(base_name) )

    if keyword_set(print_datatype) then begin
        print, 'Suported data type: '
        ids = type_dispatch.keys()
        foreach id, ids do print, '  * '+id
        return, ids
    endif


;---Dispatch patterns.
    datatype = 'l2%srvy%pad_ion'
    if n_elements(datatype) eq 0 then begin
        errmsg = handle_error('No input datatype ...')
        return, ''
    endif
    if not type_dispatch.haskey(datatype) then begin
        errmsg = handle_error('Do not support type '+datatype+' yet ...')
        return, ''
    endif
    request = type_dispatch[datatype]

;---Find files, read variables, and store them in memory.
    files = prepare_files(request=request, errmsg=errmsg, local_files=files, $
        file_times=file_times, time=time_range, nonexist_files=nonexist_files)
    if n_elements(nonexist_files) ne 0 then begin
        foreach file, request.nonexist_files do begin
            file_time = file.file_time
            local_file = file.local_file
            local_file = mms_ld_fpi_pad_ion_gen_file(file_time, filename=local_file, probe=probe)
        endforeach
        files = prepare_files(request=request, errmsg=errmsg, $
            file_times=file_times, time=time_range, nonexist_files=nonexist_files)
    endif
    
    if n_elements(files) eq 0 then return, '' else return, files


end


tr = ['2016-11-01','2016-11-02']
probe = '1'
files = mms_ld_fpi_pad_ion(tr, probe=probe)
stop
file = join_path([homedir(),'mms_ld_pad_fpi_ion_test_file.cdf'])
file = mms_ld_fpi_pad_ion_gen_file(tr, probe=probe, filename=file)
stop

end