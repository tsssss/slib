;+
; To check if L1 esvy and L1 vsvy have time tag offset.
;-

time_range = time_double(['2012-11-01','2012-11-02'])
plot_time_range = time_double('2012-11-01/04:24')+[0,30]
plot_time_range = time_double('2012-11-01/05:30')+[0,15]
probe = 'a'

prefix = 'rbsp'+probe+'_'
xyz = constant('xyz')

rbsp_efw_read_l1, time_range, probe=probe, datatype='esvy'
rbsp_efw_read_l1, time_range, probe=probe, datatype='vsvy'
store_data, prefix+'efw_esvy', dlim={data_att:{units:'mV/m'}}
store_data, prefix+'efw_vsvy', dlim={data_att:{units:'V'}}
timespan, time_range[0], total(time_range*[-1,1]), /second
rbsp_efw_cal_waveform, probe=probe, datatype='esvy', trange=time_range
rbsp_efw_cal_waveform, probe=probe, datatype='vsvy', trange=time_range

cp0 = rbsp_efw_get_cal_params(time_range[0])
cp = (probe eq 'a')? cp0.a: cp0.b
boom_length = cp.boom_length

get_data, prefix+'efw_vsvy', times, vsvy
boom_len = [100,100,10]
eu = (vsvy[*,0]-vsvy[*,1])/boom_length[0]*1e3
ev = (vsvy[*,2]-vsvy[*,3])/boom_length[1]*1e3
ew = (vsvy[*,4]-vsvy[*,5])/boom_length[2]*1e3
store_data, prefix+'efw_esvy_16', times, [[eu],[ev],[ew]]

copy_data, prefix+'efw_esvy', prefix+'efw_esvy_32'
get_data, prefix+'efw_esvy_32', common_times
ntime = n_elements(common_times)
resolutions = ['16','32']

; Save data in terms of uvw.
uvw = constant('uvw')
ndim = 3
rgb = constant('rgb')
foreach res, resolutions do begin
    copy_data, prefix+'efw_esvy_'+res, prefix+'efw_esvy_'+res+'_copy'
    interp_time, prefix+'efw_esvy_'+res+'_copy', common_times
endforeach
for ii=0,ndim-1 do begin
    data = fltarr(ntime,n_elements(resolutions))
    foreach res, resolutions, res_id do begin
        data[*,res_id] = (get_var_data(prefix+'efw_esvy_'+res+'_copy'))[*,ii]
    endforeach
    store_data, prefix+'e'+uvw[ii], common_times, data, limits={$
        labels:resolutions, colors:rgb}
endfor

; Shift data according to the resolution.
foreach res, resolutions do begin
    get_data, prefix+'efw_esvy_'+res, times, data
    time_step = sdatarate(times)
    store_data, prefix+'efw_esvy_'+res+'_shift', times-time_step, data
    interp_time, prefix+'efw_esvy_'+res+'_shift', common_times
endforeach
for ii=0,ndim-1 do begin
    data = fltarr(ntime,n_elements(resolutions))
    foreach res, resolutions, res_id do begin
        data[*,res_id] = (get_var_data(prefix+'efw_esvy_'+res+'_shift'))[*,ii]
    endforeach
    store_data, prefix+'e'+uvw[ii]+'_shift', common_times, data, limits={$
        labels:resolutions, colors:rgb}
endfor

tplot_options, 'ynozero', 1
tplot_options, 'labflag', -1
tplot_options, 'version', 1

vars = prefix+['e'+uvw,'e'+uvw+'_shift']
sgopen, 0, xsize=10, ysize=8
nvar = n_elements(vars)
tpos = sgcalcpos(nvar,margins=[10,4,6,2])

foreach var, vars do begin
    data = get_var_data(var, in=plot_time_range, times=times)
    foreach res, resolutions, res_id do begin
        data[*,res_id] -= mean(data[*,res_id],/nan)
    endforeach
    store_data, var, times, data
endforeach

tplot, vars, position=tpos, trange=plot_time_range

end
