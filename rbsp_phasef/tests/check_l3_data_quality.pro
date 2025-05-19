;+
; Check L3 data spinfit E, from 2015-01-01 to 2015-10-01
;-

;---Settings.
    probes = ['a']
    time_range = time_double(['2015-01-01','2016-01-01'])
    time_range = time_double(['2015-01-01','2015-10-01'])
    ;time_range = time_double(['2016-01-01','2017-01-01'])

    boom_pairs = ['12','24']
    dtime = 600
    fillval = !values.f_nan
    perigee_lshell = 3


    foreach probe, probes do begin
        prefix = 'rbsp'+probe+'_'
        pos_var = prefix+'position_gse'

        flag_var = prefix+'efw_flags'
        if check_if_update(flag_var, time_range, dtime=dtime) then begin
            rbsp_efw_read_flags, time_range, probe=probe
        endif

        foreach boom_pair, boom_pairs do begin            
        ;---Load spinfit data.
            e_var = prefix+'efield_in_corotation_frame_spinfit_mgse_'+boom_pair
            if check_if_update(e_var, time_range, dtime=dtime) then begin
                rbsp_efw_read_l4, time_range, probe=probe
            endif
            
            if ~check_if_update(e_var+'_perigee', time_range, dtime=dtime) then continue


        ;---Apply flags.
            get_data, e_var, common_times, e_mgse
            all_flags = get_var_data(prefix+'efw_flags', at=common_times, limits=lim)
            index = where(lim.labels eq 'boomflag1')
            boom_flags = all_flags[*,index[0]+[0,1,2,3]] ne 0

            the_flag_var = prefix+'flags_all_'+boom_pair
            flags = get_var_data(the_flag_var)

            ; New flags.
            ntime = n_elements(common_times)
            new_flags = fltarr(ntime,25)
            new_flags[*,0:17] = flags[*,0:17]
            new_flags[*,18:21] = boom_flags
            new_flags >= 0
            store_data, prefix+'flag_'+boom_pair, common_times, new_flags, $
                limits = {ystyle:1, yrange:[-0.2,1.2] }

            global_flag = total(new_flags,2) ne 0
            bad_index = where(global_flag eq 1, count)
            e_mgse[bad_index,*] = fillval
            store_data, e_var, common_times, e_mgse


        ;---Mask perigee data.
            get_data, e_var, common_times, e_mgse
            dis = snorm(get_var_data(pos_var))/constant('re')
            store_data, prefix+'r_gse', common_times, dis
            index = where(dis le perigee_lshell, complement=index2)
            data = e_mgse
            data[index2,*] = fillval
            store_data, e_var+'_perigee', common_times, data
            data = e_mgse
            data[index,*] = fillval
            store_data, e_var+'_apogee', common_times, data
        endforeach
        
        
        plot_file = join_path([srootdir(),'fig_check_l3_v24_v12.pdf'])
        sgopen, plot_file, xsize=8, ysize=6
        vars = prefix+'efield_in_corotation_frame_spinfit_mgse_'+$
            ['12','24']+'_apogee'
        options, vars, 'colors', constant('rgb')

        options, vars, 'ytitle', '(mV/m)'
        options, vars[0], 'labels', 'V12 E'+constant('xyz')
        options, vars[1], 'labels', 'V24 E'+constant('xyz')
        
        tplot_options, 'labflag', -1
        tplot, vars, trange=time_range
        
        sgclose
        
        
        
        plot_file = join_path([srootdir(),'fig_check_l3_ey_ez.pdf'])
        poss = panel_pos(plot_file, nxpan=2, nypan=1, pansize=[3,3], fig_size=fig_size)
        sgopen, plot_file, xsize=fig_size[0], ysize=fig_size[1]
        psym = 3

        d1 = get_var_data(vars[0], in=time_range)
        d2 = get_var_data(vars[1], in=time_range)
        
        e_range = [-1,1]*60
        xtitle = 'MGSE Ey (mV/m) V12'
        ytitle = 'MGSE Ey (mV/m) V24'
        tpos = poss[*,0]
        plot, d1[*,1], d2[*,1], $
            xstyle=1, xrange=e_range, xtitle=xtitle, $
            ystyle=1, yrange=e_range, ytitle=ytitle, $
            position=tpos, /noerase, psym=psym
        oplot, e_range, e_range, linestyle=1
        
        xtitle = 'MGSE Ez (mV/m) V12'
        ytitle = 'MGSE Ez (mV/m) V24'
        tpos = poss[*,1]
        plot, d1[*,2], d2[*,2], $
            xstyle=1, xrange=e_range, xtitle=xtitle, $
            ystyle=1, yrange=e_range, ytitle=ytitle, $
            position=tpos, /noerase, psym=psym
        oplot, e_range, e_range, linestyle=1
        
        sgclose
    endforeach



end
