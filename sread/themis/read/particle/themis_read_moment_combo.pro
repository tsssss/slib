;+
; Read Themis ESA+SST moments.
;-

function themis_read_moment_combo, input_time_range, probe=probe, $
    errmsg=errmsg, id=id, update=update, $
    species=species0, coord=coord, get_name=get_name

    errmsg = ''
    retval = dictionary()

;---Check input.
    ; probe.
    if ~themis_probe_is_valid(probe) then begin
        errmsg = 'Invalid probe: '+probe+' ...'
        return, retval
    endif
    prefix = 'th'+probe+'_'


;---Read data and convert coord.
    if n_elements(id) eq 0 then id = 'esa_sst_integrate'
    routine = 'themis_read_moment_combo_'+id
    time_range = time_double(input_time_range)
    vinfo = call_function(routine, time_range, probe=probe, errmsg=errmsg, $
        species=species0, update=update, get_name=get_name)

    ; vectors.
    default_coord = 'gsm'
    if n_elements(coord) eq 0 then coord = default_coord
    orig_coord = 'themis_dsl'
    foreach key, vinfo.keys() do begin
        var = vinfo[key]
        display_type = get_setting(var, 'display_type')
        if display_type ne 'vector' then continue
        input_coord = get_setting(var, 'coord')
        if input_coord eq coord then continue
        idx = strpos(var, input_coord)
        var_out = strmid(var,0,idx)+coord+strmid(var,idx+strlen(input_coord))
        vinfo[key] = var_out
        if keyword_set(get_name) then continue
        if keyword_set(update) then del_data, var_out
        if ~check_if_update(var_out, time_range) then continue
        msg = input_coord+'2'+coord
        vec = cotran_pro(get_var_data(var, times=times, limits=lim), times, msg, probe=probe)
        store_data, var_out, times, vec
        settings = dictionary(lim)
        settings.coord = coord
        add_setting, var_out, smart=1, settings
    endforeach
    

    return, vinfo


end


time_range = time_double(['2017-03-09/06:30','2017-03-09/09:00'])
probes = ['d']
species = ['e','p']
update = 0
get_name = 0
foreach the_species, species do begin
    foreach probe, probes do begin
        vinfo = themis_read_moment_combo(time_range, probe=probe, $
            species=the_species, update=update, get_name=get_name)
        print, vinfo
    endforeach
endforeach
end