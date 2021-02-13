;+
; Read MMS position in GSM. Save as 'mmsx_r_gsm'
;
; time. A time or a time range in ut sec.
; probe. A string sets the probe, '1',...,'4'.
;-
pro mms_read_orbit, time, probe=probe, errmsg=errmsg, _extra=ex

    re = 6378d
    re1 = 1d/re
    dt = 30.

    ; Use the r_gsm in fgm data.
    id = 'l2%orbit'
    mms_read_fgm, time, id=id, probe=probe, errmsg=errmsg
    if errmsg ne '' then return

    pre0 = 'mms'+probe+'_'
    rvar = pre0+'r_gsm'
    get_data, rvar, times, rgsm
    rgsm = rgsm[*,0:2]*re1
    store_data, rvar, times, rgsm
    add_setting, rvar, /smart, {$
        display_type: 'vector', $
        unit: 'Re', $
        short_name: 'R', $
        coord: 'GSM', $
        coord_labels: ['x','y','z'], $
        colors: sgcolor(['red','green','blue'])}
    uniform_time, rvar, dt

end

time = time_double(['2016-10-28/22:30:00','2016-10-29/01:00:00'])
time_range = time_double(['2019-01-01','2020-01-01'])
time_range = time_double(['2019-08-01','2019-08-31'])
time_range = time_double(['2019-08-18','2019-08-19'])
secofday = constant('secofday')
times = make_bins(time_range, secofday)
foreach time, times do mms_read_orbit, time+[0,secofday], probe='1', errmsg=errmsg
end