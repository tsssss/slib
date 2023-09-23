;+
; Read Themis E field.
;-

function themis_read_efield, input_time_range, probe=probe, id=datatype, $
    errmsg=errmsg, coord=coord, get_name=get_name, _extra=ex

    prefix = 'th'+probe+'_'
    errmsg = ''
    retval = ''

    default_coord = 'themis_dsl'
    if n_elements(coord) eq 0 then coord = default_coord
    if n_elements(datatype) eq 0 then datatype = 'survey'
;    datatypes = ['spinfit','survey','burst','spinfit_phasef']
    datatypes = ['survey']
    index = where(datatypes eq datatype, count)
    if count eq 0 then begin
        errmsg = 'Invalid resolution: '+datatype+' ...'
        return, retval
    endif

    vec_coord_var = prefix+'e_'+coord
    if keyword_set(get_name) then begin
        return, vec_coord_var
    endif

    routine = 'themis_read_efield_'+datatype
    vec_default_var = call_function(routine, input_time_range, probe=probe, errmsg=errmsg, _extra=ex)

    ; Convert to the wanted coord.
    if coord ne default_coord then begin
        get_data, vec_default_var, times, vec_default, limits=lim
        vec_coord = cotran_pro(vec_coord, times, default_coord+'2'+coord, probe=probe)
        store_data, vec_coord_var, times, vec_coord, limits=lim
    endif

    add_setting, vec_coord_var, smart=1, dictionary($
        'display_type', 'vector', $
        'unit', 'mV/m', $
        'short_name', 'E', $
        'coord', strupcase(coord), $
        'coord_labels', constant('xyz') )

    return, vec_coord_var

end