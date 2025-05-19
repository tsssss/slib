;-
; Check yearly data for problematic perigees.
; Adopted from test_raw_perigee_correction.
;+

    xyz = constant('xyz')
    de_threshold = 10.
    perigee_threshold = 2.
    common_time_step = 10.
    eclipse_pad_time = 60.
    test = 1

    probes = ['a']
    if keyword_set(test) then probes = 'a'
    foreach probe, probes do begin
        prefix = 'rbsp'+probe+'_'

        years = make_bins([2013,2018],1)
        foreach year, years do begin
            time_range = time_double(string(year+[0,1],format='(I0)'))
            if keyword_set(test) then time_range = time_double(['2014-06-14','2014-06-19'])
            if keyword_set(test) then time_range = time_double(['2015-06-01','2015-08-01'])
            if keyword_set(test) then time_range = time_double('2017-01-01')+[-1,1]*86400*10
            common_times = make_bins(time_range, common_time_step)


        ;---Calculate E-E_coro-E_vxb.
            rbsp_efw_phasef_read_wobble_free_var, time_range, probe=probe, id='quaternion'
            rbsp_efw_phasef_read_wobble_free_var, time_range, probe=probe

            vcoro_var = prefix+'vcoro_mgse'
            vcoro_mgse = calc_vcoro(r_var=prefix+'r_mgse', probe=probe)
            store_data, vcoro_var, common_times, vcoro_mgse
            add_setting, vcoro_var, /smart, dictionary($
                'display_type', 'vector', $
                'unit', 'km/s', $
                'short_name', 'Coro V', $
                'coord', '', $
                'coord_labels', xyz)

            b_mgse = get_var_data(prefix+'b_mgse')
            v_mgse = get_var_data(prefix+'v_mgse')*1e-3
            vcoro_mgse = get_var_data(prefix+'vcoro_mgse')*1e-3

            ecoro_mgse = vec_cross(-vcoro_mgse,b_mgse)
            store_data, prefix+'ecoro_mgse', common_times, ecoro_mgse
            add_setting, prefix+'ecoro_mgse', /smart, dictionary($
                'display_type', 'vector', $
                'unit', 'mV/m', $
                'short_name', 'Coro E', $
                'coord', '', $
                'coord_labels', xyz)
            evxb_mgse = vec_cross(v_mgse,b_mgse)
            store_data, prefix+'evxb_mgse', common_times, evxb_mgse
            add_setting, prefix+'evxb_mgse', /smart, dictionary($
                'display_type', 'vector', $
                'unit', 'mV/m', $
                'short_name', 'VxB E', $
                'coord', '', $
                'coord_labels', xyz)

            u_mgse = v_mgse-vcoro_mgse
            emod_mgse = vec_cross(u_mgse,b_mgse)
            store_data, prefix+'emod_mgse', common_times, emod_mgse
            add_setting, prefix+'emod_mgse', /smart, dictionary($
                'display_type', 'vector', $
                'unit', 'mV/m', $
                'short_name', 'Model E', $
                'coord', '', $
                'coord_labels', xyz)
            e_mgse = get_var_data(prefix+'e_mgse')
            de_mgse = e_mgse-emod_mgse
            de_mgse[*,0] = 0

        ;---Remove eclipse.
            rbsp_read_eclipse_flag, time_range, probe=probe
            flag_var = prefix+'eclipse_flag'
            flags = get_var_data(flag_var, times=times)
            index = where(flags eq 1, count)
            fillval = !values.f_nan
            if count ne 0 then begin
                the_time_step = total(times[0:1]*[-1,1])
                time_ranges = time_to_range(times[index], time_step=the_time_step, pad_time=eclipse_pad_time)
                ntime_range = n_elements(time_ranges)*0.5
                for ii=0,ntime_range-1 do begin
                    index = where_pro(common_times,'[]',time_ranges[ii,*], count=count)
                    if count eq 0 then continue
                    de_mgse[index,*] = fillval
                endfor
            endif

            de_var = prefix+'de_mgse'
            store_data, de_var, common_times, de_mgse
            add_setting, de_var, /smart, dictionary($
                'display_type', 'vector', $
                'unit', 'mV/m', $
                'short_name', 'Raw dE', $
                'coord', '', $
                'coord_labels', xyz)
            for ii=1,2 do begin
                the_var = prefix+'de'+xyz[ii]+'_mgse'
                store_data, the_var, common_times, de_mgse[*,ii]
                add_setting, the_var, /smart, dictionary($
                    'display_type', 'scalar', $
                    'unit', 'mV/m', $
                    'short_name', 'Raw dE'+xyz[ii], $
                    'yrange', [-1,1]*de_threshold, $
                    'ystyle', 1 )
            endfor


        ;---Get perigee time ranges and loop over.
            index = where(snorm(get_var_data(prefix+'r_mgse')) le perigee_threshold)
            perigee_times = common_times[index]
            perigee_time_ranges = time_to_range(perigee_times, time_step=common_time_step)
            
;index = where(snorm(get_var_data(prefix+'r_mgse')) gt perigee_threshold)
;foreach var, prefix+['e','emod','de']+'_mgse' do begin
;    get_data, var, times, data
;    data[*,0] = !values.f_nan
;    data[index,*] = !values.f_nan
;    store_data, var, times, data
;endforeach
;
;stop

            nperigee = n_elements(perigee_time_ranges)*0.5
            for ii=0,nperigee-1 do begin
                perigee_time_range = reform(perigee_time_ranges[ii,*])
                index = where_pro(common_times, '[]', perigee_time_range, count=count)
                if count eq 0 then continue
                data = de_mgse[index,1:2]
                index = where(finite(snorm(data)), count)
                if count eq 0 then continue
                ;if max(snorm(data)) eq 0 then continue
                if max(abs(data),/nan) lt de_threshold then continue

                plot_dir = join_path([googledir(),'works','rbsp_phase_f','plot','large_perigee_residue'])
                plot_base = prefix+'perigee_'+strjoin(time_string(perigee_time_range,tformat='YYYY_MMDD_hhmm_ss'),'_')+'.pdf'
                plot_file = join_path([plot_dir,plot_base])
                if keyword_set(test) then plot_file = 0
                sgopen, plot_file, xsize=6, ysize=8, xchsz=xchsz, ychsz=ychsz
                tplot, prefix+['emod','e','de','evxb','ecoro']+'_mgse', trange=perigee_time_range, get_plot_position=poss
                tpos = poss[*,0]
                tx = tpos[0]
                ty = tpos[3]+ychsz*0.5
                xyouts, tx,ty,/normal, plot_base
                if keyword_set(test) then stop
                sgclose
            endfor
        endforeach
    endforeach

end
