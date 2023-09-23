;+
; Read Themis ESA moments.
;-

function themis_read_moment_combo_esa_l2, input_time_range, probe=probe, errmsg=errmsg, id=id, $
    species=species0, coord=coord

    errmsg = ''
    retval = ''
    prefix = 'th'+probe+'_'

    if n_elements(species0) eq 0 then species0 = 'i'
    species = species0
    if species eq 'p' then species = 'i'
    if ~themis_esa_species_is_valid(species) then begin
        errmsg = 'Invalid species: '+species+' ...'
        return, retval
    endif
    species1 = species
    if species1 eq 'i' then species1 = 'p'

    if ~themis_probe_is_valid(probe) then begin
        errmsg = 'Invalid probe: '+probe+' ...'
        return, retval
    endif
    default_coord = 'dsl'
    if n_elements(coord) eq 0 then coord = default_coord


    time_range = time_double(input_time_range)
    files = themis_load_esa(time_range, id='l2', probe=probe, errmsg=errmsg)
    if errmsg ne '' then return, retval
    
    type = 'pe'+species+'r'
    prefix1 = prefix+type+'_'
    prefix2 = prefix+the_species+'_'
    ; Doesn't work b/c the file does not have eflux.
    in_vars = prefix1+['density','avgtemp','velocity','flux','t3','ptens','mftens']
    out_vars = prefix1+['n','t',['vbulk','nflux']+'_'+coord,'t3','ptens','mftens']

    var_list = list()
    var_list.add, dictionary($
        'in_vars', in_vars, $
        'out_vars', out_vars, $
        'time_var_name', prefix1+'time', $
        'time_var_type', 'unix')
    
    read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg
    if errmsg ne '' then return, retval


;---Processes after reading the vars.
    scalar_vars = prefix1+['n','t']
    short_names = ['N','T']
    units = ['cm!U-3','eV']
    foreach scalar_var, scalar_vars, var_id do begin
        short_name = species_name+' '+short_names[var_id]
        unit = units[var_id]
        add_setting, scalar_var, smart=1, dictionary($
            'display_type', 'scalar', $
            'short_name', short_name, $
            'unit', unit, $
            'ylog', 1 )
    endforeach


    short_names = ['V','F']
    units = ['km/s','#/cm!U2!N-s']
    want_suffix = '_'+coord
    vector_vars = prefix1+['vbulk','nflux']
    foreach var, vector_vars, var_id do begin
        var_default = var+default_suffix
        var_want = var+want_suffix
        if coord ne default_coord then begin
            vec_default = get_var_data(var_default, times=times)
            msg = default_coord+'2'+coord
            vec = cotran_pro(vec_default, times, msg, probe=probe)
            store_data, var_want, times, vec
        endif

        short_name = species_name+' '+short_names[var_id]
        unit = units[var_id]
        add_setting, var_want, smart=1, dictionary($
            'display_type', 'vector', $
            'short_name', short_name, $
            'unit', unit, $
            'coord', strupcase(coord) )
    endforeach

    return, vinfo


end


time_range = time_double(['2017-03-09/07:00','2017-03-09/09:00'])
probes = ['d','e']
species = ['e','p']
foreach the_species, species do begin
    foreach probe, probes do begin
        vinfo = themis_read_moment_combo_esa_l2(time_range, probe=probe, species=the_species)
    endforeach
endforeach
end