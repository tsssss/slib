;+
; Read the energy-time spectrogram.
; time_range.
; probe=.
;-

function dmsp_read_en_spec_cdaweb, input_time_range, probe=probe, errmsg=errmsg, $
    species=species, get_name=get_name, suffix=suffix

    prefix = 'dmsp'+probe+'_'
    errmsg = ''
    retval = ''

    if n_elements(suffix) eq 0 then suffix = '_cdaweb'
    if n_elements(species) eq 0 then species = 'e'
    all_species = dmsp_ssj_species()
    index = where(all_species eq species, count)
    if count eq 0 then begin
        errmsg = 'Invalid species: '+species+' ...'
        return, retval
    endif

    spec_var = prefix+species+'_en_spec'+suffix
    if keyword_set(get_name) then return, spec_var

    time_range = time_double(input_time_range)
    if ~check_if_update(spec_var, time_range) then return, spec_var

    files = dmsp_load_ssj_cdaweb(time_range, probe=probe, errmsg=errmsg)
    if errmsg ne '' then return, retval

    var_list = list()
    in_var = (species eq 'e')? 'ELE_DIFF_ENERGY_FLUX': 'ION_DIFF_ENERGY_FLUX'
    var_list.add, dictionary($
        'in_vars', in_var, $
        'time_var_name', 'Epoch', $
        'time_var_type', 'Epoch' )
    
    read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg
    if errmsg ne '' then return, retval

    energy_bins = cdf_read_var('CHANNEL_ENERGIES', filename=files[0])
    get_data, in_var, times, fluxs
    store_data, spec_var, times, fluxs, energy_bins
    zrange = (species eq 'e')? [1e5,1e9]: [1e4,1e8]
    species_name = (species eq 'e')? 'e-': 'H+'
    add_setting, spec_var, smart=1, dictionary($
        'requested_time_range', time_range, $
        'display_type', 'spec', $
        'unit', 'eV/cm!U2!N-sr-s-eV', $
        'zrange', zrange, $
        'species_name', species_name, $
        'ytitle', 'Energy (eV)', $
        'ylog', 1, $
        'zlog', 1, $
        'short_name', '' )
    
    return, spec_var

end



time_range = time_double(['2013-05-01/07:00','2013-05-01/10:00'])
probes = 'f'+['16','17','18']
foreach probe, probes do var = dmsp_read_en_spec(time_range, probe=probe, species='e')
tplot, var, trange=time_range
end