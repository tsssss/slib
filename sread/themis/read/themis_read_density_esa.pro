;+
; Read electron density.
;-

function themis_read_density_esa, input_time_range, probe=probe, $
    errmsg=errmsg, get_name=get_name, id=datatype, species=species


    errmsg = ''
    retval = ''

    if ~themis_probe_is_valid(probe) then begin
        errmsg = 'Invalid probe: '+probe+' ...'
        return, retval
    endif
    prefix = 'th'+probe+'_'

    ; Prepare var name.
    if n_elements(species) eq 0 then species = 'e'
    index = where(species eq themis_esa_get_species(), count)
    if count eq 0 then begin
        errmsg = 'Invalid species: '+species+' ...'
        return, retval
    endif
    species_name = themis_esa_get_species_name(species)
    var = prefix+species+'_density'
    if keyword_set(get_name) then return, var

    ; Load files.
    time_range = time_double(input_time_range)
    if ~check_if_update(var, time_range) then return, var
    files = themis_load_esa(time_range, probe=probe, id='l2', errmsg=errmsg)
    if errmsg ne '' then return, retval

    datatype = (n_elements(datatype) ne 0)? strlowcase(datatype): 'pe'+species+'r'
    case datatype of
        'peer': time_step = 3d       ; Reduced mode.
        'peeb': time_step = !null    ; Burst mode.
        'peef': time_step = !null    ; Full
        'peir': time_step = 3d       ; Reduced mode.
        'peib': time_step = !null    ; Burst mode.
        'peif': time_step = !null    ; Full
    endcase

;---Read data.
    var_list = list()
    in_vars = prefix+[datatype+'_density']
    out_vars = var
    var_list.add, dictionary($
        'in_vars', in_vars, $
        'out_vars', out_vars, $
        'time_var_name', prefix+datatype+'_time', $
        'time_var_type', 'unix' )
    read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg
    if errmsg ne '' then return, ''


    add_setting, var, smart=1, dictionary($
        'display_type', 'scalar', $
        'unit', 'cm!U-3!N', $
        'ylog', 1, $
        'short_name', species_name+' N' )
    return, var

end

time_range = time_double(['2014-08-28','2014-08-29'])
probe = 'a'
var = themis_read_density_esa(time_range, probe=probe)
end