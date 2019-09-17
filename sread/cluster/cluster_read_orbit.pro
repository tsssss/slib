
pro cluster_read_orbit, time, probe=probe, errmsg=errmsg, _extra=ex

    pre0 = 'c'+probe+'_'
    dt = 60.0

    cluster_read_fgm, time, id='orbit', probe=probe, errmsg=errmsg, _extra=ex

    re1 = 1d/6378d
    get_data, pre0+'r_gse', times, data
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
end

time = time_double(['2013-10-30/23:00','2013-10-31/06:00'])
cluster_read_orbit, time, probe='1'
end
