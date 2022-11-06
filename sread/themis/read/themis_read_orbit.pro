;+
; Read Themis position. Default in gsm.
;-

function themis_read_orbit, input_time_range, probe=probe, errmsg=errmsg, coord=coord, get_name=get_name, _extra=ex

    prefix = 'th'+probe+'_'
    errmsg = ''

    if n_elements(coord) eq 0 then coord = 'gsm'
    var = prefix+'r_'+coord
    if keyword_set(get_name) then return, var

    time_range = time_double(input_time_range)
    files = themis_load_ssc(time_range, probe=probe, id='l2')

;---Read data.
    var_list = list()
    in_vars = 'XYZ_GSM'
    out_vars = prefix+'r_gsm'
    var_list.add, dictionary($
        'in_vars', in_vars, $
        'out_vars', out_vars, $
        'time_var_name', 'Epoch', $
        'time_var_type', 'epoch' )
    read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg
    if errmsg ne '' then return, ''

;---Calibrate the data.
    ; Convert to wanted coord.
    if coord ne 'gsm' then begin
        get_data, prefix+'r_gsm', times, vec_gsm, limits=lim
        vec_coord = cotran(vec_gsm, times, 'gsm2'+coord)
        store_data, var, times, vec_coord, limits=lim
    endif

    add_setting, var, smart=1, {$
        display_type: 'vector', $
        unit: 'Re', $
        short_name: 'R', $
        coord: strupcase(coord), $
        coord_labels: constant('xyz') }


;    dt = 60.0

    return, var

end


time_range = ['2008-01-19','2008-01-20']
probe = 'a'
var = themis_read_orbit(time_range, probe=probe)
end