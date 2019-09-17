;+
; Read FGM data.
;-
pro cluster_read_bfield, time, probe=probe, resolution=resolution, errmsg=errmsg

    pre0 = 'c'+probe+'_'

    cluster_read_fgm, time, id='fgm_spin', probe=probe, errmsg=errmsg, _extra=ex
    if errmsg ne '' then return

    get_data, pre0+'b_gse', times, data
    data = cotran(data, times, 'gse2gsm')
    var = pre0+'b_gsm'
    store_data, var, times, data
    index = where(snorm(data) ge 1e29, count)
    if count ne 0 then begin
        data[index,*] = !values.f_nan
        store_data, var, times, data
    endif
    add_setting, var, /smart, {$
        display_type: 'vector', $
        unit: 'nT', $
        short_name: 'B', $
        coord: 'GSM', $
        coord_labels: ['x','y','z']}
end


time = time_double(['2013-10-30/23:00','2013-10-31/06:00'])
cluster_read_bfield, time, probe='1'
end
