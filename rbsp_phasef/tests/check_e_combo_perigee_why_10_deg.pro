;+
; Check why there is a 10 deg offset.
;
; Conclusion: the sun2sensor values for E[13,14,23,24] are wrong.
;-


;---Input.
    test_day = time_double('2016-07-01')
    probe = 'a'
    test_file = join_path([homedir(),'test.cdf'])
    if file_test(test_file) eq 1 then file_delete, test_file
    dtime = 600.


;---Load all 6 combo of E spinfit, before E model is subtracted.
    ; Get the time range.
    time = test_day
    secofday = 86400d
    date = time-(time mod secofday)
    tr = date+[0,secofday]
    rbspx = 'rbsp'+probe
    prefix = 'rbsp'+probe+'_'
    timespan, tr[0], total(tr*[-1,1]), /seconds



;---Load spice products.
    load = 0
    var = prefix+'state_pos_gse'
    if check_if_update(var,tr, dtime=dtime) then load = 1
    if load then rbsp_load_spice_cdf_file, probe


;---Load E model.
    e_model_var = rbspx+'_emod_mgse'
    load = 0
    if check_if_update(e_model_var,tr, dtime=dtime) then load = 1
    if load then begin
        rbsp_load_emodel_cdf_file, probe
        ; Clear MGSE x.
        get_data, e_model_var, uts, data
        data[*,0] = 0
        store_data, e_model_var, uts, data
    endif


;---Load E[12,34].
    pairs = ['12','34']
    test_vars = prefix+'e_spinfit_mgse_v'+pairs
    load = 0
    foreach var, test_vars do begin
        if check_if_update(var,tr, dtime=dtime) then load = 1
    endforeach
    if load then begin
        ; Restore the calibrated E UVW data.
        rbsp_efw_phasef_read_e_uvw, tr, probe=probe
        spin_axis_var = rbspx+'_spinaxis_direction_gse'
        e_uvw_var = rbspx+'_e_uvw'
        ; Add UVW to dlim to tell spinfit the coord.
        data_att = {coord_sys:'uvw'}
        dlim = {data_att:data_att}
        store_data, e_uvw_var, dlimits=dlim

        spinfit_var = e_uvw_var+'_spinfit'
        foreach pair, pairs, pair_id do begin
            rbsp_spinfit, e_uvw_var, plane_dim=pair_id
            dsc_var = prefix+'e_spinfit_v'+pair+'_dsc'
            the_var = prefix+'e_spinfit_mgse_v'+pair

            ; Transform the spinfit data from DSC to MGSE (AARON'S UPDATED VERSION which is very fast and gives same result as old method)
            copy_data, spinfit_var, dsc_var
            ;tinterpol_mxn, spin_axis_var, dsc_var,/quadratic. This is done in rbsp_efw_dsc_to_mgse.
            rbsp_efw_dsc_to_mgse, probe, dsc_var, spin_axis_var
            mgse_var = dsc_var+'_mgse'
            copy_data, mgse_var, the_var

;            ; Need to add E model back to be consistent with E combo.
;            get_data, the_var, times, edata
;            emod = get_var_data(e_model_var, at=times)
;            store_data, the_var, times, edata+emod
        endforeach
    endif


;---Load E[12,34] force.
    test_vars = prefix+'e_spinfit_mgse_v'+pairs+'_force'
    load = 0
    foreach var, test_vars do begin
        if check_if_update(var,tr, dtime=dtime) then load = 1
    endforeach
load = 1
angle_offset = 10
    if load then begin
        sun2sensor_info = dictionary($
            'v12', -20d, $
            'v34', -110d )

        ; Restore the calibrated E UVW data.
        rbsp_efw_phasef_read_e_uvw, tr, probe=probe
        spin_axis_var = rbspx+'_spinaxis_direction_gse'
        e_uvw_var = rbspx+'_e_uvw'
        ; Add UVW to dlim to tell spinfit the coord.
        data_att = {coord_sys:'uvw'}
        dlim = {data_att:data_att}
        store_data, e_uvw_var, dlimits=dlim

        foreach pair, pairs, pair_id do begin
            sun2sensor = sun2sensor_info['v'+pair]+angle_offset

            rbsp_spinfit, e_uvw_var, plane_dim=0, sun2sensor=sun2sensor, force=1
            dsc_var = prefix+'e_spinfit_v'+pair+'_dsc'
            the_var = prefix+'e_spinfit_mgse_v'+pair+'_force'

            ; Transform the spinfit data from DSC to MGSE (AARON'S UPDATED VERSION which is very fast and gives same result as old method)
            copy_data, spinfit_var, dsc_var
            ;tinterpol_mxn, spin_axis_var, dsc_var,/quadratic. This is done in rbsp_efw_dsc_to_mgse.
            rbsp_efw_dsc_to_mgse, probe, dsc_var, spin_axis_var
            mgse_var = dsc_var+'_mgse'
            copy_data, mgse_var, the_var
        endforeach
        stop
    endif


end
