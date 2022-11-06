;+
; Read ASI mlt image.
;-

pro themis_read_asf_mlt_image, input_time_range, sites=sites, $
    min_elev=min_elev, merge_method=merge_method, _extra=extra

    errmsg = ''
    time_range = time_double(input_time_range)

    themis_read_asf_mlon_image, input_time_range, sites=sites, min_elev=min_elev, merge_method=merge_method, errmsg=errmsg
    if errmsg ne '' then return

;---Rotate from mlon to mlt.
    mlon_image_var = 'thg_asf_mlon_image'
    mlt_image_var = 'thg_asf_mlt_image'
    mlon_image_to_mlt_image, mlon_image_var, to=mlt_image_var

end


time_range = time_double(['2013-03-17/07:00','2013-03-17/08:00'])
sites = ['mcgr','fykn','gako','fsim', $
    'fsmi','tpas','gill','snkq','pina','kapu']
themis_read_asf_mlt_image, time_range, sites=sites, merge_method='merge_elev', min_elev=2.5
end
