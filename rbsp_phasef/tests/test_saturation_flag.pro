;+
; Find when V12 saturation is 0 but V3456 is 1
; Conclusion: V12 can be good when other booms are bad.
;-

probe = 'b'
time_range = rbsp_efw_phasef_get_valid_range('flags_all', probe=probe)
time_range = time_double(['2012-09-20','2013'])

prefix = 'rbsp'+probe+'_'
e_var = prefix+'e_spinfit_mgse_v12'
if check_if_update(e_var, time_range) then begin
    rbsp_efw_phasef_read_spinfit_efield, time_range, probe=probe
endif

flag_var = prefix+'flag_25'
if check_if_update(flag_var, time_range) then begin
    rbsp_efw_phasef_read_flag_25, time_range, probe=probe
endif

vsvy_var = prefix+'efw_vsvy'
if check_if_update(vsvy_var, time_range) then begin
    rbsp_efw_phasef_read_vsvy, time_range, probe=probe
    interp_time, vsvy_var, to=e_var
    get_data, vsvy_var, times, vsvy
    store_data, vsvy_var, times, vsvy[*,0:3], limits={$
        colors:sgcolor(['black','red','green','blue']), labels:'V'+['1','2','3','4']}
endif

tplot_options, 'labflag', -1
get_data, e_var, times
flags = get_var_data(flag_var, at=times) gt 0
flag_names = get_setting(flag_var, 'labels')
index = where(flag_names eq 'v1_saturation')
nboom = 6
flags_saturation = flags[*,index[0]+indgen(nboom)]

flag_12 = total(flags_saturation[*,0:1],2) gt 0
flag_all_booms = total(flags_saturation,2) gt 0
store_data, prefix+'flag_12', times, flag_12, limits=$
    {yrange:[-0.2,1.2], labels:'flag_12'}
store_data, prefix+'flag_all_booms', times, flag_all_booms, limits=$
    {yrange:[-0.2,1.2], labels:'flag_all_booms'}

fillval = !values.f_nan
foreach suffix, '_'+['12','all_booms'] do begin
    get_data, e_var, times, edata, limits=lim
    var = prefix+'flag'+suffix
    get_data, var, times, flag
    edata[where(flag eq 1),*] = fillval
    store_data, e_var+suffix, times, edata, limits=lim
endforeach

tplot, prefix+['flag_'+['12','all_booms'],'e_spinfit_mgse_v12_'+['12','all_booms'],'efw_vsvy']

end