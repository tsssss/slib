

function ct_mms_bcs2mms_dbcs, vec0, times, probe=probe, errmsg=errmsg
    errmsg = ''
    retval = !null

    time_range = minmax(times)
    zphase_var = mms_read_zphase(time_range, probe=probe, errmsg=errmsg)
    zphase = get_var_data(zphase_var, times=ut_cotran)
    zphase = spin_phase_interpol(zphase, ut_cotran, times)

    vec1 = double(vec0)
    srotate, vec1, zphase, 2, deg=1

    return, vec1

end