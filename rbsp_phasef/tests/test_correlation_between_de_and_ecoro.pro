;+
; Test if dE = E-E_model correlates with E_coro
;-

    time_range = time_double(['2013-01-01','2013-02-01'])
    probe = 'a'

    ;rbsp_read_de_mgse, time_range, probe=probe, datatype='de_related'
    ;options, prefix+'de_mgse', 'colors', sgcolor(['green','blue'])

    rbsp_read_e_model, time_range, probe=probe, datatype='e_model_related'
    rbsp_efw_phasef_read_wobble_free_var, time_range, probe=probe
    
    
    
    prefix = 'rbsp'+probe+'_'
    fillval = !values.f_nan
    
    get_data, prefix+'emod_mgse', times
    foreach var, prefix+['e','b','r','v']+'_mgse' do interp_time, var, times

    ; Calc E dot0.
    get_data, prefix+'e_mgse', times, e_mgse, limits=lim
    get_data, prefix+'b_mgse', times, b_mgse
    e_mgse[*,0] = -(e_mgse[*,1]*b_mgse[*,1]+e_mgse[*,2]*b_mgse[*,2])/b_mgse[*,0]
    b_ratio = b_mgse[*,0]/snorm(b_mgse)
    index = where(abs(b_ratio) le 0.1, count)
    if count ne 0 then e_mgse[index,0] = fillval
    store_data, prefix+'e_mgse', times, e_mgse
    
    emod_mgse = get_var_data(prefix+'emod_mgse')
    de_mgse = e_mgse-emod_mgse
    store_data, prefix+'de_mgse', times, de_mgse, limits=lim
    

end