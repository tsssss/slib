;+
; Check what's happening right after maneuver.
;-

time_range = time_double(['2013-03-15','2013-03-16'])
time_range = time_double(['2015-03-13','2015-03-14'])
;time_range = time_double(['2013-03-14','2013-03-15'])
tr = time_double(['2013-03-14/19:35','2013-03-14/20:10'])

;time_range = time_double(['2013-05-14','2013-05-15'])
probe = 'b'
default_lim = {colors:constant('rgb')}
xyz = constant('xyz')
ndim = 3

;rbsp_efw_phasef_read_b_mgse, time_range, probe=probe
;rbsp_efw_read_e_mgse, time_range, probe=probe
rbsp_read_spice_var, time_range, probe=probe
rbsp_read_e_model, time_range, probe=probe, id='e_model_related'
rbsp_efw_phasef_read_wobble_free_var, time_range, probe=probe

prefix = 'rbsp'+probe+'_'
get_data, prefix+'emod_mgse', common_times, emod_mgse
rename_var, prefix+'e_mgse', to=prefix+'e0_mgse'    ; rename the orig E.
rbsp_efw_calc_edotb_to_zero, prefix+'e0_mgse', prefix+'b_mgse', $
    newname=prefix+'e_mgse', no_preprocess=1        ; calc new E with non-0 Ex.


vars = prefix+['b_mgse','e_mgse','emod_mgse','wsc_gse']
foreach var, vars do stplot_split, var, newname=var+'_'+xyz
for ii=0,ndim-1 do begin
    stplot_merge, prefix+['e','emod']+'_mgse_'+xyz[ii], newname=prefix+'e'+xyz[ii], $
        colors=sgcolor(['red','blue']), labels=['E','Emod']
endfor

tplot_options, 'ynozero', 1
tplot_options, 'labflag', -1

dif_data, prefix+'e_mgse', prefix+'emod_mgse', newname=prefix+'de_mgse'
store_data, prefix+'de_mgse', limits=default_lim

get_data, prefix+'e_mgse', times, e_mgse
store_data, prefix+'e_mag', times, snorm(e_mgse)
get_data, prefix+'emod_mgse', times, emod_mgse
store_data, prefix+'emod_mag', times, snorm(emod_mgse)
stplot_merge, prefix+['e','emod']+'_mag', newname=prefix+'emag', $
    colors=sgcolor(['red','blue']), labels=['E','Emod']
dif_data, prefix+'e_mag', prefix+'emod_mag', newname=prefix+'de_mag'
store_data, prefix+'e_angle', times, sang(e_mgse,emod_mgse,deg=1)

tplot, prefix+['de_mgse','e'+xyz,'emag','de_mag','e_angle']
stop


; Fix the diff b/w E and E_model.
emod_mgse = get_var_data(prefix+'emod_mgse')
e_mgse = get_var_data(prefix+'e_mgse')
e_mag = snorm(e_mgse)
dis = snorm(get_var_data(prefix+'r_mgse'))
perigee_lshell = 2.5
fit_index = where(dis le perigee_lshell and finite(e_mag))

;    emod_mgse = emod_mgse[fit_index,*]
;    e_mgse = e_mgse[fit_index,*]
;    emod_mag = snorm(emod_mgse)
;    e_mag = snorm(e_mgse)
;    res = linfit(e_mag,emod_mag)
;    alpha = 1/res[1]
;    
;    yy = total(emod_mgse/alpha-e_mgse,2)
;    xx = [$
;        [e_mgse[*,1]-e_mgse[*,2]],$tlimit
;        
;        [e_mgse[*,2]-e_mgse[*,0]],$
;        [e_mgse[*,0]-e_mgse[*,1]]]
;    res = regress(transpose(xx),yy, sigma=sigma, const=const)
;    
;    ntime = n_elements(common_times)
;    omega = res ## (fltarr(ntime)+1)
;    e_mgse = get_var_data(prefix+'e0_mgse')
;    emod_mgse = get_var_data(prefix+'emod_mgse')
;    e_mgse[*,0] = emod_mgse[*,0]
;    efit_mgse = alpha*e_mgse+vec_cross(omega, e_mgse)
;    de_mgse = efit_mgse-emod_mgse
;    de_mgse[*,0] = 0
;    store_data, prefix+'de2_mgse', common_times, de_mgse, limits=default_lim


    emod_mgse = emod_mgse[fit_index,*]
    e_mgse = e_mgse[fit_index,*]
    de_mgse = e_mgse-emod_mgse
    yy = total(de_mgse,2)
    xx = [$
        [emod_mgse[*,1]-emod_mgse[*,2]],$
        [emod_mgse[*,2]-emod_mgse[*,0]],$
        [emod_mgse[*,0]-emod_mgse[*,1]]]
    res = regress(transpose(xx),yy, sigma=sigma, const=const)
    
    sgopen
    plot, yy, noerase=1
    ey_fit = reform(transpose(xx) ## res)+const
    oplot, ey_fit, color=sgcolor('red')
stop
    
    ntime = n_elements(common_times)
    omega = res ## (fltarr(ntime)+1)
    e_mgse = get_var_data(prefix+'e0_mgse')
    emod_mgse = get_var_data(prefix+'emod_mgse')
    efit_mgse = vec_cross(omega, emod_mgse)
    de_mgse = e_mgse-emod_mgse+efit_mgse
    de_mgse[*,0] = 0
    store_data, prefix+'de2_mgse', common_times, de_mgse, limits=default_lim
    tplot, prefix+['de*mgse'], trange=time_range
stop


end
