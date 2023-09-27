;+
; Read Themis E field.
;-

function themis_read_efield, input_time_range, probe=probe, id=datatype, $
    errmsg=errmsg, coord=coord, get_name=get_name, update=update, _extra=ex

    prefix = 'th'+probe+'_'
    errmsg = ''
    retval = ''

    default_coord = 'themis_dsl'
    if n_elements(coord) eq 0 then coord = default_coord
    if n_elements(datatype) eq 0 then datatype = 'survey'
;    datatypes = ['spinfit','survey','burst','spinfit_phasef']
    datatypes = ['survey','spinfit']
    index = where(datatypes eq datatype, count)
    if count eq 0 then begin
        errmsg = 'Invalid resolution: '+datatype+' ...'
        return, retval
    endif

    routine = 'themis_read_efield_'+datatype
    time_range = time_double(input_time_range)
    vec_coord_var = call_function(routine, time_range, probe=probe, $
        errmsg=errmsg, coord=coord, get_name=1, _extra=ex)
    if keyword_set(get_name) then return, vec_coord_var
    if keyword_set(update) then del_data, vec_coord_var
    if ~check_if_update(vec_coord_var, time_range) then return, vec_coord_var
    
    return, call_function(routine, time_range, probe=probe, $
        errmsg=errmsg, coord=coord, _extra=ex)
;    ; Convert to the wanted coord.
;    if coord ne default_coord then begin
;        get_data, vec_default_var, times, vec_default, limits=lim
;        vec_coord = cotran_pro(vec_default, times, default_coord+'2'+coord, probe=probe)
;        store_data, vec_coord_var, times, vec_coord, limits=lim
;    endif
;
;    add_setting, vec_coord_var, id='efield', dictionary($
;        'requested_time_range', time_range, $
;        'coord', coord )

    return, vec_coord_var

end