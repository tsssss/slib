function themis_read_en_spec_esa_l2, input_time_range, probe=probe, errmsg=errmsg, $
    species=species0, get_name=get_name, id=id, update=update

    prefix = 'th'+probe+'_'
    errmsg = ''
    retval = ''

    if n_elements(species0) eq 0 then species0 = 'i'
    species = species0
    if species eq 'p' then species = 'i'
    if ~themis_esa_species_is_valid(species) then begin
        errmsg = 'Invalid species: '+species+' ...'
        return, retval
    endif
    species1 = species
    if species1 eq 'i' then species1 = 'p'
    if n_elements(suffix) eq 0 then suffix = '_esa_l2'

    var_info = prefix+species1+'_en_spec'+suffix
    if keyword_set(get_name) then return, var_info
    if keyword_set(update) then res = delete_var_from_memory(var_info)
    time_range = time_double(input_time_range)
    if ~check_if_update_memory(var_info, time_range) then return, var_info

    files = themis_load_esa(time_range, id='l2', probe=probe, errmsg=errmsg)
    if errmsg ne '' then return, retval

    if n_elements(id) ne 0 then the_type = id else the_type = 'pe'+species+'r'

    var_list = list()
    var_list.add, dictionary($
        'in_vars', prefix+the_type+'_en_eflux'+['','_yaxis'], $
        'out_vars', var_info+['','_en'], $
        'time_var_name', prefix+the_type+'_time', $
        'time_var_type', 'unix')
    
    read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg
    if errmsg ne '' then return, retval


    get_data, var_info, times, spec
    get_data, var_info+'_en', times, en_bins
    ; Convert unit from eV/(cm^2-s-sr-eV) to #/cm^2-s-sr-keV
    ; spec = spec/(en_bins*1e-3)
    ; unit = '#/cm!E2!N-s-sr-keV'
    store_data, var_info, times, spec, en_bins
    unit = 'eV/cm!E2!N-s-sr-eV'

    zrange = (species eq 'e')? [1e4,1e9]: [1e4,5e6]
    species_name = themis_esa_get_species_name(species)
    ct = (species eq 'e')? get_ct('electron'): get_ct('proton')
    add_setting, var_info, smart=1, dictionary($
        'display_type', 'spec', $
        'unit', unit, $
        'zrange', zrange, $
        'species_name', species_name, $
        'ytitle', 'Energy!C(eV)', $
        'ylog', 1, $
        'zlog', 1, $
        'zticklen', -0.5, $
        'color_table', ct, $
        'short_name', '' )

    return, var_info
end


time_range = time_double('2017-03-09')+[0,43200d]
probes = ['d','e']
species = ['e','p']
foreach the_species, species do begin
    foreach probe, probes do begin
        print, themis_read_en_spec_esa_l2(time_range, probe=probe, species=the_species)
        print, themis_read_en_spec_combo(time_range, probe=probe, species=the_species)
    endforeach
endforeach
end