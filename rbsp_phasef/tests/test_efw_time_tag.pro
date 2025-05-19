
time_range = time_double('2014-01-10/20:10')+[0,120]
;time_range = time_double('2013-06-07/05:00')+[0,10]
probe = 'a'

rbsp_efw_read_burst_efield, time_range, probe=probe, datatype='vb1'
rbsp_efw_read_l2, time_range, probe=probe, datatype='vsvy-hires'
; Test for the corrected vsvy.
; Should align without further shift.
; rbsp_efw_phasef_read_vsvy, time_range, probe=probe

prefix = 'rbsp'+probe+'_'
vars = prefix+'efw_'+['vsvy','vb1']
boom_id = 4
boom_str = string(boom_id+1,format='(I0)')
foreach var, vars do begin
    get_data, var, times, data
    the_var = var+'_v'+boom_str
    store_data, the_var, times, data[*,boom_id]
    time_step = sdatarate(times)
    store_data, the_var+'_shift', times-time_step, data[*,boom_id]
endforeach

vars = prefix+'efw_'+['vsvy','vb1']+'_v'+boom_str
vars = [vars,vars+'_shift']
options, prefix+'efw_vsvy_v'+string(boom_id,format='(I0)')+['','_shift'], 'psym', -1
sgopen, 0, xsize=8, ysize=5
poss = sgcalcpos(n_elements(vars),2, xpad=15, margins=[15,4,3,2])

tplot_options, 'version', 1
options, vars[[0,2]], 'psym', -1

plot_time_range = time_double('2014-01-10/20:10')+[5,6.5]
tpos = reform(poss[*,0,*])
tplot, vars, trange=plot_time_range, position=tpos, noerase=1
data = get_var_data(vars[-1], in=plot_time_range, times=times)
the_time = times[where(data eq min(data))]
timebar, the_time, color=sgcolor('red')

plot_time_range = time_double('2014-01-10/20:10')+[5,6.5]+5.5
tpos = reform(poss[*,1,*])
tplot, vars, trange=plot_time_range, position=tpos, noerase=1
data = get_var_data(vars[-1], in=plot_time_range, times=times)
the_time = times[where(data eq min(data))]
timebar, the_time, color=sgcolor('red')

;tplot, vars, trange=time_range, noerase=1

end
