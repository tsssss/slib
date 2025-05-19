;+
; v05 contains some minor modification to v04.
;-

pro rbsp_efw_phasef_gen_l3_v04_patch1, in_file=in_file, out_file=out_file

    on_error, 0
    errmsg = ''

;---Check input.
    if n_elements(in_file) eq 0 then begin
        errmsg = 'input file is not set ...'
        lprmsg, errmsg, log_file
        return
    endif
    if file_test(in_file) eq 0 then begin
        errmsg = 'input file does not exist ...'
        lprmsg, errmsg, log_file
        return
    endif

    msg = 'Processing '+in_file+' ...'
    lprmsg, msg, log_file

    base = file_basename(in_file)
    file = out_file
    file_copy, in_file, file, overwrite=1
    probe = strmid(base,4,1)

    prefix = 'rbsp'+probe+'_'
    rbspx = 'rbsp'+probe
    date = strmid(base,13,8)
    secofday = 86400d
    time_range = time_double(date,tformat='YYYYMMDD')+[0,secofday]

;---Remove unused labels.
    unused_labels = ['vsvy_vagv_LABL_1','vsvy_vavg_LABL_1','efw_qual_compno']
    foreach label, unused_labels do begin
        if ~cdf_has_var(label, filename=file) then continue
        cdf_del_var, label, filename=file
    endforeach

;---Add a global note.
    new_note = 'For precise estimates of the electric fields in low density plasmas, such as the plasma sheet, users should scale the spin plane electric field values up by a factor of 1.2. Inside the plasmasphere, the scaling factor is 1.0.'
    the_key = 'TEXT'
    gatt = cdf_read_setting(filename=file)
    if gatt.haskey(the_key) then begin
        text_arr = gatt[the_key]
    endif else text_arr = []
    index = where(stregex(text_arr, new_note) ne -1, count)
    if count eq 0 then text_arr = [text_arr,new_note]
    cdf_save_setting, the_key, text_arr, filename=file

;---Add orbit_num.
    orbit_var = 'orbit_num'
    if ~cdf_has_var(orbit_var, filename=file) then begin
        day = time_range[0]
        time_var = 'epoch'
        rbsp_efw_phasef_read_orbit_num, day, probe=probe
        the_var = prefix+orbit_var
        data = get_var_data(the_var, in=time_range, times=times)
        epochs = cdf_read_var(time_var, filename=file)
        common_times = convert_time(epochs, from='epoch16', to='unix')
        data = interpol(data, times, common_times)
        
        vatts = dictionary($
            'DEPEND_0', time_var, $
            'UNITS', '#', $
            'VAR_NOTES', 'Orbit number (change at perigee)' )
        cdf_save_var, orbit_var, value=data, filename=file, settings=vatts
    endif
    

;---For flags, add a note and change the wake_flag to sine_wave_fit_quality
    flag_var = 'global_flag'
    settings = dictionary('VAR_NOTES',$
        'Global flag, triggered as described at https://spdf.gsfc.nasa.gov/pub/data/rbsp/documents/efw/rbsp_efw_flag_descriptions.docx')
    cdf_save_setting, settings, varname=flag_var, filename=file
    
    flag_var = 'flags_all'
    vatt = cdf_read_setting(flag_var, filename=file)
    label_var = vatt['LABL_PTR_1']
    labels = cdf_read_var(label_var, filename=file)
    old_label = 'magnetic_wake'
    new_label = 'sine_wave_fit_quality'
    index = where(labels eq old_label)
    labels[index] = new_label
    cdf_save_data, label_var, value=labels, filename=file


;---Add unit to E field vars.
    vars = [$
        'VxB_efield_of_earth_mgse', $
        'efield_in_inertial_frame_spinfit_mgse', $
        'efield_in_corotation_frame_spinfit_mgse', $
        'efield_in_inertial_frame_spinfit_edotb_mgse', $
        'efield_in_corotation_frame_spinfit_edotb_mgse', $
        'VscxB_motional_efield_mgse']
    vatt = dictionary('UNITS', 'mV/m')
    foreach var, vars do begin
        cdf_save_setting, vatt, varname=var, filename=file
    endforeach
    stop

end


in_file = '/Volumes/data/rbsp/rbspa/l3_v04/2015/rbspa_efw-l3_20150215_v04.cdf'
file = join_path([homedir(),file_basename(in_file)])
rbsp_efw_phasef_gen_l3_v04_patch1, in_file=in_file, out_file=file
end