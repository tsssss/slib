date = '2015-01-01'
probe = 'a'

secofday = constant('secofday')
time_range = time_double(date)+[0,secofday]
prefix = 'rbsp'+probe+'_'

foreach version, ['v01','v02'] do begin
    rbsp_efw_phasef_read_b_mgse, time_range, probe=probe, version=version
    vars = prefix+['b']+'_mgse'
    foreach var, vars do rename_var, var, to=var+'_'+version
endforeach


end