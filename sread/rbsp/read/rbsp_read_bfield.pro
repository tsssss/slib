;+
; Read RBSP DC B field. Default is to read '4sec' data.
; Save as rbspx_b_gsm.
; 
; input_time_range.
; probe=. 'a', 'b'.
; resolution=. 'hires', '1sec', '4sec'.
; coord=. 'gsm','ges','gei','sm'
;-

function rbsp_read_bfield, input_time_range, probe=probe, $
resolution=resolution, errmsg=errmsg, coord=coord, get_name=get_name, _extra=ex

    prefix = 'rbsp'+probe+'_'
    errmsg = ''
    retval = ''

    default_coord = 'gsm'
    if n_elements(coord) eq 0 then coord = default_coord
    vec_coord_var = prefix+'b_'+coord
    if keyword_set(get_name) then return, vec_coord_var

    resolution = (keyword_set(resolution))? strlowcase(resolution): '4sec'
    case resolution of
        'hires': time_step = 1d/64
        '1sec': time_step = 1d
        '4sec': time_step = 4d
    endcase

    ; read 'rbspx_b_gsm'
    time_range = time_double(input_time_range)
    files = rbsp_load_emfisis(time_range, probe=probe, $
        id='l3%magnetometer', $
        resolution=resolution, coord=default_coord, errmsg=errmsg)
    if errmsg ne '' then return, retval

    var_list = list()

    vec_default_var = prefix+'b_'+default_coord
    var_list.add, dictionary($
        'in_vars', ['Mag'], $
        'out_vars', [vec_default_var], $
        'time_var_name', 'Epoch', $
        'time_var_type', 'tt2000')
    read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg
    if errmsg ne '' then return, retval

    ; Remove invalid values.
    get_data, vec_default_var, times, vec_default
    index = where(abs(vec_default) ge 65536, count)
    if count ne 0 then begin
        vec_default[index,*] = !values.f_nan
        store_data, vec_default_var, times, vec_default
    endif
    

    ; Fix time tags.
    uniform_time, vec_default_var, time_step
    dtime = time_step*0.5
    get_data, vec_default_var, times, vec_default
    store_data, vec_default_var, times+dtime, vec_default

    ; Convert to the wanted coord.
    if coord ne default_coord then begin
        get_data, vec_default_var, times, vec_default, limits=lim
        vec_coord = cotran(vec_default, times, default_coord+'2'+coord, probe=probe)
        store_data, vec_coord_var, times, vec_coord, limits=lim
    endif

    add_setting, vec_coord_var, smart=1, {$
        display_type: 'vector', $
        unit: 'nT', $
        short_name: 'B', $
        coord: strupcase(coord), $
        coord_labels: ['x','y','z'], $
        colors: constant('rgb') }

    return, vec_coord_var

end

;time_range = time_double(['2013-06-10/05:57:20','2013-06-10/05:59:40'])   ; a shorter time range for test purpose.
time_range = time_double(['2013-06-07/04:40','2013-06-07/05:10'])         ; a longer time range for test purpose.
time_range = time_double(['2013-05-01/07:20','2013-05-01/07:50'])         ; a longer time range for test purpose.
;time_range = time_double(['2015-09-15','2015-09-16'])         ; a day with data gap.
var = rbsp_read_bfield(time_range, probe='b')
end