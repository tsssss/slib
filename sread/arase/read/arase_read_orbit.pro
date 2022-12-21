;+
; Read Arase orbit. Save as 'arase_r_<coord>', Default <coord> is gsm.
;
; input_time_range. Unix time or string for time range.
;-

function arase_read_orbit, input_time_range, probe=probe, $
    errmsg=errmsg, coord=coord, get_name=get_name, resolution=resolution, _extra=ex

    prefix = 'arase_'
    errmsg = ''
    retval = ''

    if n_elements(coord) eq 0 then coord = 'gsm'
    var = prefix+'r_'+coord
    if keyword_set(get_name) then return, var

    time_range = time_double(input_time_range)
    files = arase_load_ssc(time_range, errmsg=errmsg, id='l2%def')
    if errmsg ne '' then return, retval


    var_list = list()
    orig_var = prefix+'r_gsm'
    var_list.add, dictionary($
        'in_vars', ['pos_'+coord], $
        'out_vars', [orig_var], $
        'time_var_name', 'epoch', $
        'time_var_type', 'tt2000')
    read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg
    if errmsg ne '' then return, retval

    if coord ne 'gsm' then begin
        get_data, orig_var, times, r_gsm, limits=lim
        r_coord = cotran(r_gsm, times, 'gsm2'+coord)
        store_data, var, times, r_coord, limits=lim
    endif

    add_setting, var, smart=1, dictionary($
        'display_type', 'vector', $
        'short_name', 'R', $
        'unit', 'Re', $
        'coord', strupcase(coord), $
        'coord_labels', constant('xyz') )
    
    return, var

end


time_range = ['2017-01-01','2017-01-02']
var = arase_read_orbit(time_range)
end
