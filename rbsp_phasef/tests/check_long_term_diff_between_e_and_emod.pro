;+
; Check long term difference between e_mgse and emod_mgse around perigee.
;-

time_range = time_double(['2012-09-05','2014'])
time_range = time_double(['2016','2018'])
time_range = time_double(['2013','2014'])
probe = 'a'

rbsp_efw_phasef_read_wobble_free_var, time_range, probe=probe
rbsp_read_e_model, time_range, probe=probe
rbsp_efw_phasef_read_flag_25, time_range, probe=probe

prefix = 'rbsp'+probe+'_'
default_lim = {colors:constant('rgb')}
xyz = constant('xyz')

dif_data, prefix+'e_mgse', prefix+'emod_mgse', newname=prefix+'de_mgse'
store_data, prefix+'de_mgse', limits=default_lim

bps = ['12','34','13','14','23','24']
rbsp_efw_phasef_read_spinfit_efield, time_range, probe=probe
foreach var, prefix+'e_spinfit_mgse_v'+bps do begin
    interp_time, var, to=prefix+'emod_mgse'
endforeach



perigee_lshell = 2.5
dis = snorm(get_var_data(prefix+'r_mgse'))
index = where(dis ge perigee_lshell)
fillval = !values.f_nan
vars = prefix+['de_mgse','e_spinfit_mgse_v'+bps]
foreach var, vars do begin
    get_data, var, times, de_mgse
    de_mgse[*,0] = 0
    de_mgse[index,*] = fillval
    store_data, var, times, de_mgse
endforeach


flags = (get_var_data(prefix+'flag_25', times=uts))[*,0]
flags = interp(flags, uts, times)
index = where(flags ne 0)
foreach var, vars do begin
    get_data, var, times, de_mgse
    de_mgse[*,0] = 0
    de_mgse[index,*] = fillval
    store_data, var, times, de_mgse
endforeach

stplot_split, prefix+'de_mgse', newname=prefix+'de_mgse_'+xyz, labels=xyz
vars = prefix+['de_mgse','e_spinfit_mgse_v'+bps]
ylim, vars, [-1,1]*5
tplot, vars, trange=time_range

end