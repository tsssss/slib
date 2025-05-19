;+
; Convert a square MLon image from xy pixel to MLon and MLat.
;
; input_image. Input image in [ntime,sz,sz] or [sz,sz] or dimension [sz,sz].
;   Optional. If not set, use the default image size.
; mlon=. Output mlt in [sz,sz] in deg.
; mlat=. Output mlat in [sz,sz] in deg.
; min_mlat=. Optional, in deg.
;-

pro mlon_image_xy2mlonmlat, input_image, $
    mlon=mlon, mlat=mlat, min_mlat=min_mlat, errmsg=errmsg

    mlonimg_info = mlon_image_info()
    if n_elements(input_image) eq 0 then begin
        image_size = mlonimg_info.image_size
    endif else begin
        dims = size(input_image,dimensions=1)
        ndim = size(input_image,n_dimensions=1)
        if ndim eq 3 then begin
            ; in [ntime,nx,ny]
            image_size = dims[1:2]
        endif else if ndim eq 1 then begin
            ; input is image size [nx,ny]
            image_size = input_image
        endif else if ndim eq 2 then begin
            ; in [nx,ny]
            image_size = dims
        endif
    endelse

    if n_elements(image_size) ne 2 then begin
        errmsg = 'Invalid input ...'
        return
    endif
    if image_size[0] ne image_size[1] then begin
        errmsg = 'Invalid image size ...'
        return
    endif

    sz = image_size[0]
    ones = dblarr(sz)+1
    xxs = ones ## smkarthm(-1,1,sz,'n')
    yys = smkarthm(-1,1,sz,'n') ## ones
    rrs = sqrt(xxs^2+yys^2)
    tts = atan(yys,xxs)

    if n_elements(min_mlat) eq 0 then min_mlat = mltimg_info.mlat_range[0]
    deg = constant('deg')
    mlon = tts*deg  ; in [-180, 180] deg. THEMIS ASI mlon all follow this.
    mlat = (1-rrs)*(90-min_mlat)+min_mlat

end

mlon_image_xy2mlonmlat, [5,5], mlon=mlon, mlat=mlat
end
