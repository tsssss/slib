;+
; Read RBSP E field.
;
; input_time_range.
; probe=. 'a', 'b'.
; resolution=. 'hires', 'survey', 'burst','spinfit','spinfit_phasef'.
; coord=. 'gsm','ges','gei','sm'
;-

function rbsp_read_efield, input_time_range, probe=probe, $
resolution=resolution, errmsg=errmsg, coord=coord, get_name=get_name, suffix=suffix, _extra=ex

    prefix = 'rbsp'+probe+'_'
    errmsg = ''
    retval = ''

    default_coord = 'rbsp_mgse'
    if n_elements(coord) eq 0 then coord = default_coord
    if n_elements(resolution) eq 0 then resolution = 'survey'
    resolutions = ['spinfit','survey','burst','spinfit_phasef']
    index = where(resolutions eq resolution, count)
    if count eq 0 then begin
        errmsg = 'Invalid resolution: '+resolution+' ...'
        return, retval
    endif

    if n_elements(suffix) eq 0 then suffix = ''
    vec_coord_var = prefix+'e_'+coord+suffix
    if keyword_set(get_name) then begin
        return, vec_coord_var
    endif

    routine = 'rbsp_read_efield_'+resolution
    vec_default_var = call_function(routine, input_time_range, probe=probe, errmsg=errmsg, suffix=suffix, _extra=ex)

    ; Convert to the wanted coord.
    if coord ne default_coord then begin
        get_data, vec_default_var, times, vec_default, limits=lim
        vec_coord = cotran_pro(vec_coord, times, default_coord+'2'+coord, probe=probe)
        store_data, vec_coord_var, times, vec_coord, limits=lim
    endif

    add_setting, vec_coord_var, /smart, dictionary($
        'display_type', 'vector', $
        'unit', 'mV/m', $
        'short_name', 'E', $
        'probe', probe, $
        'spin_axis', 'x', $
        'coord', strlowcase(coord), $
        'coord_labels', constant('xyz') )

    return, vec_coord_var

end