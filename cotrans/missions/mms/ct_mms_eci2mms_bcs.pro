
function ct_mms_eci2mms_bcs, vec0, times, probe=probe, errmsg=errmsg
    errmsg = ''
    retval = !null

    time_range = minmax(times)
;    files = mms_ld_mec(time_range, id='l2%survey', probe=probe, errmsg=errmsg)
;    if errmsg ne '' then return, retval
;
;    prefix = 'mms'+probe+'_'
;    in_var = prefix+'mec_quat_eci_to_bcs'
;    q_var = prefix+'q_mms_eci2mms_bcs'
;    var_list = list()
;    var_list.add, dictionary($
;        'in_vars', in_var, $
;        'out_vars', q_var, $
;        'time_var_name', 'Epoch', $
;        'time_var_type', 'tt2000' )
;    read_vars, time_range, files=files, var_list=var_list, errmsg=errmsg
;    if errmsg ne '' then return, retval
;    
;    quaternion = get_var_data(q_var, times=ut_cotran)
;    quaternion = quaternion[*,[3,0,1,2]]  ; mms quaternion in <x,y,z,w>, need to convert to <w,x,y,z>.
;    eq_tolerance = 1e-8
    q_var = mms_read_quaternion_mms_eci2mms_bcs(time_range, probe=probe)
    eq_tolerance = 1e-5
    quaternion = get_var_data(q_var, times=ut_cotran)
    quaternion = qslerp(quaternion, ut_cotran, times, eq_tolerance=eq_tolerance)
    matrix = qtom(quaternion)
    vec1 = double(vec0)
    n1 = n_elements(vec1)/3
    vec1 = rotate_vector(vec1, matrix)
    
    return, vec1

end

time_range = ['2015-09-01','2015-09-02']
probe = '1'
b_gse_var = mms_read_bfield(time_range, probe=probe, coord='gse')
b_gse = get_var_data(b_gse_var, times=times)
b_eci = ct_mms_eci2gse(b_gse, times, probe=probe)
end