;+
; Read GOES Lshell.
;-

function goes_read_lshell, input_time_range, probe=probe, errmsg=errmsg, get_name=get_name

    prefix = 'g'+probe+'_'
    errmsg = ''
    var = prefix+'lshell'
    if keyword_set(get_name) then return, var
    time_range = time_double(input_time_range)
    if ~check_if_update(var, time_range) then return, var

;---Read data.
    r_var = goes_read_orbit(time_range, probe=probe, coord='sm')
    r_sm = get_var_data(r_var, times=times)
    dis = snorm(r_sm)
    mlat = asin(r_sm[*,2]/dis)
    lshell = dis/cos(mlat)^2
    store_data, var, times, lshell
    
    add_setting, var, smart=1, dictionary($
        'requested_time_range', time_range, $
        'display_type', 'scalar', $
        'unit', '#', $
        'short_name', 'L' )

    return, var

end


time_range = ['2008-01-19','2008-01-20']
probe = 'a'
var = goes_read_lshell(time_range, probe=probe)
end