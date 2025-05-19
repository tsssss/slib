;+
; Check spec data for some random days.
;-

; There's a spike on this day. Not really?
time_range = time_double(['2015-10-19','2015-10-20'])
probe = 'a'


; SDT? on this day.
time_range = time_double(['2015-11-14','2015-11-15'])
probe = 'a'

; Spikes on this day.
time_range = time_double(['2015-11-19','2015-11-20'])
probe = 'b'

prefix = 'rbsp'+probe+'_'

rbsp_efw_read_l2, time_range, probe=probe, datatype='spec'
rbsp_efw_read_l2, time_range, probe=probe, datatype='fbk'
rbsp_efw_phasef_read_vsvy, time_range, probe=probe
;rbsp_efw_read_e_mgse, time_range, probe=probe

var = prefix+'efw_spec64_e56ac'
copy_data, var, var+'_shift'
time_tag_offset = 4.
get_data, var+'_shift', times, spec, val
store_data, var+'_shift', times-time_tag_offset, spec, val

options, prefix+'efw_spec64*', 'ylog', 1
options, prefix+'efw_vsvy', 'colors', sgcolor(['red','green','blue','yellow','cyan','purple'])

vars = prefix+['efw_spec64_e56ac','efw_spec64_e56ac_shift','efw_vsvy']
nvar = n_elements(vars)
margins = [16,4,10,2]
sgopen, 0, xsize=6, ysize=6
poss = sgcalcpos(nvar, margins=margins)
tplot, vars, trange=time_range, position=poss
end