;+
; Read MMS orbit. Save as 'mms_r_<coord>'. Default <coord> is gsm.
;
; input_time_range. Unix time or string for time range.
; probe=. A string for probe. '1','2','3','4'.
;-

function mms_read_orbit, input_time_range, probe=probe, $
    errmsg=errmsg, coord=coord, get_name=get_name, resolution=resolution, _extra=ex


    prefix = 'mms'+probe+'_'
    errmsg = ''
    retval = ''

    if n_elements(coord) eq 0 then coord = 'gsm'
    var = prefix+'r_'+coord
    if keyword_set(get_name) then return, var

    time_range = time_double(input_time_range)
    files = mms_load_fgm(time_range, probe=probe, errmsg=errmsg, id='l2%survey')
    if errmsg ne '' then return, retval


    var_list = list()
    orig_var = prefix+'r_gsm'
    var_list.add, dictionary($
        'in_vars', [prefix+'fgm_r_gsm_srvy_l2'], $
        'out_vars', [orig_var], $
        'time_var_name', 'Epoch_state', $
        'time_var_type', 'tt2000')
    read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg
    if errmsg ne '' then return, retval
    
    ; Convert to Re and remove |B|.
    get_data, orig_var, times, r_coord
    r_coord = r_coord[*,0:2]*(1d/constant('re'))
    store_data, orig_var, times, r_coord

    if coord ne 'gsm' then begin
        get_data, orig_var, times, r_gsm, limits=lim
        r_coord = cotran(r_gsm, times, 'gsm2'+coord)
        store_data, var, times, r_coord, limits=lim
    endif

    add_setting, var, smart=1, {$
        display_type: 'vector', $
        unit: 'Re', $
        short_name: 'R', $
        coord: strupcase(coord), $
        coord_labels: constant('xyz')}

    return, var

end



time_range = time_double(['2016-10-13','2016-10-14'])
probe = '1'
var = mms_read_orbit(time_range, probe=probe)
end