
function mms_read_pad_e_thermal, input_time_range, id=datatype, probe=probe, species=species, $
    print_datatype=print_datatype, errmsg=errmsg, $
    local_files=files, file_times=file_times, version=version, $
    local_root=local_root, remote_root=remote_root, $
    return_request=return_request


    compile_opt idl2
    on_error, 0
    errmsg = ''
    retval = ''


    if ~mms_probe_is_valid(probe) then begin
        errmsg = 'Invalid probe: '+probe+' ...'
        return, retval
    endif
    prefix = 'mms'+probe+'_'


    ; Prepare var name.
    species = 'e'
    var_info = prefix+species+'_pad_thermal'
    if keyword_set(get_name) then return, var_info
    if keyword_set(update) then del_data, var_info
    time_range = time_double(input_time_range)
    if ~check_if_update(var_info, time_range) then return, var_info


    mode_str = 'fast'
    level_str = 'l2'
    datatype_str = 'des-dist'
    id = strjoin([level_str,mode_str,datatype_str],'%')
    files = mms_ld_fpi(time_range, probe=probe, id=id, errmsg=errmsg)
    if errmsg ne '' then return, retval
    
    
    ; Read data.
    prefix2 = prefix+'des_'
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
        tmp_fluxs[ii,*,*] = sinterpol(reform(tmp_fluxs[ii,*,*]),reform(en_bins[ii,*]),en_centers)
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
    flux_r_bcs = fltarr(nphi,ntheta,ndim)
    for ii=0,nphi-1 do begin
        for jj=0,ntheta-1 do begin
            flux_r_bcs[ii,jj,*] = -[sint[jj]*[cosp[ii],sinp[ii]],cost[jj]]
        endfor
    endfor
    
    
    coord = 'gse'
    b_var = mms_read_bfield(time_range, probe=probe, coord=coord)
    r_var = mms_read_orbit(time_range, probe=probe, coord=coord)
    q_fac = lets_define_fac(b_var=b_var, r_var=r_var, time_var=flux_var)
    m_xxx2fac = qtom(get_var_data(q_fac))
    
    nsensor = nphi*ntheta
    r_coords = reform(flux_r_bcs, [nsensor,ndim])
    r_fac = fltarr(ntime,nsensor,ndim)
    tmp_r_var = prefix+'tmp_r_'+coord
    for sid=0,nsensor-1 do begin
        the_r_coord = (fltarr(ntime)+1) # reform(r_coords[sid,*])
        r_fac[*,sid,*] = rotate_vector(the_r_coord, m_xxx2fac)
    endfor
    
    ; fac: [b,w,o], --> [z,x,y]
    fac_phis = atan(r_fac[*,*,2],r_fac[*,*,1])*deg  ; in [ntime,nsensor]
    fac_thetas = acos(r_fac[*,*,0])*deg     ; colat.
    index = where(fac_phis lt 0, count)
    if count ne 0 then fac_phis[index] += 360  
    
    
    ; interp flux to uniform fac phi and theta.
    phi_grids = (phis # (fltarr(ntheta)+1))[*]
    theta_grids = ((fltarr(nphi)+1) # thetas)[*]
    full_fluxs = fltarr(ntime,nsensor,nen_bin)
    method = 'NearestNeighbor'
    for tid=0,ntime-1 do begin
        the_fluxs = reform(fluxs[tid,*,*])    ; in [nsensor,nen]
        the_fac_phi = reform(fac_phis[tid,*])
        the_fac_theta = reform(fac_thetas[tid,*])
        qhull, the_fac_phi, the_fac_theta, triangles, sphere=dummy
        for eid=0,nen_bin-1 do full_fluxs[tid,*,eid] = $
            griddata(the_fac_phi, the_fac_theta, the_fluxs[*,eid], method=method, sphere=1, degree=1, triangles=triangles, $
            xout=phi_grids, yout=theta_grids)
    endfor
    
    ; Convert unit.
    me = 0.91d-30   ; kg.
    qe = 1.6d-19    ; C.
    ;mm = me/(qe*1e6)
    ;cc = ((2*en_centers/mm)*1e5)^2    ; sqrt(2E/m) is velocity, the coefs are to make velocity in cm/s.
    cc = (sqrt(2*en_centers*qe/me)*1e2)^4    ; sqrt(2E/m) is velocity, the coefs are to make velocity in cm/s.
    cc = cc/(4*!dpi)    ; this is from s^3/cm^6 to eV/cm^2-s-sr-eV
    ;cc = cc/2           ; to be consistent with mms_convert_flux_units Line 85, 97, and 106.
    for ii=0,nen_bin-1 do full_fluxs[*,*,ii] *= cc[ii]   ; fluxs in eV/cm^2-s-sr-eV.
    ;for ii=0,nen_bin-1 do full_fluxs[*,*,ii] /= (en_centers[ii]*1e-3)
    full_fluxs = reform(full_fluxs,[ntime,nphi,ntheta,nen_bin])

    ; eliminate phi.
    pad_fluxs = total(full_fluxs,2)/nphi
    
    sp_times = times
    sp_pad_fluxs = pad_fluxs
    pa_centers = thetas
    
    
;    en_index = where_pro(en_centers, '[]', [0,5e1])
;    store_data, prefix+'e_pa_spec1', sp_times, total(sp_pad_fluxs[*,*,en_index],3), pa_centers, limits={spec:1,zlog:1,ylog:0}
;    en_index = where_pro(en_centers, '[]', [5e1,2e3])
;    store_data, prefix+'e_pa_spec2', sp_times, total(sp_pad_fluxs[*,*,en_index],3), pa_centers, limits={spec:1,zlog:1,ylog:0,yrange:[0,180],ystyle:1}
;    en_index = where_pro(en_centers, '[]', [2,32]*1e3)
;    store_data, prefix+'e_pa_spec3', sp_times, total(sp_pad_fluxs[*,*,en_index],3), pa_centers, limits={spec:1,zlog:1,ylog:0,yrange:[0,180],ystyle:1}


    
    ; TODO
    store_data, var_info, times, sp_pad_fluxs
    add_setting, var_info, smart=1, dictionary($
        'requested_time_range', time_range, $
        'display_type', 'pad', $
        'mission', 'mms', $
        'probe', probe, $
        'mission_probe', 'mms'+probe, $
        'unit', 'eV/cm!U2!N-s-sr-eV', $
        'species', species, $
        'en_centers', en_centers, $    ; in eV.
        'en_unit', 'eV', $
        'pa_centers', pa_centers, $
        'pa_unit', 'deg' )       ; in deg.

    return, var_info
    
;    cdf2tplot, files, get_support_data=1
;    
;    ; mms_get_fpi_dist needs v1 (azim), v2 (theta), and v3 (en).
;    var = prefix+'des_dist_fast'
;    get_data, var, times, fluxs, limits=lim, dlimits=dlim
;    vatt = dlim.cdf.vatt
;    v1_var = vatt.depend_1  ; phi
;    v2_var = vatt.depend_2  ; theta
;    v3_var = vatt.depend_3  ; energy
;    var_list = list()
;    in_vars = [v3_var]
;    var_list.add, dictionary($
;        'in_vars', [vatt.depend_3], $
;        'time_var_name', 'Epoch', $
;        'time_var_type', 'tt2000' )
;    read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg
;
;    dd = {x:times, y:fluxs, $
;        v1: cdf_read_var(v1_var, filename=files[0]), $
;        v2: cdf_read_var(v2_var, filename=files[0]), $
;        v3: get_var_data(v3_var) }
;    store_data, var, data=dd
;    
;    
;    
;    datatype_str = 'des-moms'
;    id = strjoin([level_str,mode_str,datatype_str],'%')
;    files = mms_ld_fpi(time_range, probe=probe, id=id, errmsg=errmsg)
;    if errmsg ne '' then return, retval
;    cdf2tplot, files, get_support_data=1
;
;
;    mms_part_slice2d, rotation='bv', $
;        time=mean(time_range), probe=probe, species='e', data_rate=mode_str, trange=time_range
;    
;    store_data, var_info, sp_times, sp_fluxs
;    add_setting, var_info, smart=1, dictionary($
;        'requested_time_range', time_range, $
;        'display_type', 'pad', $
;        'mission', 'mms', $
;        'probe', probe, $
;        'unit', '#/cm!U2!N-s-sr-keV', $
;        'species', species, $
;        'en_centers', en_centers, $    ; in eV.
;        'en_unit', 'eV', $
;        'pa_centers', pa_centers, $
;        'pa_unit', 'deg' )       ; in deg.
;
;    return, var_info

end


tr = ['2016-10-14/21:40','2016-10-14/22:00']
tr = ['2016-10-14/20:00','2016-10-14/22:30']
probe = '1'
ele_var = mms_read_pad_e_thermal(tr, probe=probe)

;mms_load_fpi, probes=probe, datatype='des-moms', level='l2', data_rate='fast', trange=tr
;mms_load_fpi, probes=probe, datatype='des-dist', level='l2', data_rate='fast', trange=tr
;mms_part_getspec, energy=[2,32]*1e3, pitch=[0,180], probe=probe, output='energy pa', trange=tr, data_rate='fast', species='e', instrument='fpi'
;mms_part_getspec, energy=[2,32]*1e3, pitch=[0,180], probe=probe, output='energy pa', trange=tr, data_rate='fast', species='e', instrument='fpi'
;stop

tmp = plot_pad_polygon(ele_var, plot_times=time_double('2016-10-14/21:43:30'), test=1, zrange=[1e5,5e7], color_table=49)
end