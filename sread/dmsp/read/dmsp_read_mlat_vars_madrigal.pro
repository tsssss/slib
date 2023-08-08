;+
; Read DMSP orbit. mlat, mlon, mlt. ssm and ssj are the same. But madrigal is different from cdaweb...
;-

function dmsp_read_mlat_vars_madrigal, input_time_range, probe=probe, errmsg=errmsg, coord=coord, get_name=get_namem, suffix=suffix, _extra=ex

    prefix = 'dmsp'+probe+'_'
    errmsg = ''
    retval = ''

    if n_elements(suffix) eq 0 then suffix = '_madrigal'
    vars = prefix+['mlat','mlt','mlon']+suffix
    if keyword_set(get_name) then return, vars

    time_range = time_double(input_time_range)
    if ~check_if_update(vars[0], time_range) then return, vars

    files = dmsp_load_ssj_madrigal(time_range, probe=probe, errmsg=errmsg)
    if errmsg ne '' then return, retval

;---Read data.
    mlat_var = '/Data/Array Layout/1D Parameters/mlat'
    mlat = hdf_read_var(mlat_var, filename=files)
    mlon_var = '/Data/Array Layout/1D Parameters/mlong'
    mlon = hdf_read_var(mlon_var, filename=files)
    mlt_var = '/Data/Array Layout/1D Parameters/mlt'
    mlt = hdf_read_var(mlt_var, filename=files)


;---Calibrate the data.
    time_var = '/Data/Array Layout/timestamps'
    times = hdf_read_var(time_var, filename=files)
    time_index = lazy_where(times, '[]', time_range, count=count)
    if count eq 0 then begin
        errmsg = 'No data in given time_range ...'
        return, retval
    endif
    times = times[time_index]
    mlat = mlat[time_index]
    mlon = mlon[time_index]
    mlt = mlt[time_index]
    
    var = vars[0]
    store_data, var, times, mlat
    add_setting, var, smart=1, dictionary($
        'requested_time_range', time_range, $
        'display_type', 'scalar', $
        'unit', 'deg', $
        'short_name', 'MLat' )
    
    var = vars[1]
    store_data, var, times, mlt
    add_setting, var, smart=1, dictionary($
        'requested_time_range', time_range, $
        'display_type', 'scalar', $
        'unit', 'h', $
        'short_name', 'MLT' )

    var = vars[2]
    store_data, var, times, mlon
    add_setting, var, smart=1, dictionary($
        'requested_time_range', time_range, $
        'display_type', 'scalar', $
        'unit', 'deg', $
        'short_name', 'MLon' )


    return, vars

end


time_range = ['2013-05-01','2013-05-03']
probe = 'f18'
r1_var = dmsp_read_mlat_vars_cdaweb(time_range, probe=probe)
r2_var = dmsp_read_mlat_vars_madrigal(time_range, probe=probe)
end