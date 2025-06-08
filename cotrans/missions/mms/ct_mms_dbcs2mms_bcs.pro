

function ct_mms_dbcs2mms_bcs, vec0, times, probe=probe, errmsg=errmsg

    return, ct_mms_bcs2mms_dbcs(vec0, times, probe=probe, errmsg=errmsg, inverse=1)

end