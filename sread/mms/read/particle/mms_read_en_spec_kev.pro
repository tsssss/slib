;+
; Load MMS en spec for high energy particles.
;-

function mms_read_en_spec_kev_ion, input_time_range, id=datatype, probe=probe, species=species, $
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
    
    species_info = dictionary($
        'p', 'proton', $
        'o', 'oxygen', $
        'he', 'helium', $
        'alpha', 'alpha' )
    species_name_info = dictionary($
        'p', 'H+', $
        'o', 'O+', $
        'he', 'He+', $
        'alpha', 'He++' )


    ; Prepare var name.
    if n_elements(species) eq 0 then species = 'p'
    var_info = prefix+species+'_en_spec_kev'
    if keyword_set(get_name) then return, var_info
    if keyword_set(update) then del_data, var_info
    time_range = time_double(input_time_range)
    if ~check_if_update(var_info, time_range) then return, var_info

    ; Load files.
    mode_str = 'srvy'
    level_str = 'l2'
    datatype_str = 'extof'
    id = strjoin([level_str,mode_str,datatype_str],'%')
    files = mms_ld_eis(time_range, probe=probe, id=id, errmsg=errmsg)
    if errmsg ne '' then return, retval

    ; Read data (need further clean up. Right now just adopting from mms_load_eis.
    the_prefix = prefix+'epd_eis_'
    midfix = mode_str+'_'+level_str+'_'
    new_prefix = the_prefix+midfix
    species_str = species_info[species]
    data_unit = 'flux'
       
    cdf2tplot, files, get_support_data=1, tplotnames=tplotnames, midfix=midfix, midpos=strlen(the_prefix)
    ; need to add energy to flux.
    foreach var, cdf_vars(files[0]), vid do begin
        vatt = cdf_read_setting(var, filename=files[0])
        ;if var eq 'mms2_epd_eis_extof_proton_P3_flux_t0' then stop
        if vatt.haskey('DEPEND_1') then begin
            the_var = streplace(var, the_prefix, new_prefix)
            get_data, the_var, times, data
            dep_var = vatt['DEPEND_1']
            vals = cdf_read_var(dep_var, filename=files[0])
            store_data, the_var, times, data, vals
        endif
    endforeach

    ; need mmsx_epd_eis_srvy_l2_extof_spin
    mms_eis_spin_avg, probe=probe, $
        datatype=datatype_str, species=species_str, data_units=data_unit, data_rate=mode_str, level=level_str
    ; need mmsx_epd_eis_srvy_l2_extof_proton_*flux_t?_spin, generated from the above routine.
    mms_eis_omni, spin=1, tplotnames=tplotnames, probe, $
        datatype=datatype_str, species=species_str, data_units=data_unit, data_rate=mode_str, level=level_str
    ; need mmsx_epd_eis_srvy_l2_extof_proton_*flux_t?
    mms_eis_omni, spin=0, tplotnames=tplotnames, probe, $
        datatype=datatype_str, species=species_str, data_units=data_unit, data_rate=mode_str, level=level_str

    spec_var = new_prefix+datatype_str+'_'+species_str+'_flux_omni'
    var_info = rename_var(spec_var, output=var_info)
    
    add_setting, var_info, smart=1, dictionary($
        'display_type', 'spec', $
        'ytitle', 'Energy (keV)', $
        'ysubtitle', species_name_info[species], $
        'unit', '#/cm!E2!N-s-sr-keV', $
        'ylog', 1, $
        'zlog', 1, $
        'short_name', '', $
        'requested_time_range', time_range, $
        'probe', probe, $
        'mission', 'mms' )
    return, var_info
    
end


    

function mms_read_en_spec_kev_ele, input_time_range, id=datatype, probe=probe, species=species, $
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
    var_info = prefix+species+'_en_spec_kev'
    if keyword_set(get_name) then return, var_info
    if keyword_set(update) then del_data, var_info
    time_range = time_double(input_time_range)
    if ~check_if_update(var_info, time_range) then return, var_info

    ; Load files.
    mode_str = 'srvy'
    level_str = 'l2'
    id = strjoin([level_str,mode_str,'electron'],'%')
    files = mms_ld_feeps(time_range, probe=probe, id=id, errmsg=errmsg)
    if errmsg ne '' then return, retval
    
    ; Read data (need further clean up. Right now just adopting from mms_load_feeps.
    cdf2tplot, files
    tplotnames = cdf_vars(files[0])

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

    ; calculate the omni-directional spectra
    mms_feeps_omni, this_probe, datatype=this_datatype, data_units=data_unit, $
        data_rate=mode_str, level=level_str, sensor_eyes=eyes

    ; calculate the spin averages
    mms_feeps_spin_avg, probe=this_probe, datatype=this_datatype, data_units=data_unit, $
        data_rate=mode_str, level=level_str, tplotnames=tplotnames
    
    var = prefix+'epd_feeps_'+mode_str+'_'+level_str+'_'+this_datatype+'_'+data_unit+'_omni_spin'
    copy_data, var, var_info
    
    add_setting, var_info, smart=1, dictionary($
        'display_type', 'spec', $
        'ytitle', 'Energy (keV)', $
        'ysubtitle', 'e-', $
        'unit', '#/cm!E2!N-s-sr-keV', $
        'ylog', 1, $
        'zlog', 1, $
        'short_name', '', $
        'requested_time_range', time_range, $
        'probe', probe, $
        'mission', 'mms' )
    
    return, var_info

end


function mms_read_en_spec_kev, input_time_range, id=datatype, probe=probe, species=species, $
    print_datatype=print_datatype, errmsg=errmsg, $
    local_files=files, file_times=file_times, version=version, $
    local_root=local_root, remote_root=remote_root, $
    return_request=return_request

    if n_elements(species) eq 0 then species = 'e'


    if species eq 'e' then begin
        return, mms_read_en_spec_kev_ele(input_time_range, id=datatype, probe=probe, species=species, $
            print_datatype=print_datatype, errmsg=errmsg, $
            local_files=files, file_times=file_times, version=version, $
            local_root=local_root, remote_root=remote_root, $
            return_request=return_request)
    endif else begin
        return, mms_read_en_spec_kev_ion(input_time_range, id=datatype, probe=probe, species=species, $
            print_datatype=print_datatype, errmsg=errmsg, $
            local_files=files, file_times=file_times, version=version, $
            local_root=local_root, remote_root=remote_root, $
            return_request=return_request)
    endelse

end


tr = time_double(['2016-08-04/22:15','2016-08-04/22:55'])
data_tr = time_double(['2016-08-04','2016-08-05'])
probe = '2'

; keV electron.
ele_var = mms_read_en_spec_kev(data_tr, probe=probe, species='e')

; kev ion.
ion_vars = list()
foreach species, ['p','o','he','alpha'] do ion_vars.add, mms_read_en_spec_kev(data_tr, probe=probe, species=species)
ion_vars = ion_vars.toarray()

end