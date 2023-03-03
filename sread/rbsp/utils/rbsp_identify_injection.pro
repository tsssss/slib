function simplify_time_range, time_ranges, common_times

    ntime_range = n_elements(time_ranges)*0.5

    ntime = n_elements(common_times)
    time_step = common_times[1]-common_times[0]
    
    flags = fltarr(ntime)
    pad_time = 180.
    pad_rec = pad_time/time_step
    for ii=0,ntime_range-1 do begin
        index = (reform(time_ranges[ii,*])-common_times[0])/time_step
        index[0] = (index[0]-pad_rec)>0
        index[1] = (index[1]+pad_rec)<(ntime-1)
        flags[index[0]:index[1]] = 1
    endfor
    index = where(flags eq 1)
    
    return, common_times[time_to_range(index,time_step=1)]
    
end


function rbsp_identify_injection, time_range, mission_probe=mission_probe, $
    probe=probe, prefix=prefix, routine_name=routine_name, min_duration=min_duration

    secofday = constant('secofday')
    if n_elements(mission_probe) ne 0 then begin
        probe_info = resolve_probe(mission_probe)
        prefix = probe_info.prefix
        probe = probe_info.probe
        routine_name = probe_info.routine_name
    endif
    

    ; Load electron flux.
    window_long = 3600d
    window_short = window_long*0.25
    data_time_range = time_range+[-1,1]*window_long

    routine = routine_name+'_read_kev_electron'
    flux_var0 = call_function(routine, data_time_range, probe=probe, spec=1)
    flux_var = flux_var0+'1'
    rename_var, flux_var0, to=flux_var
    time_step = 120.
    uniform_time, flux_var, time_step
    
    
    ; Prepare the flux.
    full_fluxs = get_var_data(flux_var, energys, times=full_times, limits=lim)
    target_energy = 100.    ; kev.
    tmp = min(energys-target_energy, energy_index, abs=1)
    
    ; Remove very low flux and nan.
    invalid_flux = 1e0
    ntime = n_elements(full_times)
    pad_rec = 2
    tmp = full_fluxs[*,energy_index]
    index = where(tmp le invalid_flux or finite(tmp,nan=1), count)
    if count ne 0 then begin
        ranges = time_to_range(index,time_step=1)
        nrange = n_elements(ranges)*0.5
        for ii=0,nrange-1 do begin
            i0 = (ranges[ii,0]-pad_rec)>0
            i1 = (ranges[ii,1]+pad_rec)<(ntime-1)
            full_fluxs[i0:i1,*] = !values.f_nan
        endfor
    endif
    store_data, flux_var, full_times, full_fluxs, energys
    time_index = lazy_where(full_times, '[]', time_range)
    common_times = full_times[time_index]
    fluxs = full_fluxs[time_index,*]

    
    ; Get distance.
    routine = routine_name+'_read_orbit'
    r_var = call_function(routine, data_time_range, probe=probe)
    get_data, r_var, times, r_vec
    dis_var = prefix+'dis'
    dis = snorm(r_vec)
    store_data, dis_var, times, dis
    add_setting, dis_var, smart=1, dictionary($
        'unit', 'Re', $
        'short_name', '|R|', $
        'display_type', 'scalar', $
        'yticks', 2, $
        'yminor', 2, $
        'ytickv', [2,4,6] )
    dis = interpol(dis, times, common_times, quadratic=1)
    
    
    ; Identify injection around perigee: select spectral peak around 100 keV.
    min_dis = 1.5
    min_ratio1 = 3
    min_flux = 1e3
    flux = fluxs[*,energy_index]

    flux1 = fluxs[*,energy_index-1]
    flux2 = fluxs[*,energy_index+1]
    ratio1 = flux^2/(flux1*flux2)
    ratio_var1 = prefix+'ratio1'
    store_data, ratio_var1, common_times, ratio1, limits={$
        ylog:1, constant:min_ratio1, yrange:[0.1,10], ytitle:'flux ratio'}
    add_setting, ratio_var1, smart=1, dictionary($
        'unit', '#', $
        'short_name', 'Flux ratio', $
        'display_type', 'scalar' )
    index1 = where((ratio1 ge min_ratio1 and dis ge min_dis and flux ge min_flux), count1)
    if count1 eq 0 then begin
        tr_perigee = !null
    endif else begin
        tr_perigee = common_times[time_to_range(index1,time_step=1)]
    endelse
    tr_perigee = simplify_time_range(tr_perigee, common_times)
    

    ; Identify injection around apogee: select local flux bumps.
    ; Use the energy bin around 80 keV.
    target_energy_apogee = 80.  ; kev.
    tmp = min(energys-target_energy_apogee, abs=1, energy_index_apogee)
    flux_apogee = full_fluxs[*,energy_index_apogee-1]
    flux_long = 10.^smooth(alog10(flux_apogee), nan=1, window_long/time_step, edge_zero=1)
    flux_short = 10.^smooth(alog10(flux_apogee), nan=1, window_short/time_step, edge_zero=1)
    time_index = lazy_where(full_times, '[]', time_range)
    flux_long = flux_long[time_index]
    flux_short = flux_short[time_index]
    flux_apogee = flux_apogee[time_index]
    ; The the background flux, loose beyond 4-5 Re.
    dis_coef = tanh((dis-3.5)/1)
    weight = (dis_coef+1)*0.5
    flux_bg = flux_long*(weight)+flux_short*(1-weight)
    flux_bg = (2-dis_coef)*flux_bg+2e2  ; elevate the bg within and around the slot region to eliminate false detection.
;    store_data, prefix+'test_flux', common_times, [[flux_long],[flux_short],[flux_apogee]], $
;        limits={ylog:1, colors:sgcolor(['red','green','blue']), labels:['long_smooth','short_smooth','orig']}
;    sgopen, 0
;    tplot, prefix+'test_flux', trange=time_range
;    stop
    
    
    min_dis2 = 3.5
    index2 = where((flux_short ge flux_long and dis ge min_dis2), count2)
    if count2 eq 0 then begin
        time_range2 = !null
    endif else begin
        time_range2 = common_times[time_to_range(index2,time_step=1)]
    endelse
    time_range2 = simplify_time_range(time_range2, common_times)
    ntr = n_elements(time_range2)*0.5
    flags = fltarr(ntr)
    ir = (time_range2-common_times[0])/time_step
    dflux = flux_short-flux_long
    pad_rec = 2
    for ii=0, ntr-1 do begin
        tmp = dflux[ir[ii,0]:ir[ii,1]]
        nrec = n_elements(tmp)
        max_val = tmp[(sort(tmp))[nrec*0.8]]
        ttmp = min(tmp-max_val, abs=1, index)
        base_val = (flux_long[ir[ii,0]:ir[ii,1]])[index]
        ; strong peak in absolute value or ratio.
        if max_val ge 1e4 or max_val/base_val ge 0.1 then begin
            flags[ii] = 1
        endif
        tmp = flux_short[ir[ii,0]:ir[ii,1]]
        ttmp = max(tmp, index)
        if index le pad_rec or index ge nrec-1-pad_rec then begin
            flags[ii] = 0
        endif
    endfor
    index = where(flags eq 1, count)
    if count eq 0 then begin
        time_range2 = !null
    endif else begin
        time_range2 = time_range2[index,*]
    endelse
    
    
    ; Combine the results.
    time_range_list = list()
    time_range_list.add, tr_perigee
    time_range_list.add, time_range2
    ntime = n_elements(common_times)
    flags = fltarr(ntime)
    foreach tr, time_range_list do begin
        if n_elements(tr) eq 0 then continue
        ir = (tr-common_times[0])/time_step
        nir = n_elements(ir)*0.5
        for ii=0,nir-1 do flags[ir[ii,0]:ir[ii,1]] = 1
    endforeach
    index = where(flags eq 1, count)
    if count eq 0 then begin
        time_ranges = !null
    endif else begin
        time_ranges = common_times[time_to_range(index,time_step=1)]
    endelse
    
    
    ; Remove those around nan.
    ntr = n_elements(time_ranges)*0.5
    irs = (time_ranges-common_times[0])/time_step
    flags = fltarr(ntr)
    for ii=0,ntr-1 do begin
        tmp = flux[irs[ii,0]:irs[ii,1]]
        index = where(finite(tmp,nan=1),count)
        if count ne 0 then flags[ii] = 1
    endfor
    index = where(flags eq 0, count)
    if count eq 0 then begin
        time_ranges = !null
    endif else begin
        time_ranges = time_ranges[index,*]
    endelse
    
    ; Remove those are too short.
    if n_elements(min_duration) eq 0 then min_duration = 60.
    ntr = n_elements(time_ranges)*0.5
    if ntr ne 0 then begin
        durs = time_ranges[*,1]-time_ranges[*,0]
        index = where(durs gt min_duration, count)
        if count eq 0 then begin
            time_ranges = !null
        endif else begin
            time_ranges = time_ranges[index,*]
        endelse
    endif
    
    return, time_ranges

    ; for getting test plots, check rbsp_themis_injection_identify_injections_v03.

end


time_range = time_double(['2013-07-25','2013-07-26'])
mission_probe = 'thd'
trs = identify_injection(time_range, mission_probe=mission_probe)
end