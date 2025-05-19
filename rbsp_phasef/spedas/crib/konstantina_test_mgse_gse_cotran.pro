
; Aaron's example rbsp_data_test.
time_range = ['2015-03-17','2015-03-18']
probes = ['a','b']

foreach probe, probes do begin
    mission_probe = 'rbsp'+probe
    prefix = 'rbsp'+probe+'_'

    rbsp_efw_read_l3, time_range, probe=probe
    var_in = prefix+'efw_efield_in_corotation_frame_spinfit_edotb_mgse'
    var_out = streplace(var_in, 'mgse', 'gse')
    rbsp_efw_read_spice_var, time_range, probe=probe
    q_var = prefix+'q_uvw2gse'
    e_mgse = get_var_data(var_in, times=times)
    e_gse = cotran_pro(e_mgse, times, coord_msg=['rbsp_mgse','gse'], probe=probe, mission='rbsp')
    store_data, var_out, times, e_gse
    add_setting, var_out, smart=1, dictionary($
        'display_type', 'vector', $
        'short_name', 'E', $
        'coord', 'gse', $
        'unit', 'mV/m' )
    split_vec, var_out

    get_data,prefix+'efw_spinaxis_gse',data=wgse
    rbsp_mgse2gse,prefix+'efw_efield_in_corotation_frame_spinfit_edotb_mgse', no_spice_load=0

    split_vec,prefix+'efw_efield_in_corotation_frame_spinfit_edotb_mgse_gse'
    split_vec,'flags_all'

    vars = prefix+'efw_efield_in_corotation_frame_spinfit_edotb_gse_'+['x','y','z']
    foreach var, vars do begin
        get_data, var, times, data
        window = 60
        data_rate = sdatarate(times)
        width = window/data_rate
        data = smooth(data, width, nan=1)
        store_data, var, times, data
    endforeach
    ylim,prefix+'efw_efield_in_corotation_frame_spinfit_edotb_gse_x',-6,6
    ylim,prefix+'efw_efield_in_corotation_frame_spinfit_edotb_gse_y',-5,10
    ylim,prefix+'efw_efield_in_corotation_frame_spinfit_edotb_gse_z',-15,20
    ylim,prefix+'efw_efield_in_corotation_frame_spinfit_edotb_mgse_gse_x',-6,6
    ylim,prefix+'efw_efield_in_corotation_frame_spinfit_edotb_mgse_gse_y',-5,10
    ylim,prefix+'efw_efield_in_corotation_frame_spinfit_edotb_mgse_gse_z',-15,20
    sgopen, 0, size=[6,8]
    tplot,[prefix+'efw_efield_in_corotation_frame_spinfit_edotb_*_'+['x','y','z']]
endforeach

vars = []
fig_labels = []
foreach probe, probes do begin
    prefix = 'rbsp'+probe+'_'
    vars = [vars, prefix+'efw_efield_in_corotation_frame_spinfit_edotb_gse_'+['x','y','z']]  
    fig_labels = [fig_labels,strupcase('rbsp-'+probe)+' E'+['x','y','z']]  
endforeach

test = 1
plot_file = join_path([srootdir(),'konstantina_test_mgse_gse_plot1.pdf'])
if keyword_set(test) then plot_file = 0
sgopen, plot_file, size=[6,8], xchsz=xchsz, ychsz=ychsz
tplot, vars, trange=time_range, get_plot_position=poss
foreach var, vars, pid do begin
    tpos = poss[*,pid]
    tx = tpos[0]-xchsz*10
    ty = tpos[3]-ychsz*0.7
    msg = fig_labels[pid]
    xyouts, tx,ty, msg, normal=1
endforeach
if keyword_set(test) then stop
sgclose

file = join_path([srootdir(),'konstantina_test_mgse_gse_data.cdf'])
stplot2cdf, vars, filename=file




stop
end