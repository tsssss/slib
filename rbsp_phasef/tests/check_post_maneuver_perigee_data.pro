;+
; Load maneuver times over the mission and plot 1 days of data after each maneuver.
;-

pro check_post_maneuver_perigee_data, probe=probe

test = 0
    prefix = 'rbsp'+probe+'_'
    plot_dir = join_path([homedir(),'check_post_maneuver_perigee_data'])

    start_time = '2012-09-08/00:00'
    end_time = (probe eq 'a')? '2019-10-14/24:00': '2019-07-16/24:00'
    mission_time_range = time_double([start_time,end_time])
    maneuver_time_ranges = rbsp_read_maneuver_time(mission_time_range, probe=probe)
    nmaneuver = n_elements(maneuver_time_ranges)*0.5
    for maneuver_id=0,nmaneuver-1 do begin
        maneuver_time_range = reform(maneuver_time_ranges[maneuver_id,*])
        data_time_range = maneuver_time_range+[-0.5,2.5]*86400d

        rbsp_efw_phasef_read_wobble_free_var, data_time_range, probe=probe
        rbsp_read_e_model, data_time_range, probe=probe, datatype='e_model_related'

        get_data, prefix+'b_mgse', times, b_mgse, limits=lim
        time_step = total(times[0:1]*[-1,1])
        smooth_width = 600/time_step
        for ii=0,2 do begin
            b_mgse[*,ii] -= smooth(b_mgse[*,ii],smooth_width,/edge_zero,/nan)
        endfor
        store_data, prefix+'db_mgse', times, b_mgse, limits=lim
        ylim, prefix+'db_mgse', [-1,1]*20

        e_mgse = get_var_data(prefix+'e_mgse', times=times, limits=lim)
        de_mgse = e_mgse-get_var_data(prefix+'emod_mgse', at=times)
        de_mgse[*,0] = !values.f_nan
        index = where(finite(e_mgse[*,0],/nan), count)
        if count ne 0 then de_mgse[index,*] = !values.f_nan
        store_data, prefix+'de_mgse', times, de_mgse, limits=lim
        options, prefix+'de_mgse', 'yrange', [-1,1]*8


        plot_file = join_path([plot_dir,prefix+'maneuver_'+strjoin(time_string(maneuver_time_range,tformat='YYYY_MMDD_hhmm'),'_')+'.pdf'])
        if keyword_set(test) then plot_file = 0
        sgopen, plot_file, xsize=10, ysize=6, xchsz=xchsz, ychsz=ychsz

        duration = total(maneuver_time_range*[-1,1])/3600.
        msg = 'Maneuver '+string(maneuver_id+1,format='(I0)')+$
            ', duration (hr): '+string(duration,format='(F6.2)')
        if maneuver_id ge 1 then begin
            dtime = (maneuver_time_ranges[maneuver_id,0]-maneuver_time_ranges[maneuver_id-1,1])/86400d
            msg += ', previous maneuver is (day): '+string(dtime,format='(F6.2)')
        endif
        tplot, prefix+[['db','de']+'_mgse','r_mgse'], trange=data_time_range, get_plot_position=poss
        timebar, maneuver_time_ranges, color=sgcolor('purple')
        tpos = poss[*,0]
        tx = tpos[0]
        ty = tpos[3]+ychsz*0.5
        xyouts, tx,ty,/normal, msg

        if keyword_set(test) then stop
        sgclose
    endfor

end


log_file = join_path([homedir(),'rbsp_maneuver_list.txt'])
ftouch, log_file

tab = '    '
msg = 'Probe          Maneuver start and end time                Duration (hr)      dT (day)'
lprmsg, msg, log_file

foreach probe, ['a','b'] do begin
    start_time = '2012-09-08/00:00'
    end_time = (probe eq 'a')? '2019-10-14/24:00': '2019-07-16/24:00'
    mission_time_range = time_double([start_time,end_time])
    maneuver_time_ranges = rbsp_read_maneuver_time(mission_time_range, probe=probe)
    nmaneuver = n_elements(maneuver_time_ranges)*0.5

    if probe eq 'b' then lprmsg, '', log_file
    for maneuver_id=0,nmaneuver-1 do begin
        maneuver_time_range = reform(maneuver_time_ranges[maneuver_id,*])
        msg = 'RBSP-'+strupcase(probe)
        msg += tab+strjoin(time_string(maneuver_time_range,tformat='YYYY-MM-DD/hh:mm:ss'),tab)
        msg += tab+tab+string(total(maneuver_time_range*[-1,1])/3600,format='(F8.3)')
        if maneuver_id eq 0 then begin
            dtime = 0
        endif else begin
            dtime = (maneuver_time_ranges[maneuver_id,0]-maneuver_time_ranges[maneuver_id-1,1])/86400d
        endelse
        msg += tab+tab+string(dtime,format='(F6.2)')
        lprmsg, msg, log_file
    endfor
endforeach

stop
check_post_maneuver_perigee_data, probe='b'
end
