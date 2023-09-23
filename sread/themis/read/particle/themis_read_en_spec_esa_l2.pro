function themis_read_en_spec_esa_l2, input_time_range, probe=probe, errmsg=errmsg, $
    species=species0, get_name=get_name, id=id

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

    spec_var = prefix+species1+'_en_spec'
    if keyword_set(get_name) then return, spec_var

    time_range = time_double(input_time_range)
    files = themis_load_esa(time_range, id='l2', probe=probe, errmsg=errmsg)
    if errmsg ne '' then return, retval

    if n_elements(id) ne 0 then the_type = id else the_type = 'pe'+species+'r'

    var_list = list()
    var_list.add, dictionary($
        'in_vars', prefix+the_type+'_en_eflux'+['','_yaxis'], $
        'out_vars', spec_var+['','_en'], $
        'time_var_name', prefix+the_type+'_time', $
        'time_var_type', 'unix')
    
    read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg
    if errmsg ne '' then return, retval


    get_data, spec_var, times, spec
    get_data, spec_var+'_en', times, en_bins
    ; Convert unit from eV/(cm^2-s-sr-eV) to #/cm^2-s-sr-keV
    spec = spec/(en_bins*1e-3)
    store_data, spec_var, times, spec, en_bins

    zrange = (species eq 'e')? [1e4,1e9]: [1e4,5e6]
    species_name = themis_esa_get_species_name(species)
    ct = (species eq 'e')? get_ct('electron'): get_ct('proton')
    add_setting, spec_var, smart=1, dictionary($
        'display_type', 'spec', $
        'unit', '#/cm!E2!N-s-sr-keV', $
        'zrange', zrange, $
        'species_name', species_name, $
        'ytitle', 'Energy!C(eV)', $
        'ylog', 1, $
        'zlog', 1, $
        'color_table', ct, $
        'short_name', '' )

    return, spec_var
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