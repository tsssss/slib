;+
; Calc mlat from r_var
;-

function stplot_calc_mlat_vars, r_var, _extra=ex

    get_data, r_var, times, r_vec, limits=lim
    coord = strlowcase(lim.coord)
    if coord ne 'mag' then begin
        r_vec = cotran(r_vec, times, coord+'2mag', _extra=ex)
    endif

    deg = constant('deg')
    mlat = asin(r_vec[*,2]/snorm(r_vec))*deg
    mlon = atan(r_vec[*,1],r_vec[*,0])*deg
    mlt = mlon2mlt(mlon, times)

    prefix = get_prefix(r_var)
    var = prefix+'mlat'
    store_data, var, times, mlat
    add_setting, var, smart=1, dictionary($
        'display_type', 'scalar', $
        'short_name', 'MLat', $
        'unit', 'deg' )
    var = prefix+'mlon'
    store_data, var, times, mlon
    add_setting, var, smart=1, dictionary($
        'display_type', 'scalar', $
        'short_name', 'MLon', $
        'unit', 'deg' )
    var = prefix+'mlt'
    store_data, var, times, mlt
    add_setting, var, smart=1, dictionary($
        'display_type', 'scalar', $
        'short_name', 'MLT', $
        'unit', 'h' )

    return, prefix+['mlat','mlon','mlt']
end