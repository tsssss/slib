;+
; Return the mlt image info.
; midnight is along -y.
;-

function mlt_image_info, half_size0

    ; We modifies mlon_image_info to get mlt_image_info.
    mlon_image_info = mlon_image_info(half_size0)
    xxs = mlon_image_info.pixel_xpos
    yys = mlon_image_info.pixel_ypos
    tts = atan(yys,xxs)
    deg = constant('deg')
    mlt = (tts*deg+90)/15
    index = where(mlt le -12, count)
    if count ne 0 then mlt[index] += 24
    index = where(mlt gt 12, count)
    if count ne 0 then mlt[index] -= 24

    mlon_image_info['pixel_mlt'] = mlt
    mlon_image_info['mlt_range'] = [-1d,1]*12
    return, mlon_image_info

end
