;+
; Read Moon's elevation and azimth angles for a given site and time range.
; Save as thg_site_moon_[elev,azim].
;
; input_time_range.
; site=.
; get_name=.
; errmsg=.
;-

function themis_asi_read_moon_pos, input_time_range, site=site, errmsg=errmsg, get_name=get_name

    errmsg = ''

    elev_var = 'thg_'+site+'_moon_elev'
    azim_var = 'thg_'+site+'_moon_azim'
    var_info = dictionary($
        'moon_elev', elev_var, $
        'moon_azim', azim_var)
    if keyword_set(get_name) then return, var_info
    
    
    site_info = themis_asi_read_site_info(site)
    glat = site_info['asc_glat']
    glon = site_info['asc_glon']


    time_range = time_double(input_time_range)
    time_step = 3d
    common_times = make_bins(time_range+[0,-0.1*time_step], time_step, inner=1)
    ntime = n_elements(common_times)
    moon_elevs = moon_elev(common_times, glon, glat, degree=1, azim=moon_azims)

    store_data, elev_var, common_times, moon_elevs
    add_setting, elev_var, smart=1, dictionary($
        'short_name', 'Moon elev', $
        'unit', 'deg', $
        'display_type', 'scalar' )
    store_data, azim_var, common_times, moon_azims
    add_setting, azim_var, smart=1, dictionary($
        'short_name', 'Moon azim', $
        'unit', 'deg', $
        'display_type', 'scalar' )
    
    return, var_info
    
;    if n_elements(min_elev) eq 0 then min_elev = 0
;    index = where(moon_elevs ge min_elev, count)
;    if count eq 0 then return, []
;    return, common_times[time_to_range(index,time_step=1)]

end


; examples of cloud data.
site = 'mcgr'
time_range = ['2015-03-11/09:00','2015-03-11/13:00']
tmp = themis_asi_read_moon_pos(time_range, site=site)
end