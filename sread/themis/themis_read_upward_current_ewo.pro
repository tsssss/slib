;+
; Read upward current EWOgram.
;
; time_range. Time range in unix time.
; mlt_range=. MLT range in hr.
; mlat_range=. MLat range for calc EWOgram, in deg.
;-
pro themis_read_upward_current_ewo, time_range, mlat_range=mlat_range, $
    mlt_range=mlt_range, errmsg=errmsg

    themis_read_j_ver_ewo, time_range, mlat_range=mlat_range, mlt_range=mlt_range, direction='up', errmsg=errmsg
    options, 'thg_j_up_ewo', 'color_table', 62


end

mlt_range = [-1,1]*6
time_range = time_double(['2013-06-07/04:00','2013-06-07/07:00'])
themis_read_upward_current_ewo, time_range, mlt_range=mlt_range
themis_read_downward_current_ewo, time_range, mlt_range=mlt_range

end