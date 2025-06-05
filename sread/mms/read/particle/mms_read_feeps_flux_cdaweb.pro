;+
; Loads FEEPS flux and clean the data. This is to replicate mms_load_feeps in the framework of slib.
;-

function mms_read_feeps_flux_cdaweb, input_time_range, probe=probe, $
    errmsg=errmsg, get_name=get_name, suffix=suffix, update=update


    prefix = 'mms'+probe+'_'
    errmsg = ''
    retval = ''

    if n_elements(suffix) eq 0 then suffix = ''
    suffix = ''


    ; Collect active sensors.
    instr_str = 'feeps'
    mode_str = 'srvy'
    level_str = 'l2'
    species_str = 'electron'
    species_str2 = 'ele'
    nall_sensor = 12
    sensor_ids = findgen(nall_sensor)+1
    sensor_types = ['top','bottom']
    unit_type = 'intensity'
    ;unit_type = 'count_rate'
    prefix = 'mms'+probe+'_'
    prefix2 = prefix+'epd_'+instr_str+'_'+mode_str+'_'+level_str+'_'+species_str+'_'

    ; from mms_feeps_correct_energies.
    ;electron_sensors = sensor_ids[where_pro(sensor_ids, ')(', [6,8])]
    ;sensor_strs = string(electron_sensors,format='(I0)')
    time_range = time_double(input_time_range)
    active_sensors = mms_feeps_active_eyes(time_range, probe, mode_str, species_str, level_str)

    sensor_vars = list()
    foreach sensor_type, sensor_types do begin
        sensor_strs = string(active_sensors[sensor_type],format='(I0)')
        sensor_vars.add, prefix2+sensor_type+'_'+unit_type+'_sensorid_'+sensor_strs+'_clean_sun_removed', extract=1
    endforeach
    nsensor = n_elements(sensor_vars)
    sensor_vars = sensor_vars.toarray()


    out_var = prefix2+sensor_type+'_'+unit_type+'_sensorid_'+sensor_strs+'_clean_sun_removed'
    out_var = [prefix2+'spinsectnum',out_var]
    if keyword_set(get_name) then return, out_var
    if keyword_set(update) then tmp = delete_var_from_memory(out_var)
    if ~check_if_update_memory(out_var, time_range) then return, out_var

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
    mms_feeps_remove_bad_data, probe=probe, data_rate=mode_str, level=level_str, trange=time_range, suffix=suffix


    ; split the extra integral channel from all of the spectrograms
    mms_feeps_split_integral_ch, unit_type, species_str, probe, $
        data_rate=mode_str, level=level_str, sensor_eyes=active_sensors, suffix=suffix

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
        sensor_eyes=active_sensors, suffix=suffix
    foreach var, sensor_vars do begin
        options, var, 'requested_time_range', time_range
        orig_var = streplace(var,'_clean_sun_removed','')
        vatt = cdf_read_setting(orig_var, filename=files[0])
        cdf = {vatt:vatt.tostruct()}
        dl = {cdf:cdf[0]}
        store_data, var, dlimit=dl
    endforeach
    sensor_flux_vars = sensor_vars
    options, out_var, requested_time_range=time_range

    return, out_var

end