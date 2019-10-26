
pro cluster_read_orbit, time, probe=probe, errmsg=errmsg, _extra=ex

    pre0 = 'c'+probe+'_'
    dt = 60.0   ; original data is 5min.

    ;cluster_read_fgm, time, id='orbit', probe=probe, errmsg=errmsg, _extra=ex
    cluster_read_ssc, time+[0,dt], id='orbit', probe=probe, errmsg=errmsg

    re1 = 1d/6378d
    var = pre0+'r_gse'
    sys_add, var, pre0+'dr_gse', to=var
    get_data, var, times, data
    data *= re1
    data = cotran(data, times, 'gse2gsm')
    var = pre0+'r_gsm'
    store_data, var, times, data
    add_setting, var, /smart, {$
        display_type: 'vector', $
        unit: 'Re', $
        short_name: 'R', $
        coord: 'GSM', $
        coord_labels: ['x','y','z']}

    uniform_time, var, dt
    get_data, var, times, data
    index = where(times lt max(time), count)
    if count gt 0 then begin
        times = times[index]
        data = data[index,*]
        store_data, var, times, data
    endif
end

time = time_double(['2013-01-01','2014-01-01'])
time = time_double(['2009-07-04','2009-07-05'])
time = time_double(['2014','2015'])
probe = '1'
r_var = 'c1_r_gsm'
cluster_read_orbit, time, probe=probe

end