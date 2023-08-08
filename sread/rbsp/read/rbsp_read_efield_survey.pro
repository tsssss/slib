;+
; Read RBSP EFW E field in mGSE in survey resolution (32).
; Load L2 E UVW and convert to mGSE.
; Do not use L2 E despun b/c cotran does a slightly more accurate job to convert UVW to mGSE.
;-

function rbsp_read_efield_survey, input_time_range, probe=probe, get_name=get_name, _extra=ex

    prefix = 'rbsp'+probe+'_'
    errmsg = ''
    retval = ''

    coord = 'mgse'
    vec_coord_var = prefix+'e_'+coord
    if keyword_set(get_name) then return, vec_coord_var

;    time_range = time_double(input_time_range)
;    files = rbsp_load_efw(time_range, probe=probe, $
;        id='l2%uvw', errmsg=errmsg)
;    if errmsg ne '' then return, retval
;
;    var_list = list()
;
;    default_coord = 'uvw'
;    vec_default_var = prefix+'e_'+default_coord
;    var_list.add, dictionary($
;        'in_vars', ['e_hires_uvw'], $
;        'out_vars', [vec_default_var], $
;        'time_var_name', 'epoch', $
;        'time_var_type', 'epoch16')
;    
;    read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg
;    if errmsg ne '' then return, retval

    default_coord = 'uvw'
    vec_default_var = prefix+'e_uvw'
    time_range = time_double(input_time_range)
    rbsp_efw_phasef_read_e_uvw, time_range, probe=probe

    get_data, vec_default_var, times, vec_default
    index = where(abs(vec_default) ge 1e30, count)
    if count ne 0 then begin
        vec_default[index] = !values.f_nan
        store_data, vec_default_var, times, vec_default
    endif
    add_setting, vec_default_var, /smart, {$
        display_type: 'vector', $
        unit: 'mV/m', $
        short_name: 'E', $
        coord: strupcase(default_coord), $
        coord_labels: ['u','v','w'], $
        colors: constant('rgb') }
        
    msg = default_coord+'2'+coord
    vec_coord = cotran(vec_default, times, msg, probe=probe, _extra=ex)

    e_spinaxis = vec_coord[*,0]
    vec_coord[*,0] = 0
    store_data, vec_coord_var, times, vec_coord, e_spinaxis

    add_setting, vec_coord_var, /smart, {$
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
var = rbsp_read_efield_survey(time_range, probe=probe)
end