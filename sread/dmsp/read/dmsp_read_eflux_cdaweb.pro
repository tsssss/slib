;+
; Read eflux for given species.
;-

function dmsp_read_eflux_cdaweb, input_time_range, probe=probe, errmsg=errmsg, $
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

    eflux_var = prefix+species+'_eflux'+suffix
    if keyword_set(get_name) then return, eflux_var

    time_range = time_double(input_time_range)
    if ~check_if_update(eflux_var, time_range) then return, eflux_var

    files = dmsp_load_ssj_cdaweb(time_range, probe=probe, errmsg=errmsg)
    if errmsg ne '' then return, retval

    var_list = list()
    in_var = (species eq 'e')? 'ELE_TOTAL_ENERGY_FLUX': 'ION_TOTAL_ENERGY_FLUX'
    var_list.add, dictionary($
        'in_vars', in_var, $
        'out_vars', eflux_var, $
        'time_var_name', 'Epoch', $
        'time_var_type', 'Epoch' )
    read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg
    if errmsg ne '' then return, retval
    
    add_setting, eflux_var, smart=1, dictionary($
        'requested_time_range', time_range, $
        'display_type', 'scalar', $
        'unit', 'eV/cm!U2!N-sr-s', $
        'short_name', tex2str('Gamma'), $
        'ylog', 1 )
    return, eflux_var

end


time_range = time_double(['2013-05-01/07:00','2013-05-01/10:00'])
probes = 'f'+['16','17','18']
foreach probe, probes do var = dmsp_read_eflux_cdaweb(time_range, probe=probe, species='e')
tplot, var, trange=time_range
end