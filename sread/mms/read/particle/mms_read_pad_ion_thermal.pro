
function mms_read_pad_ion_thermal, input_time_range, id=datatype, probe=probe, species=species, $
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


    ; Load files.
    if n_elements(datatype) eq 0 then datatype = 'hpca'
    index = where(datatype eq ['hpca','fpi'], count)
    if count eq 0 then begin
        errmsg = 'Invalid datatype: '+datatype+' ...'
        return, retval
    endif
    
    routine = 'mms_read_pad_ion_thermal_'+datatype
    if n_elements(suffix) eq 0 then suffix = ''
    return, call_function(routine, input_time_range, probe=probe, species=species, $
        print_datatype=print_datatype, errmsg=errmsg, $
        local_files=files, file_times=file_times, version=version, $
        local_root=local_root, remote_root=remote_root, $
        return_request=return_request, get_name=get_name, update=update, suffix=suffix)


end


tr = ['2016-10-14/21:40','2016-10-14/22:00']
tr = ['2016-10-14/20:00','2016-10-14/22:30']
probe = '1'
tr = ['2015-09-01','2015-09-02']
probe = '1'
plot_time = time_double('2016-10-14/21:43:30')
ion_var1 = mms_read_pad_ion_thermal_fpi(tr, probe=probe, species='p')
ion_var2 = mms_read_pad_ion_thermal_hpca(tr, probe=probe, species='p')
stop
mms_load_hpca, probe=probe, trange=tr, datatype='ion', level='l2', data_rate='srvy'
mms_hpca_calc_anodes, fov=[0,360], probe=probe
stop
mms_part_slice2d, time=plot_time, probe=probe, species='hplus', data_rate='srvy', instrument='hpca', trange=tr
stop



;mms_load_fpi, probes=probe, datatype='des-moms', level='l2', data_rate='fast', trange=tr
;mms_load_fpi, probes=probe, datatype='des-dist', level='l2', data_rate='fast', trange=tr
;mms_part_getspec, energy=[2,32]*1e3, pitch=[0,180], probe=probe, output='energy pa', trange=tr, data_rate='fast', species='e', instrument='fpi'
;mms_part_getspec, energy=[2,32]*1e3, pitch=[0,180], probe=probe, output='energy pa', trange=tr, data_rate='fast', species='e', instrument='fpi'
;stop

tmp = plot_pad_polygon(ion_var, plot_times=plot_time, test=1, zrange=[1e5,5e7], color_table=49)
end