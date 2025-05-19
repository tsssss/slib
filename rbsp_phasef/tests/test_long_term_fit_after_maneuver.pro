;+
; Read the full maneuver list, then use first several orbits to calculate
; the fit coefs, then apply the fit coefs to the rest orbits before next maneuver.
;-

;---Input.
    probe = 'b'
    time_range = time_double(['2013','2014'])


    fillval = !values.f_nan
    xyz = constant('xyz')


    prefix = 'rbsp'+probe+'_'
    if check_if_update(prefix+'r_mgse', time_range) then begin
        rbsp_efw_phasef_read_wobble_free_var, time_range, probe=probe
    endif

    if check_if_update(prefix+'emod_mgse', time_range) then begin
        rbsp_read_e_model, time_range, probe=probe, datatype='e_model_related'
    endif

    if check_if_update(prefix+'dis', time_range) then begin
        dis = snorm(get_var_data(prefix+'r_mgse', times=times))
        store_data, prefix+'dis', times, dis
    endif

    if check_if_update(prefix+'perigee_times') then begin
        dis = get_var_data(prefix+'dis', times=times)
        orbit_time_step = total(times[0:1]*[-1,1])
        index = where(dis le 2)
        perigee_times = times[time_to_range(index, time_step=1)]
        store_data, prefix+'perigee_times', 0, perigee_times
    endif

    maneuver_times = rbsp_read_maneuver_time(time_range, probe=probe)
    nmaneuver_time = n_elements(maneuver_times)*0.5
    perigee_times = get_var_data(prefix+'perigee_times')
    for ii=0,nmaneuver_time-2 do begin
        ; Find the first perigee after maneuver.
        maneuver_time_range = reform(maneuver_times[ii,*])
        index = where(perigee_times[*,0] ge maneuver_time_range[1], count)
        if count eq 0 then continue
        nperigee_time_range = (count ge 3)? 3: count
        perigee_time_ranges = perigee_times[index[0:nperigee_time_range-1],*]

        ; Prepare fitting.
        de_mgse = []
        b_mgse = []
        u_mgse = []
        for jj=0,nperigee_time_range-1 do begin
            b_mgse = [b_mgse,get_var_data(prefix+'b_mgse', in=perigee_time_ranges[jj,*])]
            v_mgse = get_var_data(prefix+'v_mgse', in=perigee_time_ranges[jj,*])
            vcoro_mgse = get_var_data(prefix+'vcoro_mgse', in=perigee_time_ranges[jj,*])
;            u_mgse = [u_mgse,(v_mgse-vcoro_mgse)*1e-3]
            u_mgse = [u_mgse,(vcoro_mgse)*1e-3]
            e_mgse = get_var_data(prefix+'e_mgse', in=perigee_time_ranges[jj,*])
            emod_mgse = get_var_data(prefix+'emod_mgse', in=perigee_time_ranges[jj,*])
            de_mgse = [de_mgse,e_mgse-emod_mgse]
        endfor


        ; Data as input for linear regression.
        ndim = 3
        yys = de_mgse
        nrec = n_elements(yys[*,0])
        xxs = fltarr(ndim,nrec,ndim)
        ; For Ey.
        xxs[0,*,1] =  u_mgse[*,0]*b_mgse[*,1]
        xxs[1,*,1] = -u_mgse[*,0]*b_mgse[*,0]-u_mgse[*,2]*b_mgse[*,2]
        xxs[2,*,1] =  u_mgse[*,2]*b_mgse[*,1]
        ; For Ez.
        xxs[0,*,2] =  u_mgse[*,0]*b_mgse[*,2]
        xxs[1,*,2] =  u_mgse[*,1]*b_mgse[*,0]
        xxs[2,*,2] = -u_mgse[*,0]*b_mgse[*,0]-u_mgse[*,1]*b_mgse[*,1]


        ; Calc fit coefs.
        fit_coef = fltarr(ndim+1,ndim)+fillval
        fit_index = [1,2]
        foreach jj, fit_index do begin
            yy = yys[*,jj]
            index = where(finite(yy), count)
            if count lt 10 then continue

            xx = xxs[*,*,jj]
            res = regress(xx[*,index],yy[index], sigma=sigma, const=const)
            fit_coef[*,jj] = [res[*],const]
        endforeach


        ; Apply fit coefs.
        data_time_range = maneuver_times[ii:ii+1,1]
        b_mgse = get_var_data(prefix+'b_mgse', in=data_time_range, times=times)
        v_mgse = get_var_data(prefix+'v_mgse', in=data_time_range)
        vcoro_mgse = get_var_data(prefix+'vcoro_mgse', in=data_time_range)
;        u_mgse = (v_mgse-vcoro_mgse)*1e-3
        u_mgse = (vcoro_mgse)*1e-3
        e_mgse = get_var_data(prefix+'e_mgse', in=data_time_range)
        emod_mgse = get_var_data(prefix+'emod_mgse', in=data_time_range)
        de_mgse = e_mgse-emod_mgse

        yys = de_mgse
        nrec = n_elements(yys[*,0])
        xxs = fltarr(ndim,nrec,ndim)
        ; For Ey.
        xxs[0,*,1] =  u_mgse[*,0]*b_mgse[*,1]
        xxs[1,*,1] = -u_mgse[*,0]*b_mgse[*,0]-u_mgse[*,2]*b_mgse[*,2]
        xxs[2,*,1] =  u_mgse[*,2]*b_mgse[*,1]
        ; For Ez.
        xxs[0,*,2] =  u_mgse[*,0]*b_mgse[*,2]
        xxs[1,*,2] =  u_mgse[*,1]*b_mgse[*,0]
        xxs[2,*,2] = -u_mgse[*,0]*b_mgse[*,0]-u_mgse[*,1]*b_mgse[*,1]
        
        dis = get_var_data(prefix+'dis', in=data_time_range)
        index = where(dis gt 2)
        yys[index,*] = fillval
        xxs[*,index,*] = fillval

        foreach jj, fit_index do begin
            yy = yys[*,jj]
            res = fit_coef[0:ndim-1,jj]
            const = fit_coef[ndim-1,jj]
            yfit = reform(xxs[*,*,jj] ## res)+const
            store_data, prefix+'de'+xyz[jj], times, [[yy],[yy-yfit]], $
                limits={colors:sgcolor(['red','blue']),labels:['orig','fixed']}
        endforeach


        stop
    endfor



end
