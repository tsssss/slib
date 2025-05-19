;+
; Check if jumps in w_gse is related to eclipse.
;-

pro test_spice_jump_and_eclipse, day, probe=probe

;---Settings.
    secofday = constant('secofday')
    time_range = day+[0,secofday]
    prefix = 'rbsp'+probe+'_'
    common_time_step = 1d/16
    common_times = make_bins(time_range, common_time_step)
    xyz = constant('xyz')
    uvw = constant('uvw')
    ndim = 3
    plot_dir = join_path([googledir(),'works','rbsp_phase_f','plot','test_spice_jump_and_eclipse'])

end
