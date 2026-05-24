;+
; :Purpose: Check DMSP B field from cdaweb and madrigal (noaa is the same as madrigal).
;-


compile_opt idl2
time_range = ['2013-05-01','2013-05-01/12:00']
probe = 'f18'
test = 1


;---Load data from cdaweb.
    prefix = 'dmsp'+probe+'_'
    files = dmsp_load_ssm_cdaweb(time_range, probe=probe, id='l2')

    in_vars = ['DELTA_B_SC_ORIG','B_SC_OBS_ORIG']
    b_dmsp_xyz_cdaweb_var = prefix+'b_dmsp_xyz_cdaweb'
    db_dmsp_xyz_cdaweb_var = prefix+'db_dmsp_xyz_cdaweb'
    out_vars = [db_dmsp_xyz_cdaweb_var,b_dmsp_xyz_cdaweb_var]

    var_list = list()
    var_list.add, dictionary($
        'in_vars', in_vars, $
        'out_vars', out_vars, $
        'time_var_name', 'Epoch', $
        'time_var_type', 'epoch' )
    read_vars, time_range, files=files, var_list=var_list

    dmsp_xyz_coord = 'dmsp_xyz'
    foreach var, out_vars do begin
        vecs = var_get_data(var, times=times)
        vecs = vecs[*,[1,2,0]]      ; the original order is z, x, y.
        var = var_store(var, vecs, times)
        add_setting, var, $
            dictionary('coord',dmsp_xyz_coord), smart=1, id='bfield'
    endforeach

;---Load data from madrigal.
    db_dmsp_xyz_madrigal_var = dmsp_read_bfield_madrigal(time_range, probe=probe)

    plot_file = 0
    if keyword_set(test) then plot_file = 0
    fig_size = [8,6]
    sgopen, plot_file, size=fig_size
    plot_vars = [b_dmsp_xyz_cdaweb_var,db_dmsp_xyz_cdaweb_var,db_dmsp_xyz_madrigal_var]
    tplot, plot_vars, trange=time_range
    stop

end