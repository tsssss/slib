;+
; Read vertical and horizontal currents.
;-

function themis_read_j_ver_mlt_image, input_time_range, errmsg=errmsg, get_name=get_name

    errmsg = ''
    mlt_image_var = 'thg_j_ver_mlt_image'
    if keyword_set(get_name) then return, mlt_image_var

    time_range = time_double(input_time_range)
    mlon_image_var = themis_read_j_ver_mlon_image(time_range)
    mlt_image_var = mlon_image_to_mlt_image(mlon_image_var, output=mlt_image_var)

    return, mlt_image_var
end


time_range = time_double(['2008-01-19/06:00','2008-01-19/09:00'])
var = themis_read_j_ver_mlt_image(time_range)
end