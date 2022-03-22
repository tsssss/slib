;+
; Return the mlon image info.
;-

function mlon_image_info

    half_size = [1d,1]*250
    image_size = half_size*2+1  ; odd number places the pole at the center.
    mlat_range = [50d,90]
    mlon_range = [-1,1]*180

    sz = image_size[0]
    ones = dblarr(sz)+1
    xxs = ones ## smkarthm(-1,1,sz,'n')
    yys = smkarthm(-1,1,sz,'n') ## ones
    rrs = sqrt(xxs^2+yys^2)
    tts = atan(yys,xxs)

    if n_elements(min_mlat) eq 0 then min_mlat = mlat_range[0]
    max_mlat = mlat_range[1]
    deg = constant('deg')
    mlon = tts*deg  ; in [-180, 180] deg. THEMIS ASI mlon all follow this.
    mlat = (1-rrs)*(max_mlat-min_mlat)+min_mlat

    return, dictionary($
        'half_size', half_size, $
        'image_size', image_size, $
        'mlat_range', mlat_range, $
        'mlon_range', mlon_range, $
        'pixel_xpos', xxs, $
        'pixel_ypos', yys, $
        'pixel_mlon', mlon, $
        'pixel_mlat', mlat )
end
