

function mms_read_pad_ele_thermal, input_time_range, id=datatype, probe=probe, species=species, $
    print_datatype=print_datatype, errmsg=errmsg, $
    local_files=files, file_times=file_times, version=version, $
    local_root=local_root, remote_root=remote_root, $
    return_request=return_request, get_name=get_name, update=update, suffix=suffix


    compile_opt idl2
    on_error, 0
    errmsg = ''
    retval = ''


    if ~mms_probe_is_valid(probe) then begin
        errmsg = 'Invalid probe: '+probe+' ...'
        return, retval
    endif
    prefix = 'mms'+probe+'_'
    mission_probe = 'mms'+probe
    

    ; Prepare var name.
    species = 'e'
    if n_elements(suffix) eq 0 then suffix = ''
    var_info = prefix+species+'_pad_thermal'+suffix
    if keyword_set(get_name) then return, var_info
    if keyword_set(update) then del_data, var_info
    time_range = time_double(input_time_range)
    if ~check_if_update(var_info, time_range) then return, var_info

    ; Load files.
    files = mms_ld_fpi_pad_ele(time_range, probe=probe, errmsg=errmsg)
    if errmsg ne '' then return, retval


;---Read data.
    var_list = list()
    in_vars = [prefix+'pad_fpi_ele']
    out_vars = [prefix+'pad_ele_thermal']
    var_list.add, dictionary($
        'in_vars', in_vars, $
        'out_vars', out_vars, $
        'time_var_name', 'time', $
        'time_var_type', 'unix' )
    read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg
    if errmsg ne '' then return, ''

    pad_unit = (cdf_read_setting(in_vars[0], filename=files[0]))['UNITS']
    phi_var = prefix+'phi_centers'
    phi_centers = cdf_read_var(phi_var, filename=files[0])
    phi_unit = (cdf_read_setting(phi_var, filename=files[0]))['UNITS']
    pa_var = prefix+'pa_centers'
    pa_centers = cdf_read_var(pa_var, filename=files[0])
    pa_unit = (cdf_read_setting(pa_var, filename=files[0]))['UNITS']
    en_var = prefix+'en_centers'
    en_centers = cdf_read_var(en_var, filename=files[0])
    en_unit = (cdf_read_setting(en_var, filename=files[0]))['UNITS']

    pad3d_var = out_vars[0]
    pad3d_fluxs = get_var_data(pad3d_var, times=times)
    nphi = n_elements(phi_centers)
    pad_fluxs = total(pad3d_fluxs,2)/nphi
    pad_var = var_info

    ; Convert to #/cm^2-s-sr-keV.
    nen_center = n_elements(en_centers)
    for ii=0,nen_center-1 do begin
        pad_fluxs[*,*,ii] /= en_centers[ii]*1e-3
    endfor
    pad_unit = '#/cm!U2!N-s-sr-keV'

    store_data, pad_var, times, pad_fluxs
    add_setting, pad_var, dictionary($
        'requested_time_range', time_range, $
        'probe', probe, $
        'mission', 'mms', $
        'mission_probe', 'mms'+probe, $
        'display_type', 'pad', $
        'unit', pad_unit, $
        'species', species, $
        'pa_centers', pa_centers, $
        'pa_unit', pa_unit, $
        'en_centers', en_centers, $
        'en_unit', en_unit )
    
    return, var_info

end


tr = ['2016-10-14/21:40','2016-10-14/22:00']
tr = ['2016-10-14/20:00','2016-10-14/22:30']
;tr = ['2015-09-01/20:00','2015-09-01/22:30']
probe = '1'
ele_var = mms_read_pad_ele_thermal(tr, probe=probe)

plot_time = time_double('2016-10-14/21:43:30')

;mms_load_fpi, probes=probe, datatype='des-moms', level='l2', data_rate='fast', trange=tr
;mms_load_fpi, probes=probe, datatype='des-dist', level='l2', data_rate='fast', trange=tr
;mms_part_getspec, energy=[2,32]*1e3, pitch=[0,180], probe=probe, output='energy pa', trange=tr, data_rate='fast', species='e', instrument='fpi'
;mms_part_getspec, energy=[2,32]*1e3, pitch=[0,180], probe=probe, output='energy pa', trange=tr, data_rate='fast', species='e', instrument='fpi'
;stop

tmp = plot_pad_polygon(ele_var, plot_times=plot_time, test=1, zrange=[1e5,5e7], color_table=49)
end