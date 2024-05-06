;+
; Load MMS en spec for thermal particles.
;-

function mms_read_en_spec_ion, input_time_range, id=datatype, probe=probe, species=species, $
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
        'p', 'hplus', $
        'o', 'oplus', $
        'he', 'heplus', $
        'alpha', 'heplusplus' )
    species_name_info = dictionary($
        'p', 'H+', $
        'o', 'O+', $
        'he', 'He+', $
        'alpha', 'He++' )

    ; Prepare var name.
    if n_elements(species) eq 0 then species = 'p'
    var_info = prefix+species+'_en_spec'
    if keyword_set(get_name) then return, var_info
    if keyword_set(update) then del_data, var_info
    time_range = time_double(input_time_range)
    if ~check_if_update(var_info, time_range) then return, var_info

    ; Load files.
    mode_str = 'srvy'
    level_str = 'l2'
    datatype_str = 'ion'
    id = strjoin([level_str,mode_str,datatype_str],'%')
    files = mms_ld_hpca(time_range, probe=probe, id=id, errmsg=errmsg)
    if errmsg ne '' then return, retval

    ; Read data (need further clean up. Right now just adopting from mms_load_hpca).
    cdf2tplot, files, tplotnames=tplotnames

    ; calibrate data (adopted from mms_load_hpca)
    ; mms_load_hpca_fix_dist doesn't work, need to add value to flux.
    flux_var = prefix+'hpca_'+species_info[species]+'_flux'
    energy_bins = mms_hpca_energies()
    get_data, flux_var, times, fluxs, limits=lim, dlimit=dlim
    enspec = total(fluxs,3)
    store_data, var_info, times, enspec, energy_bins
    
    ;hpca_info = mms_get_hpca_info()
    ;elev_angles = hpca_info.elevation
    
    add_setting, var_info, smart=1, dictionary($
        'display_type', 'spec', $
        'ytitle', 'Energy (eV)', $
        'ysubtitle', species_name_info[species], $
        'unit', '#/cm!E2!N-s-sr-eV', $
        'ylog', 1, $
        'zlog', 1, $
        'short_name', '', $
        'requested_time_range', time_range, $
        'probe', probe, $
        'mission', 'mms' )
    
    return, var_info
end


function mms_read_en_spec_ele, input_time_range, id=datatype, probe=probe, species=species, $
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
    var_info = prefix+species+'_en_spec'
    if keyword_set(get_name) then return, var_info
    if keyword_set(update) then del_data, var_info
    time_range = time_double(input_time_range)
    if ~check_if_update(var_info, time_range) then return, var_info

    ; Load files.
    mode_str = 'fast'
    level_str = 'l2'
    datatype_str = 'des-moms'
    id = strjoin([level_str,mode_str,datatype_str],'%')
    files = mms_ld_fpi(time_range, probe=probe, id=id, errmsg=errmsg)
    if errmsg ne '' then return, retval

    var_list = list()
    en_var = prefix+'e_energy'
    var_list.add, dictionary($
        'in_vars', prefix+'des_'+['energyspectr_omni','energy']+'_'+mode_str, $
        'out_vars', [var_info,en_var], $
        'time_var_name', 'Epoch', $
        'time_var_type', 'tt2000' )
    read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg
    if errmsg ne '' then return, ''
    add_setting, var_info, dictionary($
        'requested_time_range', time_range, $
        'probe', probe, $
        'mission', 'mms' )
    
    fluxs = get_var_data(var_info, times=times)
    energys = get_var_data(en_var)  ; in eV.
    fluxs = fluxs/(energys*1e-3)   ; convert from kev/cm^2-s-sr-kev to #/cm^2-s-sr-kev.
    store_data, var_info, times, fluxs, energys

    add_setting, var_info, smart=1, dictionary($
        'display_type', 'spec', $
        'ytitle', 'Energy (eV)', $
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


function mms_read_en_spec, input_time_range, id=datatype, probe=probe, species=species, $
    print_datatype=print_datatype, errmsg=errmsg, $
    local_files=files, file_times=file_times, version=version, $
    local_root=local_root, remote_root=remote_root, $
    return_request=return_request

    if n_elements(species) eq 0 then species = 'e'


    if species eq 'e' then begin
        return, mms_read_en_spec_ele(input_time_range, id=datatype, probe=probe, species=species, $
            print_datatype=print_datatype, errmsg=errmsg, $
            local_files=files, file_times=file_times, version=version, $
            local_root=local_root, remote_root=remote_root, $
            return_request=return_request)
    endif else begin
        return, mms_read_en_spec_ion(input_time_range, id=datatype, probe=probe, species=species, $
            print_datatype=print_datatype, errmsg=errmsg, $
            local_files=files, file_times=file_times, version=version, $
            local_root=local_root, remote_root=remote_root, $
            return_request=return_request)
    endelse

end


tr = time_double(['2016-08-04/22:15','2016-08-04/22:55'])
data_tr = time_double(['2016-08-04','2016-08-04/10:00'])
data_tr = time_double(['2016-08-09/08:00','2016-08-09/10:00'])
probe = '2'

; electron.
ele_var = mms_read_en_spec(data_tr, probe=probe, species='e')
stop
; ion.
ion_vars = list()
foreach species, ['p','o','he','alpha'] do ion_vars.add, mms_read_en_spec(data_tr, probe=probe, species=species)
ion_vars = ion_vars.toarray()

end