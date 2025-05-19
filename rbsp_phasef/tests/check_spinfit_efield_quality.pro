;+
; Check long-term data quality of the L4 data.
;-

;---Settings.
    probes = ['b','a']
    years = make_bins([2012,2019], 1)

    boom_pairs = ['12','34','13','14','23','24']
    dtime = 600
    fillval = !values.f_nan
    perigee_lshell = 3

    foreach probe, probes do begin
        prefix = 'rbsp'+probe+'_'
        foreach year, years do begin
            the_boom_pair = '12'
            if probe eq 'a' then begin
                if year ge 2015 then the_boom_pair = '24'
            endif
            str_year = string(year, format='(I4)')
            time_range = time_double(str_year+['-01-01','-12-31/24:00'])


        ;---Load spinfit data.
            e_vars = prefix+'e_spinfit_mgse_v'+boom_pairs
            e_var = e_vars[0]
            if check_if_update(e_var, time_range, dtime=dtime) then begin
                rbsp_efw_phasef_read_spinfit_efield, time_range, probe=probe
                get_data, e_vars[0], times
                ntime = n_elements(times)
                foreach e_var, e_vars do begin
                    get_data, e_var, tmp
                    if n_elements(tmp) eq ntime then continue
                    interp_time, e_var, times
                endforeach
            endif


        ;---Load boom flags.
            boom_flag_var = prefix+'boom_flag'
            if check_if_update(boom_flag_var, time_range, dtime=dtime) then begin
                rbsp_efw_read_boom_flag, time_range, probe=probe
                interp_time, boom_flag_var, to=e_var
            endif



        ;---Load other flags.
            in_vars = ['flags_charging_bias_eclipse'+'_'+boom_pairs,'position_gse']
            out_vars = prefix+['flags_'+boom_pairs,'r_gse']
            if check_if_update(out_vars[0], time_range, dtime=dtime) then begin
                if n_elements(local_root) eq 0 then local_root = join_path([default_local_root(),'rbsp'])
                if n_elements(version) eq 0 then version = 'v02'

                valid_range = (probe eq 'a')? time_double(['2012-09-08','2019-10-15']): time_double(['2012-09-08','2019-07-17'])
                rbspx = 'rbsp'+probe
                base_name = rbspx+'_efw-l4_%Y%m%d_'+version+'.cdf'
                local_path = [local_root,rbspx,'level4','%Y']

                request = dictionary($
                    'pattern', dictionary($
                    'local_file', join_path([local_path,base_name]), $
                    'local_index_file', join_path([local_path,default_index_file()])), $
                    'valid_range', time_double(valid_range), $
                    'cadence', 'day', $
                    'extension', fgetext(base_name), $
                    'var_list', list($
                    dictionary($
                    'in_vars', in_vars, $
                    'out_vars', out_vars, $
                    'time_var_name', 'epoch', $
                    'time_var_type', 'epoch16')) )
                files = prepare_files(request=request, time=time_range)
                read_files, time_range, files=files, request=request

                foreach var, out_vars do begin
                    interp_time, var, to=e_vars[0]
                    options, var, 'yrange', [-1,1]*0.1+[0,1]
                endforeach
            endif



        ;---Apply flags.
            boom_flags = get_var_data(boom_flag_var)
            index = where(total(boom_flags) ne 4, count)
            if count ne 0 then begin
                foreach e_var, e_vars do begin
                    e_mgse = get_var_data(e_var, times=times, limits=lim)
                    e_mgse[index,*] = fillval
                    store_data, e_var+'_flag', times, e_mgse, limits=lim
                endforeach
            endif


            foreach boom_pair, boom_pairs do begin
                flag_var = prefix+'flags_'+boom_pair
                flags = get_var_data(flag_var)
                bad_index = where(total(flags,2) ne 0, count)

                pad_time = 600. ; sec.
                if count ne 0 then begin
                    e_var = prefix+'e_spinfit_mgse_v'+boom_pair
                    e_mgse = get_var_data(e_var+'_flag', times=times)
                    bad_times = times[time_to_range(bad_index,time_step=1)]
                    nbad_time = n_elements(bad_times)*0.5
                    for ii=0,nbad_time-1 do begin
                        index = where_pro(times, '[]', bad_times[ii,*]+[-1,1]*pad_time, count=count)
                        if count eq 0 then continue
                        e_mgse[index,*] = fillval
                    endfor
                    store_data, e_var+'_flag', times, e_mgse
                endif
            endforeach



        ;---Save a plot.
            root_dir = join_path([homedir(),'test_spinfit_efield_quality'])

            plot_file = join_path([root_dir,'plot',prefix+str_year+'_v'+the_boom_pair+'.pdf'])
            sgopen, plot_file, xsize=8, ysize=5
            index = where(boom_pairs eq the_boom_pair)
            the_e_var = e_vars[index[0]]
            tplot, the_e_var+['','_flag'], trange=time_range, $
                title='E spinfit from V'+the_boom_pair+' before/after flags are applied'
            
            sgclose

        ;---Save data.
            dis = snorm(get_var_data(prefix+'r_gse'))/constant('re')
            perigee_index = where(dis le perigee_lshell, complement=apogee_index)
            save_vars = list()
            foreach boom_pair, boom_pairs do begin
                e_var = prefix+'e_spinfit_mgse_v'+boom_pair

                e_perigee_var = prefix+'e_spinfit_mgse_perigee_v'+boom_pair
                e_mgse = get_var_data(e_var+'_flag', times=times, limits=lim)
                e_mgse[apogee_index,*] = fillval
                store_data, e_perigee_var, times, e_mgse, limits=lim

                e_apogee_var = prefix+'e_spinfit_mgse_apogee_v'+boom_pair
                e_mgse = get_var_data(e_var+'_flag', times=times, limits=lim)
                e_mgse[perigee_index,*] = fillval
                store_data, e_apogee_var, times, e_mgse, limits=lim

                save_vars.add, [e_var,e_apogee_var,e_perigee_var], /extract
                save_vars.add, prefix+['r_gse','boom_flag','flags_'+boom_pair], /extract
            endforeach
            save_vars = save_vars.toarray()

            data_file = join_path([root_dir,'data',prefix+str_year+'.cdf'])
            stplot2cdf, save_vars, istp=1, time_var='epoch', filename=data_file  
        endforeach
    endforeach



end
