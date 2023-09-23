function rbsp_read_density_hope, input_time_range, probe=probe, $
errmsg=errmsg, get_name=get_name, species=species

    prefix = 'rbsp'+probe+'_'
    errmsg = ''
    retval = ''

    if n_elements(species) eq 0 then species = 'e'
    index = where(species eq rbsp_hope_species(), count)
    if count eq 0 then begin
        errmsg = 'Invalid species: '+species+' ...'
        return, retval
    endif
    species_name = rbsp_hope_species_name(species)
    var = prefix+species+'_density'
    if keyword_set(get_name) then return, var

    time_range = time_double(input_time_range)
    files = rbsp_load_hope(time_range, probe=probe, id='l3%mom', errmsg=errmsg)
    if errmsg ne '' then return, retval

    var_list = list()
    
    suffix = (species eq 'e')? '_200': '_30'
    in_vars = 'Dens_'+species+suffix
    time_var = (species eq 'e')? 'Epoch_Ele': 'Epoch_Ion'
    var_list.add, dictionary($
        'in_vars', in_vars, $
        'out_vars', var, $
        'time_var_name', time_var, $
        'time_var_type', 'epoch')
    read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg
    if errmsg ne '' then return, retval
    
    get_data, var, times, data
    index = where(abs(data) ge 1e30, count)
    if count ne 0 then begin
        data[index] = !values.f_nan
        store_data, var, times, data
    endif
    
    add_setting, var, /smart, dictionary($
        'display_type', 'scalar', $
        'unit', 'cm!U-3!N', $
        'ylog', 1, $
        'short_name', species_name+' N' )

    return, var
    
end

time_range = time_double(['2015-02-17/22:00','2015-02-18/08:00'])
time_range = time_double(['2013-05-01','2013-05-02'])
probe = 'b'
var = rbsp_read_density_hope(time_range, probe=probe)
end