;+
; Read pa spectrogram.
;-

function mms_read_pa_spec_kev_ion, input_time_range, id=datatype, probe=probe, species=species, $
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

end



function mms_read_pa_spec_kev_ele, input_time_range, id=datatype, probe=probe, species=species, $
    print_datatype=print_datatype, errmsg=errmsg, $
    local_files=files, file_times=file_times, version=version, $
    local_root=local_root, remote_root=remote_root, $
    return_request=return_request, $
    energy_range=energy_range


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
    var_info = prefix+species+'_pa_spec_kev'
    if keyword_set(get_name) then return, var_info
    if keyword_set(update) then del_data, var_info
    time_range = time_double(input_time_range)
    if ~check_if_update(var_info, time_range) then return, var_info
    
    if n_elements(energy_range) eq 0 then energy_range = [70d,600]

    ; Load files.
    mode_str = 'srvy'
    level_str = 'l2'
    id = strjoin([level_str,mode_str,'electron'],'%')
    files = mms_ld_feeps(time_range, probe=probe, id=id, errmsg=errmsg)
    if errmsg ne '' then return, retval
    
    ; Read data (need further clean up. Right now just adopting from mms_load_feeps.
    cdf2tplot, files
    tplotnames = cdf_vars(files[0])
    timespan, time_range[0], total(time_range*[-1,1]), second=1

    
    ; calibrate data (adopted from mms_load_feeps)
    mms_feeps_correct_energies, probe=probe, data_rate=mode_str, level=level_str
    mms_feeps_remove_bad_data, probe=probe, data_rate=mode_str, level=level_str, trange=time_range

    this_probe = probe
    this_datatype = 'electron'
    data_unit = 'intensity' ; count_rate.
    eyes = mms_feeps_active_eyes(time_range, this_probe, mode_str, this_datatype, level_str)


    ; split the extra integral channel from all of the spectrograms
    mms_feeps_split_integral_ch, data_unit, this_datatype, this_probe, $
        data_rate=mode_str, level=level_str, sensor_eyes=eyes

    ; remove the sunlight contamination
    var = prefix+'epd_feeps_'+mode_str+'_'+level_str+'_electron_spinsectnum'
    var_list = list()
    var_list.add, dictionary($
        'in_vars', var, $
        'time_var_name', 'epoch', $
        'time_var_type', 'tt2000' )
    read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg
    if errmsg ne '' then return, retval
    mms_feeps_remove_sun, probe=this_probe, datatype=this_datatype, level=level_str, $
        data_rate=mode_str, data_units=data_unit, $
        trange=time_range, sensor_eyes=eyes, tplotnames=tplotnames
        
        
    ; from mms_feeps_pad.
    datatype = 'electron'
    data_units = 'intensity'
    
    ; need 'mmsx_epd_feeps_srvy_l2_electron_pitch_angle' and 'mmsx_fgm_b_bcs_srvy_l2_bvec'.
    pa_var = prefix+'epd_feeps_'+mode_str+'_'+level_str+'_electron_pitch_angle'
    b_var = mms_read_bfield(time_range, probe=probe, coord='bcs')
    b_var2 = prefix+'fgm_b_bcs_'+mode_str+'_'+level_str+'_bvec'
    copy_data, b_var, b_var2
    stop
    mms_feeps_pad, probe=probe, energy=energy_range, $
        level=level_str, datatype='electron', data_units=data_units, $
        data_rate=mode_str
    mms_feeps_pad_spinavg, probe=probe, energy=energy_range, $
        level=level_str, datatype='electron', data_units=data_units, $
        data_rate=mode_str
    
    en_str = strjoin(string(energy_range,format='(I0)'),'-')+'keV'
    var = prefix+'epd_feeps_'+mode_str+'_'+level_str+'_electron_'+data_units+'_'+$
        en_str+'_pad_spin'
    copy_data, var, var_info


    zrange = (species eq 'e')? [1e0,1e5]: [1e0,1e5]
    species_name = 'e-'
    add_setting, var_info, smart=1, {$
        requested_time_range: time_range, $
        display_type: 'spec', $
        unit: '#/cm!U2!N-s-sr-keV', $
        zrange: zrange, $
        species_name: species_name, $
        ytitle: species_name+' PA (deg)', $
        ysubtitle: en_str, $
        ylog: 0, $
        zlog: 1, $
        yrange: [0,180], $
        ytickv: [0,90,180], $
        yticks: 2, $
        yminor: 3, $
        short_name: ''}
    
    return, var_info

end



function mms_read_pa_spec_kev, input_time_range, id=datatype, probe=probe, species=species, $
    print_datatype=print_datatype, errmsg=errmsg, $
    local_files=files, file_times=file_times, version=version, $
    local_root=local_root, remote_root=remote_root, $
    return_request=return_request 

    if n_elements(species) eq 0 then species = 'e'


    if species eq 'e' then begin
        return, mms_read_pa_spec_kev_ele(input_time_range, id=datatype, probe=probe, species=species, $
            print_datatype=print_datatype, errmsg=errmsg, $
            local_files=files, file_times=file_times, version=version, $
            local_root=local_root, remote_root=remote_root, $
            return_request=return_request)
    endif else begin
        return, mms_read_pa_spec_kev_ion(input_time_range, id=datatype, probe=probe, species=species, $
            print_datatype=print_datatype, errmsg=errmsg, $
            local_files=files, file_times=file_times, version=version, $
            local_root=local_root, remote_root=remote_root, $
            return_request=return_request)
    endelse

end


tr = time_double(['2016-08-04/22:15','2016-08-04/22:55'])
tr = time_double(['2016-08-04','2016-08-05'])
tr = time_double(['2016-10-14/20:00','2016-10-14/22:30'])
tr = time_double(['2016-10-14/12:00','2016-10-16/00:00'])

tr = time_double(['2016-08-04','2016-08-05'])
probe = '2'


pa_var = mms_read_pa_spec_kev(tr, probe=probe, species='e')
en_var = mms_read_en_spec_kev(tr, probe=probe, species='e')
stop

; keV electron.
timespan, tr[0], total(tr*[-1,1]), second=1
en_var = mms_read_en_spec_kev(tr, probe=probe, species='e')
mms_feeps_pad,  probe=probe, datatype='electron';, energy=[70,1000]
stop


; kev ion.
ion_vars = list()
foreach species, ['p','o','he','alpha'] do ion_vars.add, mms_read_pa_spec_kev(tr, probe=probe, species=species)
ion_vars = ion_vars.toarray()

end