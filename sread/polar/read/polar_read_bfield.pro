;+
; Read B field
;-

function polar_read_bfield, time, probe=probe, errmsg=errmsg, $
    coord=coord, get_name=get_name, update=update

    prefix = 'po_'
    default_coord = 'gsm'
    if n_elements(coord) eq 0 then coord = default_coord
    var_info = prefix+'b_'+coord
    if keyword_set(get_name) then return, var_info
    if keyword_set(update) then del_data, var_info
    time_range = time_double(time)
    if not check_if_update(var_info, time_range) then return, var_info

    polar_read_mfe, time, id='k0%bgsm', probe=probe, errmsg=errmsg

    bvar = prefix+'b_'+default_coord
    get_data, bvar, times, data
    fillval = !values.f_nan
    badval = -1e30
    index = where(data lt badval, count)
    if count ne 0 then begin
        data[index] = fillval
        store_data, bvar, times, data
    endif
    if coord ne default_coord then begin
        bvec = cotran_pro(data, times, coord_msg=[default_coord,coord])
        store_data, var_info, times, bvec
    endif

    add_setting, var_info, smart=1, id='bfield', {coord: coord, $
        requested_time_range:time_range, mission_probe:'polar'}
    return, var_info

end

time_range = time_double(['1998-09-25','1998-09-26'])
time_range = time_double(['1998-01-01','1998-02-01'])
time_range = time_double(['1999-01','1999-06'])
time_range = time_double('2000-'+['01','06'])
b_var = polar_read_bfield(time_range)
sgopen, 0, size=[18,5]
tplot, b_var, trange=time_range
end