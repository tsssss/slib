;+
; Read GOES position.
;-

pro goes_read_orbit, time, probe=probe, errmsg=errmsg, _extra=ex

    pre0 = 'g'+probe+'_'
    dt = 60.0

;    case probe of
;        '12': valid_range = ['2006-01-01','2016-12-20']
;        '13': valid_range = ['2006-06-10']
;        '14': valid_range = ['2009-07-09']
;        '15': valid_range = ['2010-03-21']
;        '16': valid_range = ['2016-12-03']
;        '17': valid_range = ['2018-03-21']
;        else: valid_range = !null
;    endcase
;    if n_elements(valid_range) eq 0 then valid_range = time
;    valid_range = time_double(valid_range)
;    if n_elements(valid_range) eq 1 then valid_range = [valid_range,systime(1,/utc)]
;    valid_range = minmax(valid_range)
;    if min(time) ge valid_range[1] then begin
;        errmsg = 'No data ...'
;        return
;    endif
;    if max(time) le valid_range[0] then begin
;        errmsg = 'No data ...'
;        return
;    endif
;    the_time = time<valid_range[1]>valid_range[0]
    the_time = time

    ; read 'xyz_gsm'
    goes_read_orbit_cdaweb, the_time, probe=probe, coord='gsm', errmsg=errmsg
    if errmsg ne '' then goes_read_ssc, the_time, id='pos', probe=probe, errmsg=errmsg

    var = pre0+'r_gsm'
    add_setting, var, /smart, {$
        display_type: 'vector', $
        unit: 'Re', $
        short_name: 'R', $
        coord: 'GSM', $
        coord_labels: constant('xyz')}

    uniform_time, var, dt, errmsg=errmsg
    if errmsg ne '' then begin
        del_data, var
        return
    endif

end


time_range = time_double(['2006-01-01','2007-01-01'])
time_range = time_double(['2016-01-01','2017-01-01'])
time_range = time_double(['2016-12-19','2016-12-21'])
probe = '12'

time_range = time_double(['2006-01-01','2007-01-01'])
probe = '13'

time_range = time_double(['2009-01-01','2010-01-01'])
time_range = time_double(['2009-07-09','2009-07-10'])
time_range = time_double(['2009-07-08','2009-07-09'])
probe = '14'

time_range = time_double(['2010-01-01','2011-01-01'])
probe = '15'

time_range = time_double(['2016-01-01','2017-01-01'])
probe = '16'

time_range = time_double(['2018-01-01','2019-01-01'])
probe = '17'

time_range = time_double(['2008-03-14/06:30','2008-03-14:06:40'])
probe = '13'

goes_read_orbit, time_range, probe=probe
end