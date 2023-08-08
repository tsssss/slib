;+
; Read spinfit E field.
;-

function rbsp_read_efield_spinfit, input_time_range, probe=probe, get_name=get_name, coord=coord, _extra=ex

    prefix = 'rbsp'+probe+'_'
    errmsg = ''
    retval = ''

    if n_elements(coord) eq 0 then coord = 'mgse'
    vec_coord_var = prefix+'e_'+coord
    if keyword_set(get_name) then return, vec_coord_var
    
    time_range = time_double(input_time_range)
    if ~check_if_update(vec_coord_var, time_range) then return, vec_coord_var

    files = rbsp_load_efw(time_range, probe=probe, id='l3%efw', errmsg=errmsg)
    if errmsg ne '' then return, retval
    
    var_list = list()
    default_coord = 'mgse'
    vec_default_var = prefix+'e_'+default_coord
    var_list.add, dictionary($
        'in_vars', 'efield_in_corotation_frame_spinfit_edotb_mgse', $
        'out_vars', [vec_default_var], $
        'time_var_name', 'epoch', $
        'time_var_type', 'epoch16')
    
    read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg
    if errmsg ne '' then return, retval


    if coord ne default_coord then begin
        get_data, vec_default_var, times, vec_default, limits=lim
        msg = default_coord+'2'+coord
        vec_coord = cotran(vec_default, times, msg, probe=probe)
        store_data, vec_coord_var, times, vec_coord, limits=lim
    endif

    add_setting, vec_coord_var, smart=1, {$
        display_type: 'vector', $
        unit: 'mV/m', $
        short_name: 'E', $
        coord: strupcase(coord), $
        coord_labels: ['x','y','z'], $
        colors: constant('rgb') }

    return, vec_coord_var

end

time_range = time_double(['2013-05-01/07:20','2013-05-01/07:50'])         ; a longer time range for test purpose.
probe = 'b'
var = rbsp_read_efield_spinfit(time_range, probe=probe, coord='gsm')
end