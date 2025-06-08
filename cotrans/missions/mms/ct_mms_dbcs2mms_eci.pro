
function ct_mms_dbcs2mms_eci, vec0, times, probe=probe, errmsg=errmsg

    return, ct_mms_eci2mms_dbcs(vec0, times, probe=probe, errmsg=errmsg, inverse=1)

end

time_range = ['2015-09-01','2015-09-02']
probe = '1'
b_gse_var = mms_read_bfield(time_range, probe=probe, coord='gse')
b_gse = get_var_data(b_gse_var, times=times)
b_eci = ct_mms_eci2gse(b_gse, times, probe=probe)
end