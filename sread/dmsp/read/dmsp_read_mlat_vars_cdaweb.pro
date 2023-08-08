;+
; Read DMSP orbit, aagcm mlat, mlon, mlt.
;-

function dmsp_read_mlat_vars_cdaweb, input_time_range, probe=probe, errmsg=errmsg, coord=coord, get_name=get_name, suffix=suffix, _extra=ex

    prefix = 'dmsp'+probe+'_'
    errmsg = ''

    if n_elements(suffix) eq 0 then suffix = '_cdaweb'
    vars = prefix+['mlat','mlt','mlon']+suffix
    if keyword_set(get_name) then return, vars

    time_range = time_double(input_time_range)
    if ~check_if_update(vars[0], time_range) then return, vars

    files = dmsp_load_ssm_cdaweb(time_range, probe=probe, id='l2')
    if errmsg ne '' then return, retval

;---Read data.
    var_list = list()
    in_vars = 'SC_AACGM_'+['LAT','LTIME','LON']
    out_vars = vars
    var_list.add, dictionary($
        'in_vars', in_vars, $
        'out_vars', out_vars, $
        'time_var_name', 'Epoch', $
        'time_var_type', 'epoch' )
    read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg
    if errmsg ne '' then return, ''

;---Calibrate the data.
    var = vars[0]
    add_setting, var, smart=1, dictionary($
        'requested_time_range', time_range, $
        'display_type', 'scalar', $
        'unit', 'deg', $
        'short_name', 'MLat' )
    
    var = vars[1]
    add_setting, var, smart=1, dictionary($
        'requested_time_range', time_range, $
        'display_type', 'scalar', $
        'unit', 'h', $
        'short_name', 'MLT' )

    var = vars[2]
    add_setting, var, smart=1, dictionary($
        'requested_time_range', time_range, $
        'display_type', 'scalar', $
        'unit', 'deg', $
        'short_name', 'MLon' )

    return, vars

end


time_range = ['2013-05-01','2013-05-01/12:00']
probe = 'f18'
r_vars = dmsp_read_mlat_vars_cdaweb(time_range, probe=probe)

r_var = dmsp_read_orbit(time_range, probe=probe)
vars = stplot_calc_mlat_vars(r_var)

end