;+
; Read RBSP orbit. Save as 'rbspx_r_<coord>'. Default <coord> is gsm.
;
; input_time_range. Unix time or string for time range.
; probe=. A string for probe. 'a','b'.
;-

function rbsp_read_orbit, input_time_range, probe=probe, $
    errmsg=errmsg, coord=coord, get_name=get_name, resolution=resolution, _extra=ex

    prefix = 'rbsp'+probe+'_'
    errmsg = ''
    retval = ''

    if n_elements(coord) eq 0 then coord = 'gsm'
    var = prefix+'r_'+coord
    if keyword_set(get_name) then return, var
    time_range = time_double(input_time_range)
    if ~check_if_update(var, time_range) then return, var
    
    if n_elements(resolution) eq 0 then resolution = 60d
    if resolution eq 60 or resolution eq 5*60d then begin
        return, ml_rbsp_read_pos(time_range, probe=probe, coord=coord, errmsg=errmsg, resolution=resolution)
    endif

    files = rbsp_load_spice(time_range, probe=probe, errmsg=errmsg)
    if errmsg ne '' then return, retval

    var_list = list()

    orig_var = prefix+'r_gse'
    var_list.add, dictionary($
        'in_vars', orig_var, $
        'out_vars', orig_var, $
        'time_var_name', 'Epoch', $
        'time_var_type', 'epoch' )
    read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg
    if errmsg ne '' then return, retval

    if coord ne 'gse' then begin
        get_data, prefix+'r_gse', times, r_gse, limits=lim
        r_coord = cotran(r_gse, times, 'gse2'+coord)
        store_data, var, times, r_coord, limits=lim
    endif

    add_setting, var, smart=1, {$
        requested_time_range: time_range, $
        mission_probe: 'rbsp'+probe, $
        display_type: 'vector', $
        unit: 'Re', $
        short_name: 'R', $
        coord: strupcase(coord), $
        coord_labels: constant('xyz')}

    return, var

end

time_range = ['2013-06-07','2013-06-08']
probe = 'a'
var = rbsp_read_orbit(time_range, probe=probe)
end