;+
; Read electron pitch angle distribution from FEEPS.
; 12 top sensors and 12 bottom sensors.
;-


function mms_read_pad_e_kev, input_time_range, id=datatype, probe=probe, species=species, $
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
    var_info = prefix+species+'_pad_kev'
    if keyword_set(get_name) then return, var_info
    if keyword_set(update) then del_data, var_info
    time_range = time_double(input_time_range)
    if ~check_if_update(var_info, time_range) then return, var_info


    ; Collect active sensors.
    mode_str = 'srvy'
    level_str = 'l2'
    species_str = 'electron'
    nsensor = 12
    sensor_ids = findgen(nsensor)+1
    sensor_types = ['top','bottom']
    unit_type = 'intensity'
    prefix2 = prefix+'epd_feeps_'+mode_str+'_'+level_str+'_'+species_str+'_'

    ; from mms_feeps_correct_energies.
    ;electron_sensors = sensor_ids[where_pro(sensor_ids, ')(', [6,8])]
    ;sensor_strs = string(electron_sensors,format='(I0)')
    active_sensors = mms_feeps_active_eyes(time_range, probe, mode_str, species_str, level_str)
    
    sensor_vars = list()
    foreach sensor_type, sensor_types do begin
        sensor_strs = string(active_sensors[sensor_type],format='(I0)')
        sensor_vars.add, prefix2+sensor_type+'_'+unit_type+'_sensorid_'+sensor_strs+'_clean_sun_removed', extract=1
    endforeach
    nactive_sensor = n_elements(sensor_vars)
    sensor_vars = sensor_vars.toarray()
    
    ; Load file.
    id = strjoin([level_str,mode_str,species_str],'%')
    files = mms_ld_feeps(time_range, probe=probe, id=id, errmsg=errmsg)
    if errmsg ne '' then return, retval
        
    ; Get the electron sensors and add the corresponding energy bins.
    foreach sensor_type, sensor_types do begin
        var_list = list()
        
        sensor_strs = string(active_sensors[sensor_type],format='(I0)')
        in_vars = prefix2+sensor_type+'_'+unit_type+'_sensorid_'+sensor_strs

        var_list.add, dictionary($
            'in_vars', in_vars, $
            'out_vars', in_vars, $
            'time_var_name', 'epoch', $
            'time_var_type', 'tt2000' )
        read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg

        foreach sensor_str, sensor_strs, vid do begin
            var = in_vars[vid]
            energy_map = mms_feeps_energy_table(probe, strmid(sensor_type,0,3), long(sensor_str))
            get_data, var, times, data
            store_data, var, times, data, energy_map
        endforeach
    endforeach
    
    ; calibrate data (adopted from mms_load_feeps)
    mms_feeps_remove_bad_data, probe=probe, data_rate=mode_str, level=level_str, trange=time_range
    

    ; split the extra integral channel from all of the spectrograms
    mms_feeps_split_integral_ch, unit_type, species_str, probe, $
        data_rate=mode_str, level=level_str, sensor_eyes=active_sensors

    ; remove the sunlight contamination.
    ; spinsectnum also used to do spin average.
    spin_var = prefix2+'spinsectnum'
    var_list = list()
    var_list.add, dictionary($
        'in_vars', spin_var, $
        'time_var_name', 'epoch', $
        'time_var_type', 'tt2000' )
    read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg
    if errmsg ne '' then return, retval
    mms_feeps_remove_sun, probe=probe, trange=time_range, $
        datatype=species_str, level=level_str, data_rate=mode_str, data_units=unit_type, $
        sensor_eyes=active_sensors
    foreach var, sensor_vars do begin
        options, var, 'requested_time_range', time_range
        orig_var = streplace(var,'_clean_sun_removed','')
        vatt = cdf_read_setting(orig_var, filename=files[0])
        cdf = {vatt:vatt.tostruct()}
        dl = {cdf:cdf[0]}
        store_data, var, dlimit=dl
    endforeach
    sensor_flux_vars = sensor_vars
    

    ; prepare pitch angle for all sensors.
;    ; need 'mmsx_epd_feeps_srvy_l2_electron_pitch_angle' and 'mmsx_fgm_b_bcs_srvy_l2_bvec'.
;    pa_var = prefix+'epd_feeps_'+mode_str+'_'+level_str+'_'+species_str+'_pitch_angle'
;    var_list = list()
;    var_list.add, dictionary($
;        'in_vars', pa_var, $
;        'time_var_name', 'epoch', $
;        'time_var_type', 'tt2000' )
;    read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg
;    if errmsg ne '' then return, retval
;    b_var = mms_read_bfield(time_range, probe=probe, coord='bcs')
;    b_var2 = prefix+'fgm_b_bcs_'+mode_str+'_'+level_str+'_bvec'
;    copy_data, b_var, b_var2
;    
;    mms_feeps_pitch_angles, probe=probe, trange=time_range, $
;        datatype=species_str, level=level_str, data_rate=mode_str, idx_maps=idx_maps
;    pa_data_var = prefix+'epd_feeps_'+mode_str+'_'+level_str+'_'+species_str+'_pa'
;    options, pa_data_var, 'index_map', idx_maps
;    
;    
;    ; combine sensor fluxs and map to pa_data.
;    ; idx_maps is for the pa_index, eys is for the sensor_id. L129 in mms_feeps_pad.
;    the_fluxs = get_var_data(var_info[0], times=times)
;    ntime = n_elements(the_fluxs[*,0])  
;    nen_bin = n_elements(the_fluxs[0,*])  
;    sensor_fluxs = fltarr(ntime,nen_bin,nactive_sensor)
;    sensor_en_bins = fltarr(nen_bin,nactive_sensor)
;    foreach sensor_type, sensor_types, tid do begin
;        sensor_strs = string(active_sensors[sensor_type],format='(I0)')
;        in_vars = prefix2+sensor_type+'_'+unit_type+'_sensorid_'+sensor_strs
;        pa_index = (idx_maps[tid])[species_str+'-'+sensor_type]
;        foreach pa_id, pa_index, ii do begin
;            sensor_flux_var = in_vars[ii]+'_clean_sun_removed'
;            sensor_fluxs[*,*,pa_id] = get_var_data(sensor_flux_var, en_bins)
;            sensor_en_bins[*,pa_id] = en_bins
;        endforeach
;    endforeach
;    sensor_flux_var = prefix+'epd_feeps_'+mode_str+'_'+level_str+'_'+species_str+'_sensor_flux'
;    store_data, sensor_flux_var, times, sensor_fluxs
;    options, sensor_flux_var, en_bins=sensor_en_bins, pa_bins=get_var_data(pa_data_var)

    
    top_sensor_r_fcs = transpose([$
        [ 0.347,-0.837, 0.423], $
        [ 0.347,-0.837,-0.423], $
        [ 0.837,-0.347, 0.423], $
        [ 0.837,-0.347,-0.423], $
        [-0.087, 0.000, 0.996], $
        [ 0.104, 0.180, 0.978], $
        [ 0.654,-0.377, 0.656], $
        [ 0.654,-0.377,-0.656], $
        [ 0.837, 0.347, 0.423], $
        [ 0.837, 0.347,-0.423], $
        [ 0.347, 0.837, 0.423], $
        [ 0.347, 0.837,-0.423] ])
    
    ; a rotation around y-axis by 180 deg.
    sint = 0d
    cost = -1d
    m_bottom_to_top = transpose([$
        [cost, 0, sint], $
        [0,1,0], $
        [-sint, 0, cost]])
    bottom_sensor_r_fcs = rotate_vector(top_sensor_r_fcs, m_bottom_to_top)
    
    flux_r_fcs = -[top_sensor_r_fcs[active_sensors['top']-1,*],bottom_sensor_r_fcs[active_sensors['bottom']-1,*]]
    flux_r_bcs = mms_fcs2mms_bcs(flux_r_fcs)
    times = get_var_time(sensor_vars[0])
    ntime = n_elements(times)
    
    b_var = mms_read_bfield(time_range, probe=probe, coord='bcs')
    b_bcs = get_var_data(b_var, at=times)
    sensor_pa = fltarr(ntime,nactive_sensor)
    for ii=0,nactive_sensor-1 do begin
        f_bcs = (fltarr(ntime)+1) # flux_r_bcs[ii,*]
        sensor_pa[*,ii] = sang(b_bcs,f_bcs, deg=1)
    endfor

    ; combine sensor fluxs and map to sensor_pa.
    the_fluxs = get_var_data(sensor_vars[0], times=times)
    ntime = n_elements(the_fluxs[*,0])
    nen_bin = n_elements(the_fluxs[0,*])
    sensor_fluxs = fltarr(ntime,nen_bin,nactive_sensor)
    sensor_en_bins = fltarr(nen_bin,nactive_sensor)
    foreach sensor_flux_var, sensor_flux_vars, tid do begin
        sensor_fluxs[*,*,tid] = get_var_data(sensor_flux_var, en_bins)
        sensor_en_bins[*,tid] = en_bins
    endforeach
    sensor_flux_var = prefix+'epd_feeps_'+mode_str+'_'+level_str+'_'+species_str+'_sensor_flux'
    store_data, sensor_flux_var, times, sensor_fluxs
    options, sensor_flux_var, en_bins=sensor_en_bins, pa_bins=sensor_pa
    

    ; prepare the flux as a function of energy and pitch angle.
    pa_bin_size = 16.3636   ; deg, from mms_feeps_pad.
    pa_bins = smkarthm(0,180,12,'n')
    npa_bin = n_elements(pa_bins)-1
    pa_bin_size = total(pa_bins[0:1]*[-1,1])
    pa_centers = pa_bins[0:npa_bin-1]+pa_bin_size*0.5
    dangresp = 21.4
    delta_pa = pa_bin_size*0.5+dAngResp ; c.f. Line 166 in mms_feeps_pad.
    

    ; from mms_feeps_omni.
    energies = [33.200000d, 51.900000d, 70.600000d, 89.400000d, 107.10000d, 125.20000d, 146.50000d, 171.30000d, $
        200.20000d, 234.00000d, 273.40000, 319.40000d, 373.20000d, 436.00000d, 509.20000d]
    eEcorr = [14.0, -1.0, -3.0, -3.0]
    eGfact = [1.0, 1.0, 1.0, 1.0]
    probe_index = float(probe)-1
    en_bins = energies+eEcorr[probe_index]
    nen_bin = n_elements(en_bins)
    en_label = energies
    en_chk = 0.10
    
    ; dpa is almost identical to pa_data.y (Line 151 in mms_feeps_pad).
    ; Line 150, average over all bins in the energy range.
    ; Line 167, average over all sensors that fall into the pa_bin.
    
    
    fluxs = fltarr(ntime,nen_bin,npa_bin)
    counts = fltarr(ntime,nen_bin,npa_bin)
    sensor_fluxs = get_var_data(sensor_flux_var, times=times)
    sensor_en_bins = get_var_setting(sensor_flux_var, 'en_bins')
    sensor_pa_bins = get_var_setting(sensor_flux_var, 'pa_bins')
    

    for sensor_id=0, nactive_sensor-1 do begin
        the_sensor_fluxs = sensor_fluxs[*,*,sensor_id]
        the_sensor_fluxs = transpose(sinterpol(transpose(the_sensor_fluxs), sensor_en_bins[*,sensor_id], en_bins))
        index = where(finite(the_sensor_fluxs,nan=1), count)
        if count ne 0 then the_sensor_fluxs[index] = 0
        for pa_id=0,npa_bin-1 do begin
            index = where_pro(sensor_pa_bins[*,sensor_id], '[]', pa_centers[pa_id]+[-1,1]*delta_pa, count=count)
            if count ne 0 then begin
                fluxs[index,*,pa_id] += the_sensor_fluxs[index,*]
                counts[index,*,pa_id] += 1
            endif
        endfor
    endfor
    fluxs = fluxs/counts
    index = where(counts eq 0 or fluxs eq 0, count)
    if count ne 0 then fluxs[index] = !values.f_nan
    
    ; spin averaged fluxs.
    spin_sectors = get_var_data(spin_var)
    spin_index = where(spin_sectors[0:ntime-2] ge spin_sectors[1:ntime-1], count)+1
    nspin_sector = count-1
    sp_times = times[spin_index[0:nspin_sector-1]]
    sp_fluxs = fluxs[spin_index[0:nspin_sector-1],*,*]
    for ii=0,nspin_sector-1 do begin
        i0 = spin_index[ii]
        i1 = spin_index[ii+1]-1
        drec = (i1-i0)+1
        sp_fluxs[ii,*,*] = total(fluxs[i0:i1,*,*],1,nan=1)/drec
    endfor
    
    sp_fluxs = transpose(sp_fluxs,[0,2,1])  ; [ntime,npa,nen]
    en_centers = en_bins*1e3
    store_data, var_info, sp_times, sp_fluxs
    add_setting, var_info, smart=1, dictionary($
        'requested_time_range', time_range, $
        'display_type', 'pad', $
        'mission', 'mms', $
        'probe', probe, $
        'unit', '#/cm!U2!N-s-sr-keV', $
        'species', species, $
        'en_centers', en_centers, $    ; in eV.
        'en_unit', 'eV', $
        'pa_centers', pa_centers, $
        'pa_unit', 'deg' )       ; in deg.
        
    return, var_info
    
    en_index = where_pro(en_bins,'[]',[70,600])
    pa_fluxs = total(sp_fluxs[*,en_index,*],2,nan=1)
    
    store_data, prefix+'e_pa_spec', sp_times, pa_fluxs, pa_centers, limits={zlog:1,spec:1,no_interp:1,ystyle:1}
    store_data, prefix+'e_en_spec', sp_times, total(sp_fluxs,3,nan=1), en_bins, limits={zlog:1,spec:1,no_interp:1,ystyle:1,ylog:1}
    stop
    ;    ; calculate the omni-directional spectra
    ;    ; need mmsx_epd_feeps_srvy_l2_..._sensorid_x_clean_sun_removed.
    ;    mms_feeps_omni, probe, $
    ;        datatype=species_str, level=level_str, data_rate=mode_str, data_units=unit_type, $
    ;        sensor_eyes=active_sensors
    mms_feeps_pad, probe=probe, energy=energy_range, $
        datatype=species_str, level=level_str, data_rate=mode_str, data_units=unit_type
        

    
    return, var_info
end





tr = time_double(['2016-08-04/22:15','2016-08-04/22:55'])
tr = time_double(['2016-08-04','2016-08-05'])
probe = '2'


; keV electron.
ele_var = mms_read_pad_e_kev(tr, probe=probe, species='e')
stop
tmp = plot_pad_polygon(ele_var, plot_times=time_double('2016-08-04/22:20'), zrange=10d^[1,4], test=1)

;dpa = total(pas*[-1,1])
;cpas = [pas-dpa*0.5,pas[npa-1]+dpa*0.5]
;den = mean(ens[1:nen-1]/ens[0:nen-2])
;cens = [ens/sqrt(den),ens[nen-1]*sqrt(den)]
;tts = pas # (fltarr(nen)+1)
;rrs = alog10(ens) ## (fltarr(npa)+1)
;ctts = cpas # (fltarr(nen+1)+1)
;crrs = alog10(cens) ## (fltarr(npa+1)+1)
;stop
;tmp = min(times-time_double('2016-08-04/22:10'), abs=1, time_id)
;sgdistr2d_polygon, reform(pad[time_id,*,*]), tts, rrs, ctts, crrs, ct=40


end