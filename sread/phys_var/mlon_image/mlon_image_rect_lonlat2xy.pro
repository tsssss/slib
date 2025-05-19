;+
; Return the x and y position for given mlon and mlat.
; mlon=. Input mlon in deg.
; mlat=. Input mlat in deg.
; xpos=. Output xpos in pixel #.
; ypos=. Output ypos in pixel #.
; info=. Optional, the return value of mlon_image_rect_info(). To avoid reloading it.
;-

pro mlon_image_rect_lonlat2xy, mlon=mlon, mlat=mlat, xpos=xpos, ypos=ypos, $
    info=mlon_image_rect_info

    if n_elements(mlon_image_rect_info) eq 0 then mlon_image_rect_info = mlon_image_rect_info()
    mlat_range = mlon_image_rect_info.mlat_range
    mlon_range = mlon_image_rect_info.mlon_range
    image_size = mlon_image_rect_info.image_size

    xpos = (mlon-mlon_range[0])/(mlon_range[1]-mlon_range[0])*(image_size[0]-1)
    ypos = (mlat-mlat_range[0])/(mlat_range[1]-mlat_range[0])*(image_size[1]-1)

end