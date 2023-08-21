;+
; Read DMSP orbit. Default in gsm.
;-

function dmsp_read_orbit_madrigal, input_time_range, probe=probe, errmsg=errmsg, coord=coord, get_name=get_namem, suffix=suffix, _extra=ex

    prefix = 'dmsp'+probe+'_'
    errmsg = ''
    if n_elements(suffix) eq 0 then suffix = '_madrigal'

    if n_elements(coord) eq 0 then coord = 'gsm'
    var = prefix+'r_'+coord+suffix
    if keyword_set(get_name) then return, var

    time_range = time_double(input_time_range)
    if ~check_if_update(var, time_range) then return, var


;---Read data.
    glat_vars = dmsp_read_glat_vars_madrigal(time_range, probe=probe, errmsg=errmsg)
    if errmsg ne '' then return, retval
    gdlat = get_var_data(glat_vars[0], times=times)
    glon = get_var_data(glat_vars[1])
    gdalt = get_var_data(glat_vars[2])


;---Calibrate the data.
    rad = constant('rad')
    re = constant('re')

    dis = geod2geoc(gdalt, gdlat, glat)/re  ; convert to geocentric latitude and altitude.
    glat = glat*rad
    glon = glon*rad
    
    
    ntime = n_elements(times)
    ndim = 3
    r_geo = fltarr(ntime,ndim)
    r_geo[*,0] = dis*cos(glat)*cos(glon)
    r_geo[*,1] = dis*cos(glat)*sin(glon)
    r_geo[*,2] = dis*sin(glat)
    coord_default = 'geo'
    r_default_var = prefix+'r_'+coord_default+suffix
    store_data, r_default_var, times, r_geo
    add_setting, r_default_var, smart=1, dictionary($
        'requested_time_range', time_range, $
        'display_type', 'vector', $
        'unit', 'Re', $
        'short_name', 'R', $
        'coord', strupcase(coord_default), $
        'coord_labels', constant('xyz') )

    ; Convert to wanted coord.
    if coord ne coord_default then begin
        get_data, r_default_var, times, vec_default, limits=lim
        vec_coord = cotran(vec_default, times, coord_default+'2'+coord)
        store_data, var, times, vec_coord, limits=lim
    endif

    add_setting, var, smart=1, dictionary($
        'requested_time_range', time_range, $
        'display_type', 'vector', $
        'unit', 'Re', $
        'short_name', 'R', $
        'coord', strupcase(coord), $
        'coord_labels', constant('xyz') )


    return, var

end


time_range = ['2013-05-01','2013-05-03']
probe = 'f18'
r1_var = dmsp_read_orbit_cdaweb(time_range, probe=probe, coord='gsm')
r2_var = dmsp_read_orbit_madrigal(time_range, probe=probe, coord='gsm')
end