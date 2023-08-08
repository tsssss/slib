;+
; Read DMSP orbit. Default in gsm.
;-

function dmsp_read_orbit_cdaweb, input_time_range, probe=probe, errmsg=errmsg, coord=coord, get_name=get_name, suffix=suffix, _extra=ex

    prefix = 'dmsp'+probe+'_'
    errmsg = ''
    if n_elements(suffix) eq 0 then suffix = '_cdaweb'

    if n_elements(coord) eq 0 then coord = 'gsm'
    var = prefix+'r_'+coord+suffix
    if keyword_set(get_name) then return, var

    time_range = time_double(input_time_range)
    if ~check_if_update(var, time_range) then return, var

    files = dmsp_load_ssm_cdaweb(time_range, probe=probe, id='l2', errmsg=errmsg)
    if errmsg ne '' then return, retval

;---Read data.
    var_list = list()
    in_vars = 'SC_GEOCENTRIC_'+['LAT','LON','R']
    out_vars = prefix+['glat','glon','dis']
    var_list.add, dictionary($
        'in_vars', in_vars, $
        'out_vars', out_vars, $
        'time_var_name', 'Epoch', $
        'time_var_type', 'epoch' )
    read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg
    if errmsg ne '' then return, ''

;---Calibrate the data.
    rad = constant('rad')
    re = constant('re')
    glat = get_var_data(out_vars[0], times=times)*rad
    glon = get_var_data(out_vars[1])*rad
    dis = get_var_data(out_vars[2])/re
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


time_range = ['2013-05-01','2013-05-01/12:00']
probe = 'f18'
r_var = dmsp_read_orbit_cdaweb(time_range, probe=probe, coord='gsm')
vars = stplot_calc_mlat_vars(r_var)
igrf = 1
vinfo = geopack_trace_to_ionosphere(r_var, models='t89', igrf=igrf, south=1, refine=1, suffix='_south')
vinfo = geopack_trace_to_ionosphere(r_var, models='t89', igrf=igrf, north=1, refine=1, suffix='_north')

end