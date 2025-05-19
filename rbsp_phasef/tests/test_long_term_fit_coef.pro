;+
; Test if dE = E-E_model correlates with E_coro
;-

    
function rbsp_fit_perigee_coef, time_range, probe=probe


    prefix = 'rbsp'+probe+'_'
    fillval = !values.f_nan
    xyz = constant('xyz')


;---Read data and uniform time.
    rbsp_read_e_model, time_range, probe=probe, datatype='e_model_related'
    rbsp_efw_phasef_read_wobble_free_var, time_range, probe=probe

    get_data, prefix+'emod_mgse', common_times
    ncommon_time = n_elements(common_times)
    foreach var, prefix+['e','b','r','v']+'_mgse' do interp_time, var, common_times


;---Calculate dE = E-E_model
    e_mgse = get_var_data(prefix+'e_mgse')
    emod_mgse = get_var_data(prefix+'emod_mgse')
    de_mgse = e_mgse-emod_mgse
    fit_index = [1,2]
    foreach ii, fit_index do begin
        the_var = prefix+'de'+xyz[ii]
        store_data, the_var, common_times, de_mgse[*,ii]
        add_setting, the_var, /smart, dictionary($
            'display_type', 'scalar', $
            'constant', 0, $
            'yrange', [-1,1]*10, $
            'ytickv', [-2,-1,0,1,2]*4, $
            'yticks', 4, $
            'yminor', 4, $
            'unit', 'mV/m', $
            'short_name', 'MGSE dE'+xyz[ii] )
    endforeach


;---Remove eclipse and only keep data around perigee.
    pad_time = 300. ; sec.
    rbsp_read_eclipse_flag, time_range, probe=probe
    flag_var = prefix+'eclipse_flag'
    flags = get_var_data(flag_var, times=times)
    index = where(flags eq 1, count)
    if count ne 0 then begin
        the_time_step = total(times[0:1]*[-1,1])
        time_ranges = time_to_range(times[index], time_step=the_time_step, pad_time=pad_time)
        ntime_range = n_elements(time_ranges)*0.5
        for ii=0,ntime_range-1 do begin
            index = where_pro(common_times,'[]',time_ranges[ii,*], count=count)
            if count eq 0 then continue
            de_mgse[index,*] = fillval
        endfor
        store_data, prefix+'de_mgse', common_times, de_mgse
    endif

    ; Only keep perigee.
    r_mgse = get_var_data(prefix+'r_mgse')
    dis = snorm(r_mgse)
    perigee_shell = 2.2
    perigee_index = where(dis le perigee_shell, nperigee_time)
    if nperigee_time ne 0 then begin
        de_mgse[perigee_index,*] = fillval
        store_data, prefix+'de_mgse', common_times, de_mgse
    endif


;---Fit per perigee.
    b_mgse = get_var_data(prefix+'b_mgse')
    v_mgse = get_var_data(prefix+'v_mgse')
    vcoro_mgse = get_var_data(prefix+'vcoro_mgse')
    u_mgse = (v_mgse-vcoro_mgse)*1e-3


    ; Data as input for linear regression.
    ndim = 3
    yys = de_mgse
    xxs = fltarr(ndim,ncommon_time,ndim)
    ; For Ey.
    xxs[0,*,1] =  u_mgse[*,0]*b_mgse[*,1]
    xxs[1,*,1] = -u_mgse[*,0]*b_mgse[*,0]-u_mgse[*,2]*b_mgse[*,2]
    xxs[2,*,1] =  u_mgse[*,2]*b_mgse[*,1]
    ; For Ez.
    xxs[0,*,2] =  u_mgse[*,0]*b_mgse[*,2]
    xxs[1,*,2] =  u_mgse[*,1]*b_mgse[*,0]
    xxs[2,*,2] = -u_mgse[*,0]*b_mgse[*,0]-u_mgse[*,1]*b_mgse[*,1]


    fit_coef = fltarr(ndim+1,ndim)+fillval
    foreach ii, fit_index do begin
        yy = yys[*,ii]
        index = where(finite(yy), count)
        if count lt 10 then continue

        xx = xxs[*,*,ii]
        res = regress(xx[*,index],yy[index], sigma=sigma, const=const)
        fit_coef[*,ii] = [res[*],const]
    endforeach


    return, fit_coef

end


time_range = time_double(['2013-01-01','2019-01-01'])
days = make_bins(time_range,86400)
nday = n_elements(days)
ndim = 3
xyz = constant('xyz')

foreach probe, ['a','b'] do begin
    prefix = 'rbsp'+probe+'_'

    fit_coefs = fltarr(nday,ndim+1,ndim)
    foreach day, days, ii do begin
        fit_coefs[ii,*,*] = rbsp_fit_perigee_coef(day+[0,86400], probe=probe)
    endforeach
    
    for ii=1,2 do begin
        store_data, prefix+'fit_coef_'+xyz[ii], days, fit_coefs[*,*,ii], limits={$
            colors:sgcolor(['red','green','blue','black']), labels:['x','y','z','c']}
    endfor
    
    file = join_path([homedir(),prefix+'efw_perigee_fit_coef.tplot'])
    vars = prefix+'fit_coef_'+xyz[1:2]
    tplot_save, vars, filename=file
endforeach

end