;+
; Read DMSP orbit, glat, glon, alt.
; glat and alt are geocentric by default, not geodetic.
; geodetic=. Set to return geodetic glat/glon/alt.
;-

function dmsp_read_glat_vars_noaa, input_time_range, probe=probe, errmsg=errmsg, get_name=get_name, suffix=suffix, geodetic=geodetic, _extra=ex

    prefix = 'dmsp'+probe+'_'
    errmsg = ''
    retval = ''

    if n_elements(suffix) eq 0 then suffix = '_noaa'
    vars = prefix+['glat','glon','alt']+suffix
    if keyword_set(get_name) then return, var

    time_range = time_double(input_time_range)
    if ~check_if_update(var, time_range) then return, var

    files = dmsp_load_ssm_noaa(time_range, probe=probe, id='l2', errmsg=errmsg)
    if errmsg ne '' then return, retval


;---Read data.
    var_list = list()
    in_vars = prefix+['glat','glon','alt']
    out_vars = vars
    var_list.add, dictionary($
        'in_vars', in_vars, $
        'out_vars', out_vars, $
        'time_var_name', 'ut', $
        'time_var_type', 'unix' )
    read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg
    if errmsg ne '' then return, ''

;---Calibrate the data.
    get_data, vars[0], times, gdlat
    get_data, vars[2], times, gdalt
    re = constant('re')
    if keyword_set(geodetic) then begin
        alt = gdalt
        glat = gdlat
    endif else begin
        alt = geod2geoc(gdalt, gdlat, glat)-re  ; convert to geocentric latitude and altitude.
    endelse


    var = vars[0]
    store_data, var, times, glat
    add_setting, var, smart=1, dictionary($
        'requested_time_range', time_range, $
        'display_type', 'scalar', $
        'unit', 'deg', $
        'short_name', 'GLat' )

    var = vars[1]
    get_data, var, times, glon
    index = where(glon ge 180, count)
    if count ne 0 then begin
        glon[index] -= 360
        store_data, var, times, glon
    endif
    add_setting, var, smart=1, dictionary($
        'requested_time_range', time_range, $
        'display_type', 'scalar', $
        'unit', 'deg', $
        'short_name', 'GLon' )
    
    var = vars[2]
    store_data, var, times, alt
    add_setting, var, smart=1, dictionary($
        'requested_time_range', time_range, $
        'display_type', 'scalar', $
        'unit', 'km', $
        'short_name', 'Altitude' )

    return, vars

end


time_range = ['2013-05-01','2013-05-01/12:00']
probe = 'f18'
r_var = dmsp_read_glat_vars_noaa(time_range, probe=probe)

end
