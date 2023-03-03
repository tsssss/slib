;+
; Return the valid time range for a certain goes satellite.
;-

function goes_valid_range_info

    valid_range_info = orderedhash()

    ; A rough estimate from THEMIS summary plot
    ; and from the orbit data at CDAWeb, https://cdaweb.gsfc.nasa.gov/pub/data/goes/.
    time_now = time_string(systime(1))
    valid_range_info['09'] = time_double(['1995-06-01','2008-12-31/24:00'])
    valid_range_info['10'] = time_double(['1997-05-01','2009-12-31/24:00'])
    valid_range_info['11'] = time_double(['2000-05-01','2015-12-31/24:00'])
    valid_range_info['12'] = time_double(['2006-01-01','2016-12-31/24:00'])
    valid_range_info['13'] = time_double(['2006-06-01','2017-12-31/24:00'])
    valid_range_info['14'] = time_double(['2009-07-01','2020-03-31/24:00'])
    valid_range_info['15'] = time_double(['2010-03-01','2020-03-31/24:00'])
    valid_range_info['16'] = time_double(['2016-12-01',time_now])
    valid_range_info['17'] = time_double(['2018-03-01',time_now])
    valid_range_info['18'] = time_double(['2022-03-01',time_now])

    return, valid_range_info

end