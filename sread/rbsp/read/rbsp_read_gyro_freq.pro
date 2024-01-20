;+
; Read RBSP gyro frequencies.
;-

function get_mass, species
    e_mass = 0.91e-30   ; kg.
    if species eq 'e' then return, e_mass
    p_mass = 1.67e-27   ; kg.
    if species eq 'p' then return, p_mass
    if species eq 'o' then return, p_mass*16
    if species eq 'he' then return, p_mass*4
end


function rbsp_read_gyro_freq, input_time_range, probe=probe, errmsg=errmsg, $
    species=species, get_name=get_name, $
    update=update, suffix=suffix, resolution=resolution


    prefix = 'rbsp'+probe+'_'
    errmsg = ''
    retval = ''

    if n_elements(species) eq 0 then species = 'e'
    all_species = rbsp_hope_species()
    index = where(all_species eq species, count)
    if count eq 0 then begin
        errmsg = 'Invalid species: '+species+' ...'
        return, retval
    endif

    if n_elements(suffix) eq 0 then suffix = ''
    fc_var = prefix+'fc'+species+suffix
    if keyword_set(get_name) then return, fc_var
    if keyword_set(update) then del_data, fc_var
    time_range = time_double(input_time_range)
    if ~check_if_update(fc_var, time_range) then return, fc_var

    if n_elements(resolution) eq 0 then resolution = '1sec'
    b_var = rbsp_read_bfield(time_range, probe=probe, resolution=resolution, suffix='_'+resolution)
    q = 1.6e-19 ; C
    mass = get_mass(species)
    f_c0 = 1e-9*q/(2*!dpi*mass) ; in Hz.
    bmag = snorm(get_var_data(b_var, times=times))
    f_cq = f_c0*bmag
    store_data, fc_var, times, f_cq
    add_setting, fc_var, smart=1, dictionary($
        'display_type', 'scalar', $
        'short_name', 'f!Dc'+species, $
        'unit', 'Hz', $
        'ylog', 1, $
        'requested_time_range', time_range )
    return, fc_var

end

time_range = ['2015-03-17','2015-03-18']
probe = 'a'
var = rbsp_read_gyro_freq(time_range, probe=probe)
end