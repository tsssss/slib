;+
; Some days have data gap but filled with interpolated E field.
; The interpolated data appear as huge spikes in yearly plots.
;-

probe = 'b'
dates = time_double([$
    '2015-09-15', $
    '2015-09-16', $
    '2015-10-10', $
    '2015-10-11', $
    '2015-10-12', $
    '2016-01-24', $
    '2016-05-18', $
    '2017-01-11', $
    '2017-01-12', $
    '2018-03-25', $
    '2018-09-03', $
    '2019-05-14', $
    '2019-05-15' ])

rbsp_efw_read_l4_gen_file, time_range, probe=probe, filename=test_file
end
