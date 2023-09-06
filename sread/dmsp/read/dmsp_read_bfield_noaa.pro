;+
; Read DMSP B/dB field.
;-

function dmsp_read_bfield_noaa, input_time_range, probe=probe, errmsg=errmsg, $
    get_name=get_name, suffix=suffix, coord=coord, _extra=ex

    prefix = 'dmsp'+probe+'_'
    errmsg = ''
    retval = ''

    if n_elements(suffix) eq 0 then suffix = '_noaa'
    if n_elements(coord) eq 0 then coord = 'xyz'
    b_coord_var = prefix+'db_'+coord
    if keyword_set(get_name) then return, b_coord_var

    time_range = time_double(input_time_range)
    if ~check_if_update(b_coord_var, time_range) then return, b_coord_var

    files = dmsp_load_ssm_noaa(time_range, probe=probe, errmsg=errmsg)
    if errmsg ne '' then return, retval


;---Read data.
    var_list = list()
    ; also b_xyz
    in_vars = prefix+['db_xyz']
    out_vars = b_coord_var
    var_list.add, dictionary($
        'in_vars', in_vars, $
        'out_vars', out_vars, $
        'time_var_name', 'ut', $
        'time_var_type', 'unix' )
    read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg
    if errmsg ne '' then return, ''
    

    add_setting, b_coord_var, smart=1, dictionary($
        'requested_time_range', time_range, $
        'display_type', 'vector', $
        'unit', 'nT', $
        'short_name', 'dB', $
        'coord', 'XYZ' )

    return, b_coord_var

end

time_range = ['2013-05-01','2013-05-02']
probe = 'f18'
time_range = ['2015-03-12','2015-03-13']
probe = 'f19'
b_var = dmsp_read_bfield_noaa(time_range, probe=probe)
end