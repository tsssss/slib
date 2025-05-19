;+
; Test if e_mgse around perigee has oscillations at w and 2w.
;-


time_range = time_double(['2012-11-01','2012-11-02'])
plot_time_range = time_double('2012-11-01/05:55')+[0,40]
probe = 'a'

prefix = 'rbsp'+probe+'_'
xyz = constant('xyz')
uvw = constant('uvw')
rgb = constant('rgb')
ndim = 3

;rbsp_efw_read_e_mgse, time_range, probe=probe

vars = prefix+'e'+xyz+'_mgse'
stplot_split, prefix+'e_mgse', newnames=vars
options, vars, 'ytitle', 'RBSP-'+strupcase(probe)+'!C(mV/m)'
tplot_options, 'labflag', -1
tplot_options, 'version', 1

sgopen, 0, xsize=5, ysize=5

nvar = n_elements(vars)
tpos = sgcalcpos(nvar, margin=[10,4,8,2])
tplot, vars, trange=plot_time_range, position=tpos

end
