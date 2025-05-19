;+
; Check RBSP V4 after 2019-02-23.
;-

time_range = time_double(['2019-02-22','2019-10-13'])
probe = 'a'
boom_index = 3

prefix = 'rbsp'+probe+'_'
secofday = 86400d
days = make_bins(time_range, secofday)

time_step = 1d
times = make_bins(time_range, time_step)
ntime = n_elements(times)
v4s = fltarr(ntime)
foreach day, days do begin
    day_time_range = day+[0,secofday]
    time_index = where_pro(times, '[]', day_time_range, count=count)
    if count le 1 then continue
    rbsp_read_efw, day_time_range, probe=probe, id='l1%vsvy'
    the_times = times[time_index]
    get_data, 'vsvy', uts, vsvy
    v4s[time_index] = (get_var_data('vsvy', at=the_times))[*,boom_index]
endforeach

var = prefix+'v4'
store_data, var, times, v4s*0.01, limits={ytitle:'V4 (V)', labels:'RBSP-A V4'}
tplot_options, 'labflag', -1
ylim, var, [-1,1]*5

sgopen, join_path([srootdir(),'check_rbspa_v4.pdf']), xsize=5, ysize=3
tplot, var, trange=time_range
sgclose

end
