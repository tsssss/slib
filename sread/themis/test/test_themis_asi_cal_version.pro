;+
; Check the differences between cal v01 and v02 files.
;-

site = 'mcgr'
file_v01 = '/Volumes/data/themis/thg/l2/asi/cal/thg_l2_asc_'+site+'_19700101_v01.cdf'
file_v02 = '/Volumes/data/themis/thg/l2/asi/cal/thg_l2_asc_'+site+'_19700101_v02.cdf'

prefix = 'thg_asf_'+site+'_'
vars = ['time','elev','azim','glon','glat']
cal_v01 = dictionary()
cal_v02 = dictionary()
foreach var, vars do begin
    val = double(cdf_read_var(prefix+var, filename=file_v01))
    index = where(finite(val,nan=1), count)
    if count ne 0 then val[index] = 0d
    cal_v01[var] = val
    val = double(cdf_read_var(prefix+var, filename=file_v02))
    index = where(finite(val,nan=1), count)
    if count ne 0 then val[index] = 0d
    cal_v02[var] = val
endforeach

print, time_string(cal_v01.time)
print, time_string(cal_v02.time)


stop

end
