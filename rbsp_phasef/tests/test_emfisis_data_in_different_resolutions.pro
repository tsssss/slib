date = '2012-12-25'
probe = 'b'


secofday = constant('secofday')
time_range = time_double(date[0])+[0,secofday]
prefix = 'rbsp'+probe+'_'
xyz = constant('xyz')
rgb = constant('rgb')

resolutions = ['hires','1sec','4sec']
foreach res, resolutions do begin
    rbsp_read_emfisis, time_range, id='l3%magnetometer', probe=probe, resolution=res, coord='gse', errmsg=errmsg
    copy_data, prefix+'b_gse', prefix+'b_gse_'+res
endforeach

tplot_options, 'labflag', -1
tplot_options, 'ynozero', 1

ndim = 3
get_data, prefix+'b_gse_1sec', common_times
ntime = n_elements(common_times)


; Save data in terms of xyz.
foreach res, resolutions do begin
    copy_data, prefix+'b_gse_'+res, prefix+'b_gse_'+res+'_copy'
    interp_time, prefix+'b_gse_'+res+'_copy', common_times
endforeach
for ii=0,ndim-1 do begin
    data = fltarr(ntime,n_elements(resolutions))
    foreach res, resolutions, res_id do begin
        data[*,res_id] = (get_var_data(prefix+'b_gse_'+res+'_copy'))[*,ii]
    endforeach
    store_data, prefix+'b'+xyz[ii]+'_gse', common_times, data, limits={$
        labels:resolutions, colors:rgb}
endfor

; Shift data according to the resolution.
foreach res, resolutions do begin
    get_data, prefix+'b_gse_'+res, times, data
    time_step = sdatarate(times)
    store_data, prefix+'b_gse_'+res+'_shift', times+time_step*0.5, data
    interp_time, prefix+'b_gse_'+res+'_shift', common_times
endforeach
for ii=0,ndim-1 do begin
    data = fltarr(ntime,n_elements(resolutions))
    foreach res, resolutions, res_id do begin
        data[*,res_id] = (get_var_data(prefix+'b_gse_'+res+'_shift'))[*,ii]
    endforeach
    store_data, prefix+'b'+xyz[ii]+'_gse_shift', common_times, data, limits={$
        labels:resolutions, colors:rgb}
endfor

vars = prefix+['b'+xyz+'_gse','b'+xyz+'_gse_shift']
sgopen, 0, xsize=10, ysize=8
nvar = n_elements(vars)
tpos = sgcalcpos(nvar,margins=[10,4,6,2])
plot_time_range = time_double('2012-12-25/08:54:20')+[0,30]
tplot, vars, position=tpos, trange=plot_time_range

end
