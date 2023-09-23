;+
; Read flags for data availability.
;
; input_time_range. Input time in string or unix time.
; site=. Required input, a string for site.
;-

function themis_asf_read_flag_avail, input_time_range, site=site, errmsg=errmsg, get_name=get_name

    retval = !null
    errmsg = ''

    time_range = time_double(input_time_range)
    
    asf_var = themis_read_asf(time_range, site=site, get_name=1, errmsg=errmsg)
    if errmsg ne '' then return, retval
    flag_var = asf_var+'_flag_avail'
    

    files = themis_asf_load_flag_avail(time_range, site=site, errmsg=errmsg)
    if errmsg ne '' then return, retval
    if keyword_set(get_name) then return, retval

    var_list = list()

    var_list.add, dictionary($
        'in_vars', flag_var, $
        'time_var_name', 'time', $
        'time_var_type', 'unix' )
    read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg
    if errmsg ne '' then return, retval

    add_setting, flag_var, smart=1, dictionary($
        'display_type', 'scalar', $
        'short_name', 'Avail', $
        'unit', '#', $
        'ystyle', 1, $
        'yrange', [-0.1,1.1] )
    return, flag_var

end

time_range = ['2015-01-01','2015-01-03']
site = 'rank'
flag_var = themis_asf_read_flag_avail(time_range, site=site)
end