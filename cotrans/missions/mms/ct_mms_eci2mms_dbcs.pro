
function ct_mms_eci2mms_dbcs, vec0, times, probe=probe, errmsg=errmsg, inverse=inverse

    errmsg = ''
    retval = !null

    time_range = minmax(times)
    q_var = mms_read_q_mms_eci2mms_dbcs(time_range, probe=probe, errmsg=errmsg)
    if errmsg ne '' then return, retval
    
    eq_tolerance = 1e-3
    quaternion = get_var_data(q_var, times=ut_cotran)
    index = where(abs(snorm(quaternion)-1) le eq_tolerance, count)
    if count eq 0 then begin
        errmsg = 'Invalid quaternion ...'
        return, retval
    endif
    quaternion = quaternion[index,*]
    ut_cotran = ut_cotran[index]

    quaternion = qslerp(quaternion, ut_cotran, times, eq_tolerance=eq_tolerance)
    matrix = qtom(quaternion)
    if keyword_set(inverse) then begin
        n1 = n_elements(vec1)/3
        for ii=0,n1-1 do matrix[ii,*,*] = transpose(matrix[ii,*,*])
    endif
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