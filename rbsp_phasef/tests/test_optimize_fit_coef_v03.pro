;+
; Check how to optimize the fit coef.
;
;-

test = 0
probes = ['a','b']
root_dir = join_path([homedir(),'test_fit_e_mgse'])
rgb = constant('rgb')
labels = [tex2str('alpha'),tex2str('beta'),tex2str('gamma')]
tplot_options, 'labflag', -1
deg = constant('deg')
root_dir = join_path([homedir(),'test_fit_e_mgse'])


;---Test for a year.
    test_time_range = time_double(['2013','2019'])
    test_probes = ['a','b']
    foreach probe, test_probes do begin
        prefix = 'rbsp'+probe+'_'


    ;---Read fit_list
        fit_list = rbsp_phasef_read_fit_coef(test_time_range, probe=probe)
        section_times = list()
        y_coef = list()
        z_coef = list()
        foreach fit_info, fit_list do begin
            time_range = fit_info.time_range
            if product(test_time_range-time_range[0]) gt 0 and product(test_time_range-time_range[1]) gt 0 then continue
            section_times.add, time_range
            y_coef.add, fit_info.y
            z_coef.add, fit_info.z
        endforeach
        section_times = section_times.toarray()
        y_coef = y_coef.toarray()
        z_coef = z_coef.toarray()

        ; Remove large angle.
        the_times = section_times[*,0]
        rad = constant('rad')
        for ii=0,2 do begin
            index = where(abs(y_coef[*,ii]) lt 5*rad)
            y_coef[*,ii] = interpol(y_coef[index,ii], the_times[index], the_times)
            index = where(abs(z_coef[*,ii]) lt 5*rad)
            z_coef[*,ii] = interpol(z_coef[index,ii], the_times[index], the_times)
        endfor
        store_data, prefix+'maneuver_fit_coef', section_times, y_coef, z_coef


    ;---Load data.
        section_time_range = minmax(section_times)
        if check_if_update(prefix+'b_mgse') then begin
            rbsp_efw_phasef_read_wobble_free_var, section_time_range, probe=probe
            rbsp_read_e_model, section_time_range, probe=probe, datatype='e_model_related'
            rbsp_efw_phasef_read_e_spinfit, section_time_range, probe=probe
        endif

    ;---Fitting data.
        if check_if_update(prefix+'fit_data') then begin
            b_mgse = get_var_data(prefix+'b_mgse', times=times)
            v_mgse = get_var_data(prefix+'v_mgse')
            vcoro_mgse = get_var_data(prefix+'vcoro_mgse')
            u_mgse = (v_mgse-vcoro_mgse)*1e-3

            ndim = 3
            nrec = n_elements(times)
            xxs = fltarr(ndim,nrec,ndim)
            ; For Ey.
            xxs[0,*,1] =  u_mgse[*,0]*b_mgse[*,1]
            xxs[1,*,1] = -u_mgse[*,0]*b_mgse[*,0]-u_mgse[*,2]*b_mgse[*,2]
            xxs[2,*,1] =  u_mgse[*,2]*b_mgse[*,1]
            ; For Ez.
            xxs[0,*,2] =  u_mgse[*,0]*b_mgse[*,2]
            xxs[1,*,2] =  u_mgse[*,1]*b_mgse[*,0]
            xxs[2,*,2] = -u_mgse[*,0]*b_mgse[*,0]-u_mgse[*,1]*b_mgse[*,1]

            copy_data, prefix+'e_mgse', prefix+'de_mgse'
            get_data, prefix+'de_mgse', uts, dat
            index = where(finite(dat[*,1]), count)
            if count ne 0 then dat[index,0] = 0
            store_data, prefix+'de_mgse', uts, dat
            interp_time, prefix+'de_mgse', times
            yys = get_var_data(prefix+'de_mgse')
            store_data, prefix+'fit_data', times, xxs, yys
        endif


    ;---Fit Ey and Ez separately and together.
        ;if check_if_update(prefix+'ey_fit') then begin
            get_data, prefix+'maneuver_fit_coef', section_times, y_coef, z_coef
            get_data, prefix+'fit_data', times, xxs, yys
            nsection = n_elements(section_times)*0.5
            ntime = n_elements(times)
            fillval = !values.f_nan
            ey_fit = fltarr(ntime)+fillval
            ez_fit = fltarr(ntime)+fillval
            ey_old = yys[*,1]
            ez_old = yys[*,2]
            dis = snorm(get_var_data(prefix+'r_mgse'))
            dis_index = where(dis ge 2)
            ey_old[dis_index] = fillval
            ez_old[dis_index] = fillval
            for ii=0,nsection-1 do begin
                section_time_range = reform(section_times[ii,*])
                index = where_pro(times, '[]', section_time_range)
                ey_fit[index] = xxs[*,index,1] ## reform(y_coef[ii,0:2])+y_coef[ii,3]
                ez_fit[index] = xxs[*,index,2] ## reform(z_coef[ii,0:2])+z_coef[ii,3]

                ; Recover the old data if fit does not work.
                ey_stddev_old = stddev(abs(ey_old[index]),/nan)
                ez_stddev_old = stddev(abs(ez_old[index]),/nan)
                ey_stddev_new = stddev(abs(ey_old[index]-ey_fit[index]),/nan)
                ez_stddev_new = stddev(abs(ez_old[index]-ez_fit[index]),/nan)

                if ez_stddev_new gt ez_stddev_old then begin
                    ez_fit[index] = 0
                    z_coef[where(section_times[*,0] eq section_time_range[0]),*] = 0
                endif
                if ey_stddev_new gt ey_stddev_old then begin
                    ey_fit[index] = 0
                    y_coef[where(section_times[*,0] eq section_time_range[0]),*] = 0
                endif
            endfor
            store_data, prefix+'ey_fit', times, ey_fit
            store_data, prefix+'ez_fit', times, ez_fit
            store_data, prefix+'maneuver_fit_coef', section_times, y_coef, z_coef
        ;endif


    ;---Prepare plot.
        get_data, prefix+'fit_data', times, xxs, yys
        ey_fit = get_var_data(prefix+'ey_fit')
        ez_fit = get_var_data(prefix+'ez_fit')
        ey_old = yys[*,1]
        ez_old = yys[*,2]
        ey_new = ey_old-ey_fit
        ez_new = ez_old-ez_fit

        dis = snorm(get_var_data(prefix+'r_mgse'))
        dis_index = where(dis ge 2)
        ey_new[dis_index,*] = fillval
        ez_new[dis_index,*] = fillval
        store_data, prefix+'ey_new', times, ey_new
        store_data, prefix+'ez_new', times, ez_new
        add_setting, prefix+'ey_new', /smart, dictionary($
            'display_type', 'scalar', $
            'unit', 'mV/m', $
            'short_name', 'Ey after fit' )
        add_setting, prefix+'ez_new', /smart, dictionary($
            'display_type', 'scalar', $
            'unit', 'mV/m', $
            'short_name', 'Ez after fit' )

        ey_old[dis_index,*] = fillval
        ez_old[dis_index,*] = fillval
        store_data, prefix+'ey_old', times, ey_old
        store_data, prefix+'ez_old', times, ez_old
        add_setting, prefix+'ey_old', /smart, dictionary($
            'display_type', 'scalar', $
            'unit', 'mV/m', $
            'short_name', 'Ey before fit' )
        add_setting, prefix+'ez_old', /smart, dictionary($
            'display_type', 'scalar', $
            'unit', 'mV/m', $
            'short_name', 'Ez before fit' )


        ; Fit coef.
        get_data, prefix+'maneuver_fit_coef', times, y_coef, z_coef
        store_data, prefix+'ey_coef', reform(times[*,0]), y_coef[*,0:2]*deg
        store_data, prefix+'ez_coef', reform(times[*,0]), z_coef[*,0:2]*deg
        add_setting, prefix+'ey_coef', /smart, dictionary($
            'display_type', 'stack', $
            'unit', 'deg', $
            'colors', rgb, $
            'labels', 'Ey fit angles '+labels )
        add_setting, prefix+'ez_coef', /smart, dictionary($
            'display_type', 'stack', $
            'unit', 'deg', $
            'colors', rgb, $
            'labels', 'Ez fit angles '+labels )
        ylim, prefix+'ey_coef', [-1,1]*5
        ylim, prefix+'ez_coef', [-1,1]*5


        vars = prefix+['ey_'+['old','new'],'ez_'+['old','new']]
        ylim, vars, [-1,1]*6
        vars = prefix+['ey','ez']+'_new'
        options, vars, 'constant', [-1,1]*2
        tmp = ['old','new','coef']
        vars = prefix+['ey_'+tmp, 'ez_'+tmp]
        options, vars, 'yticklen', -0.005
        options, vars, 'xticklen', -0.04

        plot_file = join_path([root_dir,prefix+'ey_ez_before_after_fit_per_maneuver_v03.pdf'])
        if keyword_set(test) then plot_file = 0
        sgopen, plot_file, xsize=10, ysize=8
        tplot, vars, trange=test_time_range
        timebar, section_times
        if keyword_set(test) then stop
        sgclose

    endforeach

    tmp = ['ey_old','ey_new','ez_old','ez_new']
    vars = []
    foreach probe, test_probes do begin
        prefix = 'rbsp'+probe+'_'
        vars = [vars, prefix+tmp]
    endforeach
    cdf_file = join_path([root_dir,'test_optimize_fit_coef_v03.cdf'])
    stplot2cdf, vars, time_var='epoch', istp=1, filename=cdf_file
stop




;---Plot all coef.
    foreach probe, probes do begin
        prefix = 'rbsp'+probe+'_'

        ; Read fit_list
        fit_list = rbsp_phasef_read_fit_coef(probe=probe)
        times = list()
        y_coef = list()
        z_coef = list()
        foreach fit_info, fit_list do begin
            times.add, fit_info.time_range
            y_coef.add, fit_info.y
            z_coef.add, fit_info.z
        endforeach
        times = times.toarray()
        y_coef = y_coef.toarray()
        z_coef = z_coef.toarray()
        store_data, prefix+'y_coef', reform(times[*,0]), y_coef[*,0:2]*deg, limits={colors:rgb, labels:labels+' Ey RB-'+strupcase(probe), ytitle:'(deg)'}
        store_data, prefix+'z_coef', reform(times[*,0]), z_coef[*,0:2]*deg, limits={colors:rgb, labels:labels+' Ez RB-'+strupcase(probe), ytitle:'(deg)'}
    endforeach

    vars = tnames('rbsp'+probes+'_?_coef')
    plot_file = join_path([root_dir,'fit_coef_over_time.pdf'])
    if keyword_set(test) then plot_file = 0
    sgopen, plot_file, xsize=6, ysize=8
    tplot, vars
    if keyword_set(test) then stop
    sgclose




end
