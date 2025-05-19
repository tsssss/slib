;+
; Test to reduce residue of the perigee E field.
; Use B_measure and B_model to correct r_gsm.
;-


pro test_perigee_correction_change_adhoc, test_time, probe=probe


test = 1

;---Constant.
    secofday = constant('secofday')
    xyz = constant('xyz')

;---Settings.
    prefix = 'rbsp'+probe+'_'
    perigee_shell = 4.  ; Re.
    time_range = test_time+[0,secofday*2]
    plot_dir = join_path([googledir(),'works','rbsp_phase_f','plot','test_perigee_emgse_change_adhoc'])


;---Load basic data.
    rbsp_read_efield, time_range, probe=probe, resolution='hires'
    rbsp_read_orbit, time_range, probe=probe
    rbsp_read_sc_vel, time_range, probe=probe
    rbsp_read_bfield, time_range, probe=probe
    rbsp_read_quaternion, time_range, probe=probe


;---Get perigee times.
    r_var = prefix+'r_gsm'
    dis = snorm(get_var_data(r_var, times=orbit_times))
    perigee_times = orbit_times[where(dis le perigee_shell)]
    orbit_time_step = total(orbit_times[0:1]*[-1,1])
    perigee_time_ranges = time_to_range(perigee_times, time_step=orbit_time_step)
    nperigee_time_range = n_elements(perigee_time_ranges)*0.5
    if nperigee_time_range lt 1 then return
    id = 1
    the_time_range = reform(perigee_time_ranges[id,*])



;---Prepare data on common times.
    common_time_step = 1
    common_times = make_bins(time_range, common_time_step)
    ncommon_time = n_elements(common_times)
    foreach var, prefix+['v','r'] do begin
        var_in = var+'_gsm'
        get_data, var_in, times, data, limits=limits
        data = sinterpol(data, times, common_times, quadratic=1)
        var_out = var+'_mgse'
        data = cotran(data, common_times, 'gsm2mgse', probe=probe)
        store_data, var_out, common_times, data
        limits.coord = 'MGSE'
        add_setting, var_out, /smart, limits
    endforeach

    foreach var, prefix+['b','e'] do begin
        var_in = var+'_gsm'
        get_data, var_in, times, data, limits=limits
        data = sinterpol(data, times, common_times, quadratic=0)
        var_out = var+'_mgse'
        data = cotran(data, common_times, 'gsm2mgse', probe=probe)
        store_data, var_out, common_times, data
        limits.coord = 'MGSE'
        add_setting, var_out, /smart, limits
    endforeach
    rbsp_emfisis_remove_perigee_spike, prefix+'b_mgse'
    get_data, prefix+'b_mgse', times, b_mgse
    b_mgse = rbsp_remove_spintone(b_mgse, times)
    store_data, prefix+'b_mgse', times, b_mgse


;---Calculate dE.
    de_var = prefix+'de_mgse'
    rbsp_remove_efield_bg, e_var=prefix+'e_mgse', b_var=prefix+'b_mgse', $
        v_var=prefix+'v_mgse', r_var=prefix+'r_mgse', save_to=de_var, probe=probe
    de_mgse = get_var_data(de_var, times=times)
    de_mgse[*,0] = 0
    store_data, de_var, times, de_mgse
    add_setting, de_var, /smart, dictionary($
        'display_type', 'vector', $
        'unit', 'mV/m', $
        'short_name', 'dE', $
        'coord', 'MGSE', $
        'coord_labels', constant('xyz') )
        
        
        
    e_mgse = get_var_data(prefix+'e_mgse', times=times)
    evxb_mgse = get_var_data(prefix+'evxb_mgse')
    store_data, prefix+'ey_mgse', times, [[e_mgse[*,1]],[evxb_mgse[*,1]]], limits={$
        ytitle:'(mV/m)', labels:['Ey','Ey VxB'], colors:sgcolor(['blue','red'])}
    store_data, prefix+'ez_mgse', times, [[e_mgse[*,2]],[evxb_mgse[*,2]]], limits={$
        ytitle:'(mV/m)', labels:['Ez','Ez VxB'], colors:sgcolor(['blue','red'])}
    de_mgse = e_mgse-evxb_mgse
    ecoro_mgse = get_var_data(prefix+'ecoro_mgse')
    store_data, prefix+'dey_mgse', times, [[de_mgse[*,1]],[ecoro_mgse[*,1]]], limits={$
        ytitle:'(mV/m)', labels:['dEy','dEy Coro'], colors:sgcolor(['blue','red'])}
    store_data, prefix+'dez_mgse', times, [[de_mgse[*,2]],[ecoro_mgse[*,2]]], limits={$
        ytitle:'(mV/m)', labels:['dEz','dEz Coro'], colors:sgcolor(['blue','red'])}
        
    tplot_options, 'labflag', -1
    tplot, prefix+['ey','ez','dey','dez']+'_mgse'
    stop


;---Adhoc correction.
    smooth_window = 1*60.  ; sec.
    smooth_width = smooth_window/common_time_step
    index = where_pro(common_times,'[]', the_time_range)
    section_times = make_bins(time_range, smooth_window)
    nsection = n_elements(section_times)-1
    section_center_times = section_times[0:nsection-1]+smooth_window*0.5
    for ii=1,2 do begin
        e0 = e_mgse[*,ii]
        e1 = evxb_mgse[*,ii]

        ; This method has weird coef.
;        coef = fltarr(nsection)
;        for jj=0,nsection-1 do begin
;            index = where_pro(common_times, '[]', section_times[jj:jj+1])
;            fit_res = linfit(e1[index],e0[index])
;            coef[jj] = fit_res[1]
;        endfor
;        coef = interpol(coef, section_center_times, common_times, /quadratic)

        min_e = 10
        yshift = min_e-min(e1)
        coef = (e0+yshift)/(e1+yshift)
        coef = smooth(coef, smooth_width, /edge_zero)

        e1 = (e1+yshift)*coef-yshift
        de_mgse[*,ii] = e0-e1
        evxb_mgse[*,ii] = e1
    endfor
    store_data, prefix+'evxb_mgse', common_times, evxb_mgse

    de_var = prefix+'de_mgse'
    store_data, de_var, common_times, de_mgse


    plot_file = join_path([plot_dir,prefix+'emgse_perigee_'+$
        strjoin(time_string(the_time_range,tformat='YYYY_MMDD_hhmm'),'_')+'.pdf'])
    perigee_correction_plot1, the_time_range, probe=probe, plot_file=plot_file, test=test

end


probes = ['a','b']
years = ['2013','2014','2015','2016','2017']
months = ['03','06','09','12']
dates = []
foreach year, years do foreach month, months do dates = [dates, year+'-'+month+'-01']


;probes = ['a']
;dates = ['2013-07-21']

test_times = time_double(dates)
foreach probe, probes do foreach test_time, test_times do test_perigee_correction_change_adhoc, test_time, probe=probe
end
