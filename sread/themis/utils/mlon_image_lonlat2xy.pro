;+
; Return the x and y position for given mlon and mlat.
; mlon=. Input mlon in deg.
; mlat=. Input mlat in deg.
; xpos=. Output xpos in pixel #.
; ypos=. Output ypos in pixel #.
; info=. Optional, the return value of mlon_image_info(). To avoid reloading it.
;-

pro mlon_image_lonlat2xy, mlon=mlon, mlat=mlat, xpos=xpos, ypos=ypos, $
    info=mlon_image_info

    if n_elements(mlon_image_info) eq 0 then mlon_image_info = mlon_image_info()
    mlat_range = mlon_image_info.mlat_range
    min_mlat = mlat_range[0]
    max_mlat = mlat_range[1]
    image_size = mlon_image_info.image_size

    rr = 1-(mlat-min_mlat)/(max_mlat-min_mlat)  ; r in [-1,1].
    tt = mlon*constant('rad')
    xpos = rr*cos(tt)
    ypos = rr*sin(tt)
    xpos = (xpos*0.5+0.5)*(image_size[0]-1)
    ypos = (ypos*0.5+0.5)*(image_size[1]-1)
    
end