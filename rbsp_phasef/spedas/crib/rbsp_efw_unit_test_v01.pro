;+
; Unit test for all spedas routines.
;-


time_range = ['2013-06-07/00:30','2013-06-07/08:30']
time_range = ['2014-01-06','2014-01-07']
probe = 'b'


mission_probe = 'rbsp'+probe
prefix = 'rbsp'+probe+'_'
prefix2 = prefix+'efw_'


; Load level 3 data.
rbsp_efw_read_l3, time_range, probe=probe

bo_var = prefix2+'angle_spinplane_Bo'
; rbsp_efw_phasef_read_angle_spinplane_bo, rbsp_efw_phasef_gen_l3_v04
bo = cos(get_var_data(bo_var, times=times)*constant('rad'))
by_mgse = bo[*,0]
bz_mgse = bo[*,1]
bx_mgse = sqrt(1-by_mgse^2-bz_mgse^2)
by_angle = tan(bx_mgse/by_mgse)*constant('deg')
by_angle_var = prefix2+'by_angle'
store_data, by_angle_var, times, by_angle, limits={ytitle:'(deg)',constant:[-1,1]*15, yrange:[-1,1]*90}
bz_angle = tan(bx_mgse/bz_mgse)*constant('deg')
bz_angle_var = prefix2+'bz_angle'
store_data, bz_angle_var, times, bz_angle, limits={ytitle:'(deg)',constant:[-1,1]*15, yrange:[-1,1]*90}
stop



; Load burst data time and rate.
foreach datatype, ['vb1','mscb1'] do begin
    var = lets_read_this(time_range, probe=mission_probe, func='rbsp_efw_phasef_read_b1_time_rate', datatype=datatype)
    if check_if_update(var, time_range) then message, 'Something is wrong ...'
endforeach

; Load burst data.



print, 'Everything works :)'
end