;+
; Read electron pitch angle spectrogram.
; species=. ['e']
; pitch_angle_range=. [0,180]
; id=. ['all','kev','thermal']
;-

function mms_read_en_spec_ele_cdaweb, input_time_range, id=datatype, probe=probe, species=species, var_info=var_info, $
    pitch_angle_range=pitch_angle_range, $
    print_datatype=print_datatype, errmsg=errmsg, $
    local_files=files, file_times=file_times, version=version, $
    local_root=local_root, remote_root=remote_root, $
    return_request=return_request, $
    get_name=get_name, suffix=suffix, update=update
    

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
    if n_elements(species) eq 0 then species = 'e'
    species_str = 'e-'


    if n_elements(datatype) eq 0 then datatype = 'cdaweb'
    if n_elements(suffix) eq 0 then suffix = '_'+datatype
    if n_elements(var_info) eq 0 then var_info = prefix+species+'_en_spec'+suffix
    if keyword_set(get_name) then return, var_info
    if keyword_set(update) then del_data, var_info
    time_range = time_double(input_time_range)
    if ~check_if_update(var_info, time_range) then return, var_info


    instr_str = 'fpi'
    species = 'e'
    species_str = 'ele'
    mode_str = 'fast'
    level_str = 'l2'
    datatype_str = 'des-moms'
    id = strjoin([level_str,mode_str,datatype_str],'%')
    files = mms_ld_fpi(time_range, probe=probe, id=id, errmsg=errmsg)
    if errmsg ne '' then return, retval


    prefix2 = prefix+'des_'
    var_list = list()
    in_vars = [prefix2+['energy','energyspectr_omni']+'_'+mode_str]
    flux_var = in_vars[1]
    energy_var = in_vars[0]
    var_list.add, dictionary($
        'in_vars', in_vars, $
        'time_var_name', 'Epoch', $
        'time_var_type', 'tt2000' )
    read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg    
    if errmsg ne '' then return, retval

    ; Get the fluxs.
    en_fluxs = get_var_data(flux_var, times=times) ; in [ntime,nen]
    ntime = n_elements(times)
    index = where(en_fluxs le 0, count)
    if count ne 0 then en_fluxs[index] = 0
    en_centers = get_var_data(energy_var)
    settings = dictionary($
        'unit', 'keV/cm!!U2!N-s-sr-keV', $
        'en_unit', 'eV' )

    store_data, var_info, times, en_fluxs, en_centers
    unit = settings.unit
    energy_unit = settings.en_unit
    add_setting, var_info, smart=1, {$
        requested_time_range: time_range, $
        display_type: 'spec', $
        unit: unit, $
        species: species, $
        species_name: species_str, $
        ytitle: 'Energy!C('+energy_unit+')', $
        subytitle: species_str, $
        ylog: 1, $
        zlog: 1, $
        short_name: ''}

    dr = sdatarate(times)
    times = make_bins(time_range, dr)
    interp_time, var_info, times

    return, var_info
end


tr = ['2015-09-01','2015-09-02']
;tr = ['2015-08-27','2015-08-28']
probe = '1'
;mms_load_fpi, tr=tr, probe=probe, datatype='des-moms', level='l2', data_rate='fast'
var = mms_read_en_spec_ele_cdaweb(tr, probe=probe)
tplot, var, trange=tr
end