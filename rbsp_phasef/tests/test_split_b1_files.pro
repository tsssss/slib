;+
; Test to split b1 files into 30-min chunks.
;-


;---Load B1 data.
    time_range = time_double(['2013-06-01','2015-01-01'])
    probe = 'a'
    timespan, time_range[0], total(time_range*[-1,1]), /seconds

    rbsp_efw_init
    ; Berkeley site contains most up to date data.
    !rbsp_efw.remote_data_dir = 'http://themis.ssl.berkeley.edu/data/rbsp/'
    !rbsp_efw.local_data_dir = '/Volumes/data/rbsp/'
    rbsp_load_efw_waveform, probe=probe, type='calibrated', $
        datatype='vb1', downloadonly=1, files=files


end