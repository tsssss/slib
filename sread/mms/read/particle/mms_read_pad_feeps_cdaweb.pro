;+
; Load FEEPS pitch angle data. This is to replicate mms_load_pitch_angle in the framework of slib.
;-

function mms_read_pad_feeps_cdaweb_gen_file_v01, input_time_range, probe=probe, filename=cdf_file, errmsg=errmsg, species_str=species_str

    errmsg = ''
    retval = !null
    update = 0

    date = time_double(input_time_range[0])
    secofday = constant('secofday')
    time_range = date+[0,secofday]

    ; Collect active sensors.
    instr_str = 'feeps'
    mode_str = 'srvy'
    level_str = 'l2'
    species_str2 = (species_str eq 'electron') ? 'ele' : 'ion'
    nall_sensor = 12
    sensor_ids = findgen(nall_sensor)+1
    sensor_types = ['top','bottom']
    unit_type = 'intensity'
    prefix = 'mms'+probe+'_'
    prefix2 = prefix+'epd_'+instr_str+'_'+mode_str+'_'+level_str+'_'+species_str+'_'

    active_sensors = mms_feeps_active_eyes(time_range, probe, mode_str, species_str, level_str)

    ; Load pitch angle.
    id = strjoin([level_str,mode_str,species_str],'%')
    files = mms_ld_feeps(time_range, probe=probe, id=id, errmsg=errmsg)
    if errmsg ne '' then return, retval

    var_list = list()
    in_vars = prefix2+'pitch_angle'
    var_list.add, dictionary($
        'in_vars', in_vars, $
        'out_vars', in_vars, $
        'time_var_name', 'epoch', $
        'time_var_type', 'tt2000' )
    read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg
    if errmsg ne '' then return, retval
    
    flux_vars = mms_read_feeps_flux_cdaweb(time_range, probe=probe, species_str=species_str, $
        errmsg=errmsg, get_name=get_name, suffix=suffix, update=update)


;    ; mms_feeps_pad loads mms_feeps_pitch_angle, does calculations, and then run mms_feeps_pad_spinavg.
;    ;
;    mms_feeps_pad, energy=energy_range, $
;        probe=probe, datatype=species_str, data_rate=mode_str, $
;        level=level_str, data_units=unit_type, suffix=suffix
    
    bin_size = 16.3636
    data_units = 'intensity'
    dangresp = (species_str eq 'electron')? 21.4: 10.0
    n_pabins = 180./bin_size
    pa_bins = 180.*indgen(n_pabins+1)/n_pabins
    pa_label = 180.*indgen(n_pabins)/n_pabins+bin_size/2.
    
    mms_feeps_pitch_angles, trange=time_range, probe=probe, $
        level=level_str, data_rate=mode_str, datatype=species_str, suffix='', idx_maps=idx_maps
    get_data, prefix2+'pa', data=pa_data, dlimits=pa_dlimits
    if n_elements(idx_maps) eq 0 then begin
        errmsg = 'Error in obtaining pitch angle ...'
        return, retval
    endif
    
    pa_data_map = hash()
    sensor_types = ['top', 'bottom']
    nsensor = 0
    foreach str, sensor_types, sid do begin
        key = str+'-'+species_str
        pa_data_map[key] = (idx_maps[sid])[species_str+'-'+str]
        nsensor += n_elements(pa_data_map[key])
    endforeach
    
    en_bins = get_var_value(flux_vars[1])
    n_enbins = n_elements(en_bins)
    ntime = n_elements(pa_data.x)
    dflux = fltarr(ntime, nsensor, n_enbins)
    dpa = fltarr(ntime,nsensor)
    eyes = mms_feeps_active_eyes(time_range, probe, mode_str, species_str, level_str)
    for s_type_idx = 0, n_elements(sensor_types)-1 do begin ; loop through top and bottom
        s_type = sensor_types[s_type_idx]
        pa_map = pa_data_map[s_type+'-'+species_str]
        particle_idxs = eyes[s_type]-1
        for isen=0, n_elements(particle_idxs)-1 do begin ; loop through sensors
            ; get data
            var_name = strcompress(prefix2+s_type+'_'+data_units+'_sensorid_'+strcompress(string(particle_idxs[isen]+1), /rem)+'_clean_sun_removed', /rem)
            get_data, var_name, data = d, dlimits=dl
            d.y[where(d.y eq 0.0)] = !values.d_nan ; remove any 0s before averaging
            ; store data in dflux and dpa
            ; Energy indices to use:
            ;indx = where((d.v le energy[1]) and (d.v ge energy[0]), energy_count)
            dflux[*, pa_map[isen],*] = d.y
            dpa[*, pa_map[isen]] = reform(pa_data.y[*, pa_map[isen]])
        endfor
    endfor
    
    ; we need to replace the 0.0s left in after populating dpa with NaNs; these
    ; 0.0s are left in there because these points aren't covered by sensors loaded
    ; for this mode_str/data_rate
    dpa[where(dpa eq 0.0)] = !values.d_nan ; fill any missed bins with NAN

    pa_flux = fltarr(ntime, n_pabins, n_enbins)
    delta_pa = (pa_bins[1]-pa_bins[0])/2.0

    ; Now loop through PA bins and time, find the telescopes where there is data in those bins and average it up!
    for it = 0l, n_elements(dpa[*,0])-1 do begin
        for ipa = 0, n_pabins-1 do begin
            ind = where((dpa[it,*] + dAngResp ge pa_label[ipa]-delta_pa) and (dpa[it,*] - dAngResp lt pa_label[ipa]+delta_pa))  ; edited by DLT on 26 Jun 2017
            if ind[0] eq -1 then continue
            for en_idx=0,n_enbins-1 do begin
                pa_flux[it, ipa, en_idx] = reform(average(dflux[it, ind, en_idx], 2, /NAN))
            endfor
        endfor
    endfor
    pa_flux[where(pa_flux eq 0.0)] = !values.d_nan ; fill any missed bins with NAN
    times = pa_data.x
    ; convert unit from #/cm^2-s-sr-keV to eV/cm^2-s-sr-eV.
    foreach en, en_bins, en_idx do begin
        pa_flux[*,*,en_idx] *= en*1e3
    endforeach
    
    
    ;new_name = prefix+'feeps_pa_spec_cdaweb_'+species_str
    ;var = var_store(new_name, total(pa_flux,3,nan=1)/n_enbins, times, pa_label)
    ;options, var, yrange=[0,180], ystyle=1, spec=1, no_interp=1, minzlog=0.01, zlog=1, extend_y_edges=1
    
    
;---Save to file.
    gatt = dictionary($
        'title', 'MMS '+strupcase(instr_str)+' pitch angle distribution, calculated based on l2 data', $
        'text', 'Calculated by Sheng Tian, email:ts0110@atmos.ucla.edu' )
    cdf_save_setting, gatt, filename=cdf_file

    time_var = 'time'
    vatt = dictionary($
        'FIELDNAM', 'Unix time', $
        'UNITS', 'sec', $
        'VAR_TYPE', 'support_data' )
    cdf_save_var, time_var, value=times, filename=cdf_file, cdf_type='CDF_DOUBLE'
    cdf_save_setting, vatt, varname=time_var, filename=cdf_file

    pa_var = prefix+'pa_centers'
    pa_unit = 'deg'
    vatt = dictionary($
        'FIELDNAM', 'Pitch angle at the center of each bin', $
        'UNITS', pa_unit, $
        'VAR_TYPE', 'support_data' )
    cdf_save_var, pa_var, value=pa_label, filename=cdf_file, save_as_one=1
    cdf_save_setting, vatt, varname=pa_var, filename=cdf_file

    en_var = prefix+'en_centers'
    en_unit = 'eV'
    vatt = dictionary($
        'FIELDNAM', 'Energy at the center of each bin', $
        'UNITS', en_unit, $
        'VAR_TYPE', 'support_data' )
    cdf_save_var, en_var, value=en_bins*1e3, filename=cdf_file, save_as_one=1
    cdf_save_setting, vatt, varname=en_var, filename=cdf_file

    pad_var = prefix+'pad2d_'+instr_str+'_'+species_str2
    pad_unit = 'eV/cm!U2!N-s-sr-eV'
    vatt = dictionary($
        'FIELDNAM', 'flux', $
        'UNITS', pad_unit, $
        'VAR_TYPE', 'data', $
        'DEPEND_0', time_var, $ ; in sec.
        'DEPEND_1', pa_var, $   ; in deg.
        'DEPEND_2', en_var, $   ; in eV.
        'species', species_str2 )
    cdf_save_var, pad_var, value=pa_flux, filename=cdf_file
    cdf_save_setting, vatt, varname=pad_var, filename=cdf_file

    return, cdf_file


end

function mms_read_pad_feeps_cdaweb_load_file, input_time_range, probe=probe, $
    species_str=species_str, errmsg=errmsg

    compile_opt idl2
    on_error, 0
    errmsg = ''
    retval = ''


;---Check inputs.
    sync_threshold = 0
    if n_elements(probe) eq 0 then probe = 'x'
    if n_elements(local_root) eq 0 then local_root = join_path([default_local_root(),'sdata','mms'])
;    if n_elements(remote_root) eq 0 then remote_root = 'https://cdaweb.gsfc.nasa.gov/pub/data/mms'
    if n_elements(version) eq 0 then version = 'v01'

    if size(input_time_range[0],type=1) eq 7 then begin
        time_range = time_double(input_time_range)
    endif else begin
        time_range = input_time_range
    endelse


;---Init settings.
    type_dispatch = hash()
    mission_str = 'mms'
    instr_str = 'feeps'
    level_str = 'l2'
    species_str2 = (species_str eq 'electron') ? 'ele' : 'ion'
    type_str = 'pad2d_'+species_str2
    mode_str = 'srvy'
    valid_range = mms_valid_range([instr_str,level_str,mode_str], probe=probe)
    keys = [level_str,mode_str,type_str]
    the_key = strjoin(keys,'%')

    base_name = mission_str+probe+'_'+instr_str+'_'+mode_str+'_'+level_str+'_'+type_str+'_%Y%m%d_'+version+'.cdf'
    local_path = [local_root,mission_str+probe,instr_str,mode_str,level_str,type_str+'_'+version,'%Y','%m']
    request = dictionary($
        'pattern', dictionary($
            'local_file', join_path([local_path,base_name]), $
            'local_index_file', join_path([local_path,default_index_file(/sync)])), $
        'valid_range', time_double(valid_range), $
        'sync_threshold', 0, $
        'cadence', 'day', $
        'extension', fgetext(base_name) )

;---Find files, read variables, and store them in memory.
    files = prepare_files(request=request, errmsg=errmsg, local_files=files, $
        file_times=file_times, time=time_range, nonexist_files=nonexist_files)
    if n_elements(nonexist_files) ne 0 then begin
        foreach file, request.nonexist_files do begin
            file_time = file.file_time
            local_file = file.local_file
            routine = 'mms_read_pad_feeps_cdaweb_gen_file_'+version
            local_file = call_function(routine, file_time, filename=local_file, probe=probe, species_str=species_str)
        endforeach
        files = prepare_files(request=request, errmsg=errmsg, $
            file_times=file_times, time=time_range, nonexist_files=nonexist_files)
    endif
    
    if n_elements(files) eq 0 then return, '' else return, files


end



function mms_read_pad_feeps_cdaweb, input_time_range, probe=probe, $
    species_str=species_str, $
    errmsg=errmsg, get_name=get_name, suffix=suffix, update=update, var_info=var_info

    prefix = 'mms'+probe+'_'
    errmsg = ''
    retval = ''

    if n_elements(suffix) eq 0 then suffix = '_cdaweb'
    if n_elements(species_str) eq 0 then species_str = 'electron'
    species_str2 = (species_str eq 'electron')? 'ele': 'ion'
    if n_elements(var_info) eq 0 then var_info = prefix+'pad_spec_'+species_str2+'_kev'+suffix
    if keyword_set(get_name) then return, var_info
    if keyword_set(update) then tmp = delete_var_from_memory(var_info)
    time_range = time_double(input_time_range)
    if ~check_if_update_memory(var_info, time_range) then return, var_info

    ; Load files.
    files = mms_read_pad_feeps_cdaweb_load_file(time_range, probe=probe, errmsg=errmsg, species_str=species_str)
    if errmsg ne '' then return, retval


;---Read data.
    var_list = list()
    in_vars = [prefix+'pad2d_feeps_'+species_str2]
    out_vars = [prefix+'pad2d_'+species_str2+'_kev']
    var_list.add, dictionary($
        'in_vars', in_vars, $
        'out_vars', out_vars, $
        'time_var_name', 'time', $
        'time_var_type', 'unix' )
    read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg
    if errmsg ne '' then return, ''

    pad_unit = (cdf_read_setting(in_vars[0], filename=files[0]))['UNITS']
    pa_var = prefix+'pa_centers'
    pa_centers = cdf_read_var(pa_var, filename=files[0])
    pa_unit = (cdf_read_setting(pa_var, filename=files[0]))['UNITS']
    en_var = prefix+'en_centers'
    en_centers = cdf_read_var(en_var, filename=files[0])
    en_unit = (cdf_read_setting(en_var, filename=files[0]))['UNITS']

    pad2d_var = out_vars[0]
    pad_fluxs = get_var_data(pad2d_var, times=times)
    
    pad_var = var_info
    if ~keyword_set(no_spin_average) then begin
    ;---spin average.
        instr_str = 'feeps'
        mode_str = 'srvy'
        level_str = 'l2'
        species_str = 'electron'
        id = strjoin([level_str,mode_str,species_str],'%')
        files = mms_ld_feeps(time_range, probe=probe, id=id, errmsg=errmsg)
        
        prefix2 = prefix+'epd_'+instr_str+'_'+mode_str+'_'+level_str+'_'+species_str+'_'
        spin_var = prefix2+'spinsectnum'
        var_list = list()
        var_list.add, dictionary($
            'in_vars', spin_var, $
            'time_var_name', 'epoch', $
            'time_var_type', 'tt2000' )
        read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg
        
        ; spin averaged fluxs.
        spin_sectors = get_var_data(spin_var, at=times)
        ntime = n_elements(times)
        spin_index = where(spin_sectors[0:ntime-2] ge spin_sectors[1:ntime-1], count)+1
        nspin_sector = count-1
        sp_times = times[spin_index[0:nspin_sector-1]]
        sp_pad_fluxs = pad_fluxs[spin_index[0:nspin_sector-1],*,*]
        for ii=0,nspin_sector-1 do begin
            i0 = spin_index[ii]
            i1 = spin_index[ii+1]-1
            drec = (i1-i0)+1
            sp_pad_fluxs[ii,*,*] = total(pad_fluxs[i0:i1,*,*],1,nan=1)/drec
        endfor
        store_data, pad_var, sp_times, sp_pad_fluxs
    endif else begin
        store_data, pad_var, times, pad_fluxs
    endelse

    ; Use unit eV/cm^2-s-sr-eV, so that fluxes can be added directly in pa and en.
;    get_data, pad_var, times, pad_fluxs
;    nen_center = n_elements(en_centers)
;    for ii=0,nen_center-1 do begin
;        pad_fluxs[*,*,ii] /= en_centers[ii]*1e-3
;    endfor
    pad_unit = 'eV/cm!U2!N-s-sr-eV'
    
    add_setting, pad_var, dictionary($
        'requested_time_range', time_range, $
        'probe', probe, $
        'mission', 'mms', $
        'mission_probe', 'mms'+probe, $
        'display_type', 'pad', $
        'unit', pad_unit, $
        'species', species_str, $
        'pa_centers', pa_centers, $
        'pa_unit', pa_unit, $
        'en_centers', en_centers, $
        'en_unit', en_unit )
    
    return, var_info
    

end


time_range = ['2015-09-01','2015-09-02']
probe = '4'
species_str = 'electron'
pa_var = mms_read_pad_feeps_cdaweb(time_range, probe=probe, species_str=species_str)
end