;+
; Read G parameters.
; 
; G1, G2, and G3 are calculated as one-hour trailing averages following
; Qin et al. [2007], as implemented in EL_PASO load_indices_solar_wind_parameters.py.
; Qin, Z., R. E. Denton, N. A. Tsyganenko, and S. Wolf (2007), Solar wind parameters for magnetospheric magnetic field modeling, Space Weather, 5, S11003, doi:10.1029/2006SW000296.
;-

function geopack_read_g, input_time_range, get_name=get_name, update=update, errmsg=errmsg, _extra=extra
    compile_opt idl2

    errmsg = ''
    retval = !null

    var_info = 'geopack_g'
    if keyword_set(get_name) then return, var_info
    if keyword_set(update) then tmp = delete_var_from_memory(var_info)

    time_range = time_double(input_time_range)
    if ~check_if_update(var_info, time_range) then return, var_info

;---G parameters.
    history_window = 3600d    ; 1 hour.
    data_tr = time_range+[-history_window,0]
    coord = 'gsm'
    sw_n_var = omni_read_sw_n(data_tr, errmsg=errmsg)
    sw_b_var = omni_read_sw_b(data_tr, coord=coord, errmsg=errmsg)
    sw_v_var = omni_read_sw_v(data_tr, coord=coord, errmsg=errmsg)

    times = var_get_time(sw_n_var)
    time_step = sdatarate(times)
    common_times = make_bins(minmax(times), time_step, inner=1)
    time_index = where_pro(common_times, '[]', time_range, count=ntime)
    if ntime le 0 then begin
        errmsg = 'No data in the specified time range.'
        return, retval
    endif
    times = common_times[time_index]
    foreach var, [sw_n_var, sw_b_var, sw_v_var] do begin
        interp_time, var, common_times
    endforeach

    sw_n = var_get_data(sw_n_var) > 0
    b_vec = var_get_data(sw_b_var)
    v_vec = var_get_data(sw_v_var)
    sw_speed = snorm(v_vec)

    imf_by = b_vec[*,1]
    imf_bz = b_vec[*,2]
    b_perp = sqrt(imf_by^2+imf_bz^2)
    theta = atan(imf_by, imf_bz)
    bp_norm = b_perp/40.0
    b_south = ((-imf_bz)>0)

    ng = 3
    integrands = fltarr(n_elements(common_times),ng)
    ; G1.
    integrands[*,0] = sw_speed * bp_norm^2 / (1+bp_norm) * sin(theta*0.5)^3
    ; G2.
    integrands[*,1] = sw_speed * b_south / 200.0
    ; G3.
    integrands[*,2] = sw_n * sw_speed * b_south / 2000.0

    history_shift = round(history_window/time_step)
    g_params = fltarr(ntime,ng)
    for tid=0,ntime-1 do begin
        i1 = time_index[tid]
        i0 = (i1-history_shift)>0
        for gg=0,ng-1 do begin
            sub_data = integrands[i0:i1,gg]
            good_index = where(finite(sub_data), count)
            if count gt 0 then g_params[tid,gg] = mean(sub_data[good_index], /nan) else g_params[tid,gg] = !values.f_nan
        endfor
    endfor

    settings = dictionary($
        'requested_time_range', time_range, $
        'display_type', 'stack', $
        'labels', 'G'+string(findgen(ng)+1,format='(I0)'), $
        'colors', get_color(ng), $
        'ytitle', 'G Param' )
    var_info = var_store(var_info, g_params, times, settings=settings)

    return, var_info

end

