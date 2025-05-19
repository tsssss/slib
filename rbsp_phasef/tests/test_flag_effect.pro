;+
; Load spinfit E field and flag to check how much bad data are removed.
;-

probes = ['a','b']
years = make_bins([2012,2019],1)
test = 0

foreach year, years do begin
    foreach probe, probes do begin
        prefix = 'rbsp'+probe+'_'
        boom_pair = '12'
        if year ge 2015 and probe eq 'a' then boom_pair = '24'
        time_range = time_double(string(year+[0,1],format='(I4)'))
        if year eq 2012 then time_range = time_double(['2012-09-05','2013'])
        
    ;---Load data.
        e_var = prefix+'e_spinfit_mgse_v'+boom_pair
        if check_if_update(e_var, time_range) then begin
            rbsp_efw_phasef_read_spinfit_efield, time_range, probe=probe
        endif

        flag_var = prefix+'flag_25'
        if check_if_update(flag_var, time_range) then begin
            rbsp_efw_phasef_read_flag_25, time_range, probe=probe, boom_pair=boom_pair
        endif

        vsvy_var = prefix+'efw_vsvy'
        if check_if_update(vsvy_var, time_range) then begin
            rbsp_efw_phasef_read_vsvy, time_range, probe=probe
            get_data, vsvy_var, times, vsvy, limits=lim
            store_data, vsvy_var, times, vsvy[*,0:3], limits={$
                ytitle:'(V)', labels:'V'+['1','2','3','4'], $
                colors:sgcolor(['black','red','green','blue'])}
        endif

    ;---Save each flag on its own.
        all_flags = get_var_data(flag_var, times=times, limit=lim)
        foreach flag_name, lim.labels, flag_id do begin
            store_data, prefix+'flag_'+flag_name, times, all_flags[*,flag_id], $
                limits={labels:flag_name, yrange:[-0.2,1.2]}
        endforeach


    ;---Apply global flag.
        get_data, e_var, common_times, edata, limits=lim
        flags = (get_var_data(flag_var, at=common_times))[*,0] ne 0
        bad_times = common_times[time_to_range(where(flags eq 1),time_step=1)]
        nbad_time = n_elements(bad_times)*0.5
        pad_time = 5*60d
        fillval = !values.f_nan
        for bad_id=0,nbad_time-1 do begin
            index = where_pro(common_times, '[]', bad_times[bad_id,*]+[-1,1]*pad_time, count=count)
            if count eq 0 then continue
            edata[index,*] = fillval
        endfor
        store_data, e_var+'_flagged', common_times, edata, limits=lim
        store_data, prefix+'global_flag', common_times, flags, limits={yrange:[-0.2,1.2]}
    
    ;---Make a plot.
        vars = [e_var+['','_flagged'],prefix+['global_flag']]
        ofn = join_path([srootdir(),$
            'test_flag_effect_'+prefix+time_string(time_range[0],tformat='YYYY')+'.pdf'])
        if keyword_set(test) then ofn = 0
        sgopen, ofn, xsize=8, ysize=5
        tplot, vars, trange=time_range
        if keyword_set(test) then stop
        sgclose
    endforeach
endforeach

end
