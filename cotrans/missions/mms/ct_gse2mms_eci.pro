
function ct_gse2mms_eci, vec0, times, probe=probe, errmsg=errmsg

    prefix = 'mms'+probe+'_'
    errmsg = ''
    retval = !null

    time_range = minmax(times)
    q_var = mms_read_q_mms_eci2gse(time_range, probe=probe, errmsg=errmsg)
    if errmsg ne '' then return, retval
    
    quaternion = get_var_data(q_var, times=ut_cotran)
    eq_tolerance = 1e-8

    quaternion = qslerp(quaternion, ut_cotran, times, eq_tolerance=eq_tolerance)
    matrix = qtom(quaternion)
    n1 = n_elements(vec1)/3
    for ii=0,n1-1 do matrix[ii,*,*] = transpose(matrix[ii,*,*])
    vec1 = double(vec0)
    vec1 = rotate_vector(vec1, matrix)
    
    return, vec1

end

time_range = ['2015-09-01','2015-09-02']
probe = '1'
prefix = 'mms'+probe+'_'

;r_eci_var = mms_read_orbit(time_range, probe=probe, coord='eci', ids='cdaweb')
;r_gse_var = mms_read_orbit(time_range, probe=probe, coord='gse', ids='cdaweb')



b_gse_var = mms_read_bfield(time_range, probe=probe, coord='gse')
b_eci_var = mms_read_bfield(time_range, probe=probe, coord='mms_eci')
b_bcs_var = mms_read_bfield(time_range, probe=probe, coord='mms_bcs')
stop
;b_gse = get_var_data(b_gse_var, times=times)
;b1 = cotran_pro(b_gse, times, probe=probe, coord_msg=['gse','mms_bcs'])
b_eci = get_var_data(b_eci_var, times=times)
b1 = cotran_pro(b_eci, times, probe=probe, coord_msg=['mms_eci','mms_dbcs'])
lim = get_var_setting(b_bcs_var)
var1 = prefix+'b_mms_dbcs_cotran'
store_data, var1, times, b1
add_setting, var1, smart=1, lim

b2 = cotran_pro(b1, times, probe=probe, coord_msg=['mms_dbcs','mms_bcs'])
lim = get_var_setting(b_bcs_var)
var2 = prefix+'b_mms_bcs_cotran'
store_data, var2, times, b2
add_setting, var2, smart=1, lim
stop
end