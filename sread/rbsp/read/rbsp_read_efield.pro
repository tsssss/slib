;+
; Read RBSP E field.
;
; input_time_range.
; probe=. 'a', 'b'.
; resolution=. 'hires', 'survey', 'burst','spinfit','spinfit_phasef'.
; coord=. 'gsm','ges','gei','sm'
;-

function rbsp_read_efield, input_time_range, probe=probe, $
resolution=resolution, errmsg=errmsg, coord=coord, get_name=get_name, _extra=ex

    prefix = 'rbsp'+probe+'_'
    errmsg = ''
    retval = ''

    default_coord = 'mgse'
    if n_elements(coord) eq 0 then coord = default_coord
    if n_elements(resolution) eq 0 then resolution = 'survey'
    resolutions = ['spinfit','survey','burst','spinfit_phasef']
    index = where(resolutions eq resolution, count)
    if count eq 0 then begin
        errmsg = 'Invalid resolution: '+resolution+' ...'
        return, retval
    endif

    vec_coord_var = prefix+'e_'+coord
    if keyword_set(get_name) then begin
        return, vec_coord_var
    endif

    routine = 'rbsp_read_efield_'+resolution
    vec_default_var = call_function(routine, input_time_range, probe=probe, errmsg=errmsg, _extra=ex)

    ; Convert to the wanted coord.
    if coord ne default_coord then begin
        get_data, vec_default_var, times, vec_default, limits=lim
        vec_coord = cotran(vec_coord, times, default_coord+'2'+coord, probe=probe)
        store_data, vec_coord_var, times, vec_coord, limits=lim
    endif

    add_setting, vec_coord_var, /smart, {$
        display_type: 'vector', $
        unit: 'mV/m', $
        short_name: 'E', $
        coord: strupcase(coord), $
        coord_labels: ['x','y','z'], $
        colors: constant('rgb') }

    return, vec_coord_var

end