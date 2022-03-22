;+
; Convert a square MLT image from xy pixel to MLT and MLat.
;
; input_image. Input image in [ntime,sz,sz] or [sz,sz] or dimension [sz,sz].
; min_mlat=. Input min mlat in deg. By default is 50 deg.
; mlt=. Output mlt in [sz,sz] in hr.
; mlat=. Output mlat in [sz,sz] in deg.
;
;-

pro mltimg_xy2mltmlat, input_image, min_mlat=min_mlat, $
    mlt=mlt, mlat=mlat, errmsg=errmsg

    if n_elements(min_mlat) eq 0 then min_mlat = 50d

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

    rad2hour = constant('deg')/15
    mlt = tts*rad2hour-6
    index = where(mlt le -12, count)
    if count ne 0 then mlt[index] += 24
    mlat = (1-rrs)*(90-min_mlat)+min_mlat

end

mltimg_xy2mltmlat, [5,5], mlt=mlt, mlat=mlat
end
