
function mms_ld_hpca_pad_ion_gen_file, input_time_range, probe=probe, filename=cdf_file, errmsg=errmsg

    errmsg = ''
    retval = !null

    date = time_double(input_time_range[0])
    secofday = constant('secofday')
    time_range = date+[0,secofday]

    prefix = 'mms'+probe+'_'
    mission_probe = 'mms'+probe
    instr_str = 'hpca'
    mode_str = 'srvy'
    level_str = 'l2'
    datatype_str = 'ion'
    id = strjoin([level_str,mode_str,datatype_str],'%')
    files = mms_ld_hpca(time_range, probe=probe, id=id, errmsg=errmsg)
    if errmsg ne '' then return, retval


;---Read data.
    prefix2 = prefix+instr_str+'_'

    var_list = list()
    species_info = mms_get_hpca_species_info()
    orig_species_names = (species_info.values()).toarray()

    ; sensor flux, energy, and phase.
    spin_var = prefix2+'start_azimuth'
    flux_vars = prefix2+orig_species_names+'_flux'    ; flux in #/cm^2-s-sr-eV
    in_vars = [flux_vars,spin_var]
    var_list.add, dictionary($
        'in_vars', in_vars, $
        'time_var_name', 'Epoch', $
        'time_var_type', 'tt2000' )

    ; sensor azimuthal angle.
    azim_var = prefix2+'azimuth_angles_per_ev_degrees' ; in [ntime2, nenergy, elev, azim]. c.f. Line 192 in mms_get_hpca_dist.
    var_list.add, dictionary($
        'in_vars', azim_var, $
        'time_var_name', 'Epoch_Angles', $
        'time_var_type', 'tt2000' )
    read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg    
    if errmsg ne '' then return, retval


;---Save dependent vars, time, pa_center, phi_center, en_center.
    flux_var = flux_vars[0]
    raw_uts = get_var_time(flux_var)

    ; time needs to be adjusted to center.  Line 131 in spd_cdf_info_to_tplot.
    ep_att = cdf_read_setting('Epoch', filename=files[0])
    time_offsets = dblarr(2)
    foreach key, 'DELTA_'+['MINUS','PLUS']+'_VAR', vid do begin
        var = ep_att[key]
        vatt = cdf_read_setting(var, filename=files[0])
        conv_coef = double((strsplit(vatt['SI_CONVERSION'],'>',extract=1))[0])
        time_offsets[vid] = cdf_read_var(var, filename=files[0])
    endforeach
    ; time_offset = time_plus_offset-time_minus_offset)/2.
    ; 0.31250000000000000
    time_offset = total(time_offsets*[-1,1])*0.5*conv_coef
    uts = raw_uts+time_offset

        
    ; sensor elevation angle.
    elev_angles = cdf_read_var(prefix2+'centroid_elevation_angle', filename=files[0])
    
    ; Get the azim angles.
    azim_angles = get_var_data(azim_var, times=time_bins)   ; in [ntime, nenergy, ntheta, nphi]. c.f. Line 192 in mms_get_hpca_dist.
    ntime = n_elements(time_bins)-1
    time_bin_size = sdatarate(time_bins)
    times = time_bins[0:ntime-1]+time_bin_size*0.5
    ntheta = double(n_elements(elev_angles))
    nphi = double(n_elements(azim_angles[0,0,0,*]))

    phi_bin_size = 360d/nphi
    phi_bins = smkarthm(0,360,phi_bin_size, 'dx')
    phis = phi_bins[0:nphi-1]+phi_bin_size*0.5
    theta_bin_size = 180d/ntheta
    theta_bins = smkarthm(0,180,theta_bin_size, 'dx')
    thetas = theta_bins[0:ntheta-1]+theta_bin_size*0.5
    ndir = double(ntheta*nphi)

    pa_centers = thetas
    phi_centers = phis


    gatt = dictionary($
        'title', 'MMS '+strupcase(instr_str)+' pitch angle distribution, calculated based on l2 data', $
        'text', 'Calculated by Sheng Tian at UCLA, email:ts0110@atmos.ucla.edu' )
    cdf_save_setting, gatt, filename=cdf_file

    time_var = 'time'
    vatt = dictionary($
        'FIELDNAM', 'Unix time', $
        'UNITS', 'sec', $
        'VAR_TYPE', 'support_data' )
    cdf_save_var, time_var, value=times, filename=cdf_file, cdf_type='CDF_DOUBLE', copy_data=1
    cdf_save_setting, vatt, varname=time_var, filename=cdf_file

    phi_var = prefix+'phi_centers'
    phi_unit = 'deg'
    vatt = dictionary($
        'FIELDNAM', 'Gyro phase at the center of each bin', $
        'UNITS', phi_unit, $
        'VAR_TYPE', 'support_data' )
    cdf_save_var, phi_var, value=phi_centers, filename=cdf_file, save_as_one=1, copy_data=1
    cdf_save_setting, vatt, varname=phi_var, filename=cdf_file

    pa_var = prefix+'pa_centers'
    pa_unit = 'deg'
    vatt = dictionary($
        'FIELDNAM', 'Pitch angle at the center of each bin', $
        'UNITS', pa_unit, $
        'VAR_TYPE', 'support_data' )
    cdf_save_var, pa_var, value=pa_centers, filename=cdf_file, save_as_one=1, copy_data=1
    cdf_save_setting, vatt, varname=pa_var, filename=cdf_file
        

    en_centers = cdf_read_var(prefix2+'ion_energy', filename=files[0])
    nen_bin = n_elements(en_centers)
    en_var = prefix+'en_centers'
    en_unit = 'eV'
    vatt = dictionary($
        'FIELDNAM', 'Energy at the center of each bin', $
        'UNITS', en_unit, $
        'VAR_TYPE', 'support_data' )
    cdf_save_var, en_var, value=en_centers, filename=cdf_file, save_as_one=1, copy_data=1
    cdf_save_setting, vatt, varname=en_var, filename=cdf_file


    azim_angles = reform(azim_angles[0:ntime-1,*,*,*], [ntime,nen_bin,ndir])
    azims = transpose(azim_angles, [0,2,1])       ; in [ntime,ndir,nen]
    elevs = rebin(elev_angles, [ntheta,nphi,ntime,nen_bin])
    elevs = reform(transpose(elevs, [2,3,0,1]), [ntime,nen_bin,ndir])

    ; Rotate to FAC.
    rad = constant('rad')
    deg = constant('deg')
    
    cosp = cos(azims[*]*rad)
    sinp = sqrt(1-cosp^2)
    cost = cos(elevs[*]*rad)
    sint = sqrt(1-cost^2)
    dir_coords = -[sint*cosp,sint*sinp,cost]
    
    coord = 'gse'
    b_var = mms_read_bfield(time_range, probe=probe, coord=coord)
    r_var = mms_read_orbit(time_range, probe=probe, coord=coord)
    q_fac_var = lets_define_fac(b_var=b_var, r_var=r_var)
    q_xxx2fac = get_var_data(q_fac_var, times=q_times)
    m_xxx2fac = qtom(qslerp(q_xxx2fac,q_times,times))
    
    ndim = 3
    ndata = nen_bin*ndir
    r_coords = reform(dir_coords, [ntime,ndata,ndim])   ; in [ntime,nen,ndir,ndim]
    r_fac = fltarr(ntime,ndata,ndim)
    tmp_r_var = prefix+'tmp_r_'+coord
    for sid=0,ndata-1 do begin
        the_r_coord = reform(r_coords[*,sid,*])
        r_fac[*,sid,*] = rotate_vector(the_r_coord, m_xxx2fac)
    endfor
    
    ; fac: [b,w,o], maps to [z,x,y]
    fac_azims = atan(r_fac[*,*,2],r_fac[*,*,1])*deg  ; in [ntime,ndata]
    fac_elevs = acos(r_fac[*,*,0])*deg     ; colat, in [0,180].
    index = where(fac_azims lt 0, count)
    if count ne 0 then fac_azims[index] += 360 
    fac_azims = reform(fac_azims, [ntime,ndir,nen_bin])
    fac_elevs = reform(fac_elevs, [ntime,ndir,nen_bin])
    
    
    ; interp flux to uniform fac azim and elev.
    phi_grids = (phis # (fltarr(ntheta)+1))[*]
    theta_grids = ((fltarr(nphi)+1) # thetas)[*]
    ngrid = nphi*ntheta



;---Calc PAD.
    qe = 1.6d-19    ; C.
    foreach species_str, species_info.keys() do begin
        orig_species_name = species_info[species_str]
        mass = get_mass(species_str)
        flux_var = flux_vars[where(orig_species_names eq orig_species_name)]
        ; Get the fluxs. should be on uts for all species.
        raw_fluxs = get_var_data(flux_var) ; in [ntime1,nenergy,ntheta], in s^3/cm^6.
        index = where(raw_fluxs le 0, count)
        if count ne 0 then raw_fluxs[index] = 0

        ; also from info = mms_get_hpca_info()?

        fluxs = fltarr(ntime,nen_bin,ndir)  ; in [ntime,nen,ndir]
        for tid=0,ntime-1 do begin
            index = where_pro(uts, '[)', time_bins[tid:tid+1], count=count)
            if count eq nphi then begin
                fluxs[tid,*,*] = reform(transpose(raw_fluxs[index,*,*],[1,2,0]), [nen_bin,ndir])
            endif
        endfor
        
        ; Now we should have fluxs, azims (angle from x), elevs (angle from z)
        fluxs = transpose(fluxs, [0,2,1])       ; in [ntime,ndir,nen]
        

        full_fluxs = fltarr(ntime,ngrid,nen_bin)
        method = 'NearestNeighbor'
        method = 'InverseDistance'  ; this works much better. but much slower.
        for tid=0,ntime-1 do begin
            for eid=0,nen_bin-1 do begin
                the_fluxs = reform(fluxs[tid,*,eid])    ; in [ndir]
                the_fac_phi = reform(fac_azims[tid,*,eid])
                the_fac_theta = reform(fac_elevs[tid,*,eid])
                index = where(finite(the_fac_phi,nan=1), count)
                if count ne 0 then continue
                qhull, the_fac_phi, the_fac_theta, triangles, sphere=dummy
                full_fluxs[tid,*,eid] = $
                griddata(the_fac_phi, the_fac_theta, the_fluxs, method=method, sphere=1, degree=1, triangles=triangles, $
                    xout=phi_grids, yout=theta_grids)
            endfor
        endfor
        
        ; Convert unit.
        ;mm = me/(qe*1e6)
        ;cc = ((2*en_centers/mm)*1e5)^2    ; sqrt(2E/m) is velocity, the coefs are to make velocity in cm/s.
        cc = (sqrt(2*en_centers*qe/mass)*1e2)^4    ; sqrt(2E/m) is velocity, the coefs are to make velocity in cm/s.
        cc = cc/(4*!dpi)    ; this is from s^3/cm^6 to eV/cm^2-s-sr-eV
        ;cc = cc/2           ; to be consistent with mms_convert_flux_units Line 85, 97, and 106.
        ;for ii=0,nen_bin-1 do full_fluxs[*,*,ii] *= en_centers[ii]   ; fluxs in eV/cm^2-s-sr-eV.
        ;for ii=0,nen_bin-1 do full_fluxs[*,*,ii] /= (en_centers[ii]*1e-3)
        full_fluxs = reform(full_fluxs,[ntime,nphi,ntheta,nen_bin])
        
    ;---Save data
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
    endforeach

    return, cdf_file

end


function mms_ld_hpca_pad_ion, input_time_range, id=datatype, probe=probe, species=species_str, $
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
    instr_str = 'hpca'
    level_str = 'l2'
    if n_elements(species_str) eq 0 then species_str = 'p'
    type_str = 'pad_ion'
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
            local_file = mms_ld_hpca_pad_ion_gen_file(file_time, filename=local_file, probe=probe)
        endforeach
        files = prepare_files(request=request, errmsg=errmsg, $
            file_times=file_times, time=time_range, nonexist_files=nonexist_files)
    endif
    
    if n_elements(files) eq 0 then return, '' else return, files




tr = ['2015-09-01','2015-09-02']
probe = '1'
files = mms_ld_hpca_pad_ion(tr, probe=probe)
stop
test_file = join_path([homedir(),'test_hpca_pad.cdf'])
file = mms_ld_hpca_pad_ion_gen_file(tr, probe=probe, filename=test_file)
print, file
end