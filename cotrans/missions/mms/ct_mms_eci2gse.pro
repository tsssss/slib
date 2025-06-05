

function ct_mms_eci2gse, vec0, times, probe=probe, errmsg=errmsg
    
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
    vec1 = double(vec0)
    vec1 = rotate_vector(vec1, matrix)
    
    return, vec1

end

time_range = ['2015-09-01','2015-09-02']
probe = '1'
b_gse_var = mms_read_bfield(time_range, probe=probe, coord='gse')
b_gse = get_var_data(b_gse_var, times=times)
b_eci = ct_mms_eci2gse(b_gse, times, probe=probe)
end