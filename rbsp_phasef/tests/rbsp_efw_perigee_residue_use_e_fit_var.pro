
time_range = time_double(['2012-09','2019-09'])
probes = ['a','b']
foreach probe, probes do begin
    prefix = 'rbsp'+probe+'_'

    rbsp_efw_phasef_read_e_fit_var, time_range, probe=probe

    e_mgse = get_var_data(prefix+'edotb_mgse', limits=lim)
    emod_mgse = get_var_data(prefix+'emod_mgse', times=times)
    store_data, prefix+'e_emod_angle', times, sang(e_mgse,emod_mgse,/deg)

    var = prefix+'e1_mgse'
    dif_data, prefix+'e_mgse', prefix+'emod_mgse', newname=var
    get_data, var, times, e1_mgse
    e1_mgse[*,0] = 0
    store_data, var, times, e1_mgse, limits=lim
    xyz = constant('xyz')
    vars = var+'_'+xyz
    stplot_split, var, newnames=vars, labels='MGSE E!D'+xyz
    ylim, vars[1:2], [-1,1]*6
    options, vars, 'ytitle', 'RBSP-'+strupcase(probe)+'!C(mV/m)'
endforeach

ofn = join_path([srootdir(),'rbsp_efw_perigee_residue_use_e_fit_var.pdf'])
sgopen, ofn, xsize=10, ysize=5
vars = ['rbspa_e1_mgse_'+xyz[1:2],'rbspb_e1_mgse_'+xyz[1:2]]
tplot, vars, trange=time_range
sgclose

sgopen, 0, xsize=10, ysize=5
vars = ['rbspa_e1_mgse_'+xyz[1:2],'rbspb_e1_mgse_'+xyz[1:2]]
tplot, vars, trange=time_range

end