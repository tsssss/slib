;+
; Read W parameters.
; 
; Qin, Z., R. E. Denton, N. A. Tsyganenko, and S. Wolf (2007), Solar wind parameters for magnetospheric magnetic field modeling, Space Weather, 5, S11003, doi:10.1029/2006SW000296.
;-

function geopack_read_w, input_time_range, get_name=get_name, update=update, errmsg=errmsg, _extra=extra
    compile_opt idl2
    test = 0
  
    errmsg = ''
    retval = !null

    var_info = 'geopack_w'
    if keyword_set(get_name) then return, var_info
    if keyword_set(update) then tmp = delete_var_from_memory(var_info)

    time_range = time_double(input_time_range)
    if ~check_if_update(var_info, time_range) then return, var_info

;---W parameters.
    w_lambda = [0.394732, 0.550920, 0.387365, 0.436819, 0.405553, 1.26131]
    w_beta   = [0.846509, 0.180725, 2.26596,  1.28211,  1.62290,  2.42297]
    w_gamma  = [0.916555, 0.898772, 1.29123,  1.33199,  0.699074, 0.537116]
    w_r      = [0.383403, 0.648176, 0.318752e-01, 0.581168, 1.15070, 0.843004]

    w_he_factor    = 1.16    ; he++ abundance correction applied to proton density

    history_window = 14*86400d    ; 14 days.
    data_tr = time_range+[-history_window,0]
    sw_n_var = omni_read_sw_n(data_tr)
    sw_b_var = omni_read_sw_b(data_tr, coord=coord)
    sw_v_var = omni_read_sw_v(data_tr, coord=coord)

    times = var_get_time(sw_n_var)
    time_step = sdatarate(times)
    common_times = make_bins(minmax(times), time_step, inner=1)
    foreach var, [sw_n_var, sw_b_var, sw_v_var] do begin
        interp_time, var, common_times
    endforeach

    sw_n = var_get_data(sw_n_var)
    b_vec = var_get_data(sw_b_var)
    v_vec = var_get_data(sw_v_var)
    sw_speed = snorm(v_vec)

    n_normed = sw_n*w_he_factor / 5
    v_normed = sw_speed/400.0
    bs_normed = ((-b_vec[*,2])>0) / 5

    nw_param = n_elements(w_lambda)
    time_index = where_pro(common_times, '[]', time_range, count=ntime)
    if ntime le 0 then begin
        errmsg = 'No data in the specified time range.'
        return, retval
    endif
    times = common_times[time_index]

    history_shift = history_window/time_step
    w_params = fltarr(ntime,nw_param)
    w_vars = strarr(nw_param)
    for ww=0,nw_param-1 do begin
        lambda = w_lambda[ww]
        beta  = w_beta[ww]
        gamma = w_gamma[ww]
        decay_rate = w_r[ww]/3600.0     ; decay rate per second.

        s_n = (n_normed gt 0)*(n_normed > 0)^lambda
        s_v = (v_normed gt 0)*(v_normed > 0)^beta
        s_bs = (bs_normed gt 0)*(bs_normed > 0)^gamma
        s = s_n*s_v*s_bs

        decay = -decay_rate*smkarthm(history_window,0,-time_step,'dx')
        for tid=0,ntime-1 do begin
            i1 = time_index[tid]
            i0 = i1-history_shift
            sub_s = s[i0:i1]
            w_params[tid,ww] = decay_rate*time_step*total(sub_s*exp(decay))
        endfor

        if keyword_set(test) then begin
            w_str = 'W'+string(ww+1,format='(I0)')
            w_var = var_store('geopack_'+strlowcase(w_str), w_params[*,ww], times)
            options, w_var, ytitle=w_str, yrange=[0.01,100], ylog=1
            w_vars[ww] = w_var
        endif
    endfor

    settings = dictionary($
        'requested_time_range', time_range, $
        'display_type', 'stack', $
        'labels', 'W'+string(findgen(nw_param+1),format='(I0)'), $
        'ytitle', 'W Param' )
    var_info = var_store(var_info, w_params, times, settings=settings)


    if keyword_set(test) then begin
        dst_var = omni_read_symh(data_tr)
        options, dst_var, yrange=[-200,150]
        options, sw_n_var, ylog=1, yrange=[1,100]
        sw_v_var = var_store('omni_sw_v', sw_speed, common_times)
        options, sw_v_var, yrange=[200,800], ytitle='V (km/s)'
        sw_bz_var = var_store('omni_sw_bz', b_vec[*,2], common_times)
        options, sw_bz_var, yrange=[-1,1]*20, ytitle='Bz!C(nT)'

        plot_vars = [dst_var, sw_n_var, sw_v_var, sw_bz_var, w_vars]
        tplot, plot_vars
        stop
    endif

    return, var_info
  
end 


compile_opt idl2
w_vars = list()
end
