;+
; Read MMS orbit. Save as 'mms_r_<coord>'. Default <coord> is gsm.
;
; input_time_range. Unix time or string for time range.
; probe=. A string for probe. '1','2','3','4'.
;-

function mms_read_orbit_cdaweb, input_time_range, probe=probe, $
    var_info=var_info, $
    errmsg=errmsg, coord=coord, get_name=get_name, resolution=resolution, suffix=suffix, _extra=ex


    prefix = 'mms'+probe+'_'
    errmsg = ''
    retval = ''

    if n_elements(coord) eq 0 then coord = 'gsm'
    if n_elements(suffix) eq 0 then suffix = '_cdaweb'
    if n_elements(var_info) eq 0 then var_info = prefix+'r_'+coord
    if keyword_set(get_name) then return, var_info

    time_range = time_double(input_time_range)
    files = mms_ld_mec(time_range, probe=probe, errmsg=errmsg, id='l2%survey')
    ;if errmsg ne '' then return, retval


    var_list = list()
    orig_var = prefix+'r_gsm'
    var_list.add, dictionary($
        'in_vars', [prefix+'mec_r_gsm'], $
        'out_vars', [orig_var], $
        'time_var_name', 'Epoch', $
        'time_var_type', 'tt2000')
    read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg
    if errmsg ne '' then return, retval
    
    ; Convert to Re and remove |B|.
    get_data, orig_var, times, r_coord
    r_coord = r_coord[*,0:2]*(1d/constant('re'))
    ; Remove invalid data.
    index = where(snorm(r_coord) ge 1e4, count)
    if count ne 0 then r_coord[index,*] = !values.f_nan

    if coord ne 'gsm' then begin
        get_data, orig_var, times, r_gsm, limits=lim
        r_coord = cotran_pro(r_gsm, times, coord_msg=['gsm',coord])
        store_data, var_info, times, r_coord, limits=lim
    endif else begin
        store_data, var_info, times, r_coord
    endelse

    add_setting, var_info, smart=1, {$
        requested_time_range: time_range, $
        probe: probe, $
        mission: 'mms', $
        mission_probe: 'mms'+probe, $
        display_type: 'vector', $
        unit: 'Re', $
        short_name: 'R', $
        coord: strlowcase(coord), $
        coord_labels: constant('xyz')}

    return, var_info

end



time_range = time_double(['2016-10-13','2016-10-14'])
probe = '1'
ids = 'cdaweb'
var = mms_read_orbit(time_range, probe=probe, ids=ids)
end