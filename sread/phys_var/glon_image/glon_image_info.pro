;+
; Return the glon image info.
; 
; half_size0. The image is 2*half_size0+1.
;-

function glon_image_info, half_size0

    if n_elements(half_size0) eq 0 then half_size0 = 250
    half_size = [1d,1]*half_size0
    image_size = half_size*2+1  ; odd number places the pole at the center.
    glat_range = [50d,90]
    glon_range = [-1,1]*180

    sz = image_size[0]
    ones = dblarr(sz)+1
    xxs = ones ## smkarthm(-1,1,sz,'n')
    yys = smkarthm(-1,1,sz,'n') ## ones
    rrs = sqrt(xxs^2+yys^2)
    tts = atan(yys,xxs)

    if n_elements(min_glat) eq 0 then min_glat = glat_range[0]
    max_glat = glat_range[1]
    deg = constant('deg')
    glon = tts*deg  ; in [-180, 180] deg. THEMIS ASI glon all follow this.
    glat = (1-rrs)*(max_glat-min_glat)+min_glat

    return, dictionary($
        'half_size', half_size, $
        'image_size', image_size, $
        'glat_range', glat_range, $
        'glon_range', glon_range, $
        'pixel_xpos', xxs, $
        'pixel_ypos', yys, $
        'pixel_glon', glon, $
        'pixel_glat', glat )
end
