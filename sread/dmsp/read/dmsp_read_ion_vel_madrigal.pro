;+
; Read DMSP ion velocity.
;-

function dmsp_read_ion_vel_madrigal, input_time_range, probe=probe, errmsg=errmsg, $
    get_name=get_name, suffix=suffix, coord=coord, _extra=ex

    prefix = 'dmsp'+probe+'_'
    errmsg = ''
    retval = ''

    if n_elements(suffix) eq 0 then suffix = '_madrigal'
    if n_elements(coord) eq 0 then coord = 'xyz'
    v_coord_var = prefix+'v_'+coord
    if keyword_set(get_name) then return, v_coord_var

    time_range = time_double(input_time_range)
    if ~check_if_update(v_coord_var, time_range) then return, v_coord_var

    files = dmsp_load_ssm_madrigal(time_range, probe=probe, errmsg=errmsg)
    if errmsg ne '' then return, retval

;---Read data.
    all = hdf_read_var('/Data/Table Layout', filename=files)
    
    times = all.ut1_unix
    time_index = where_pro(times, '[]', time_range, count=count)
    if count eq 0 then begin
        errmsg = 'No data in given time_range ...'
        return, retval
    endif
    times = times[time_index]
    ntime = n_elements(times)
    v_forw = fltarr(ntime)
    v_perp = (all.hor_ion_v)[time_index]
    v_down = (all.vert_ion_v)[time_index]

    store_data, v_coord_var, times, [[v_forw],[v_perp],[v_down]]
    add_setting, v_coord_var, smart=1, dictionary($
        'requested_time_range', time_range, $
        'display_type', 'vector', $
        'unit', 'm/s', $
        'short_name', 'V', $
        'coord', 'XYZ' )

    return, v_coord_var

;    'B_FORWARD'
;    'B_PERP'
;    'BD'
;    'HOR_ION_V'
;    'VERT_ION_V'
    ; Found by tmp = h5_browser(files[0])
    ; db_forward = hdf_read_var('/Data/Table Layout/diff_b_for', filename=files)
    ; db_perp = hdf_read_var('/Data/Table Layout/diff_b_perp', filename=files)
    stop



end



time_range = ['2013-05-01','2013-05-02']
probe = 'f18'
time_range = ['2015-03-12','2015-03-13']
probe = 'f19'
b_var = dmsp_read_bfield_madrigal(time_range, probe=probe)
v_var = dmsp_read_ion_vel_madrigal(time_range, probe=probe)
end