;+
;-
function themis_read_ion_vel, input_time_range, probe=probe, id=datatype, $
    resolution=resolution, coord=coord, errmsg=errmsg

    errmsg = ''
    retval = ''

    if ~themis_probe_is_valid(probe) then begin
        errmsg = 'Invalid probe: '+probe+' ...'
        return, retval
    endif
    prefix = 'th'+probe+'_'

    ; Prepare var name.
    default_coord = 'gsm'
    if n_elements(coord) eq 0 then coord = default_coord
    vec_coord_var = prefix+'u_'+coord
    if keyword_set(get_name) then return, vec_coord_var

    ; Load files.
    time_range = time_double(input_time_range)
    if ~check_if_update(vec_coord_var, time_range) then return, vec_coord_var
    files = themis_load_esa(time_range, probe=probe, id='l2', errmsg=errmsg)
    if errmsg ne '' then return, retval

    datatype = (n_elements(datatype) ne 0)? strlowcase(datatype): 'peir'
    case datatype of
        'peir': time_step = 3d       ; Reduced mode.
        'peib': time_step = !null    ; Burst mode.
        'peif': time_step = !null    ; Full
    endcase


;---Read data.
    var_list = list()
    in_vars = prefix+[datatype+'_velocity_'+default_coord]
    out_vars = prefix+['u_'+default_coord]
    var_list.add, dictionary($
        'in_vars', in_vars, $
        'out_vars', out_vars, $
        'time_var_name', prefix+datatype+'_time', $
        'time_var_type', 'unix' )
    read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg
    if errmsg ne '' then return, ''



    var = prefix+'u_gsm'
    get_data, var, times, data
    index = where(data le -1e30, count)
    if count ne 0 then begin
        data[index] = !values.d_nan
        store_data, var, times, data
    endif
    if coord ne 'gsm' then begin
        get_data, var, times, vec
        vec = cotran_pro(vec, times, 'gsm2'+coord, probe=probe)
        var = prefix+'u_'+coord
        store_data, vec_coord_var, times, vec
    endif
    add_setting, vec_coord_var, smart=1, dictionary($
        'requested_time_range', time_range, $
        'display_type', 'vector', $
        'unit', 'km/s', $
        'short_name', 'U!S!Uion!N!R', $
        'coord', strupcase(coord), $
        'coord_labels', constant('xyz') )

    return, vec_coord_var
end

time_range = time_double(['2014-08-28','2014-08-29'])
probe = 'a'
var = themis_read_ion_vel(time_range, probe=probe, id='peib')
end
