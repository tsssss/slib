;+
; Read ASI mlt image.
;-

function themis_read_asf_mlt_image, input_time_range, sites=sites, $
    min_elev=min_elev, merge_method=merge_method, $
    get_name=get_name, calibration_method=calibration_method, _extra=extra

    errmsg = ''
    retval = ''
    mlt_image_var = 'thg_asf_mlt_image'
    if keyword_set(get_name) then return, mlt_image_var
    
    time_range = time_double(input_time_range)
    mlon_image_var = themis_read_asf_mlon_image(input_time_range, sites=sites, $
        min_elev=min_elev, merge_method=merge_method, errmsg=errmsg, calibration_method=calibration_method)
    if errmsg ne '' then return, retval

;---Rotate from mlon to mlt.
    return, mlon_image_to_mlt_image(mlon_image_var, output=mlt_image_var)

end


time_range = time_double(['2013-03-17/07:00','2013-03-17/08:00'])
sites = ['mcgr','fykn','gako','fsim', $
    'fsmi','tpas','gill','snkq','pina','kapu']
themis_read_asf_mlt_image, time_range, sites=sites, merge_method='merge_elev', min_elev=2.5
end