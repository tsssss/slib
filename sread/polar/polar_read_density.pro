;+
; Read Polar density.
;-

function polar_read_density, time, probe=probe, errmsg=errmsg

    errmsg = ''
    retval = !null
    
    polar_read_cdaweb_hydra, time, id='ele_density', errmsg=errmsg
    if errmsg ne '' then return, retval

    var = 'po_ele_n'
    get_data, var, times, data
    index = where(data le -1e30, count)
    if count ne 0 then begin
        data[index] = !values.d_nan
        store_data, var, times, data
    endif
    add_setting, var, /smart, {$
        display_type: 'scalar', $
        unit: 'cm!U-3!N', $
        short_name: 'n!Dele', $
        ylog: 1}
    
    return, var

end

time = time_double(['1999-09-25','1999-09-26'])
time_range = time_double('2000-'+['03-20','03-22'])

time_range = time_double('2000-'+['01','06'])
time_range = time_double('1999-'+['06','12-31'])
time_range = time_double(['1999-11-15','1999-11-16'])
time_range = time_double(['2000-03-20','2000-03-22'])
n_var = polar_read_density(time_range)
b_var = polar_read_bfield(time_range)
r_var = polar_read_orbit(time_range)
u_var = polar_read_ion_vel(time_range)
sgopen, 0, size=[18,5]
prefix = 'po_'
tplot, [n_var,b_var,u_var,r_var,prefix+['mlt']], trange=time_range
end
