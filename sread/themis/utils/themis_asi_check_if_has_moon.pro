function themis_asi_check_if_has_moon, input_time_range, site=site, errmsg=errmsg, min_elev=min_elev

    time_range = time_double(input_time_range)
    var_info = themis_asi_read_moon_pos(time_range, site=site, get_name=1)
    elev_var = var_info['moon_elev']
    if check_if_update(elev_var, time_range) then var_info = themis_asi_read_moon_pos(time_range, site=site)
    
    moon_elevs = get_var_data(elev_var)
    if n_elements(min_elev) eq 0 then min_elev = 5
    index = where(moon_elevs ge min_elev, count)
    if count eq 0 then return, 0 else return, 1

end


; examples of cloud data.
site = 'mcgr'
time_range = ['2015-03-11/09:00','2015-03-11/13:00']
tmp = themis_asi_read_moon_pos(time_range, site=site)
end