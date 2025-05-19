
time_range = time_double(['2012-11-01','2012-11-02'])
plot_time_range = time_double(['2012-11-01/04:24','2012-11-01/04:25'])
probe = 'a'

prefix = 'rbsp'+probe+'_'
rbsp_read_emfisis, time_range, probe=probe, id='l2%magnetometer'
get_data, prefix+'b_uvw', times, b_uvw
b_mgse = cotran(b_uvw, times, 'uvw2mgse', probe=probe)
store_data, prefix+'b_mgse', times, b_mgse
xyz = constant('xyz')
stplot_split, prefix+'b_mgse', newnames=prefix+'b'+xyz+'_mgse'

tplot_options, 'ynozero', 1
tplot_options, 'labflag', -1
tplot_options, 'version', 1

sgopen, 0, xsize=5, ysize=4
vars = prefix+'b'+xyz+'_mgse'
options, vars, 'ytitle', 'RBSP-'+strupcase(probe)+'!C(nT)'
tplot, vars, trange=plot_time_range

end
