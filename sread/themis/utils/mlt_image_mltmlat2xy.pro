;+
; Return the x and y position for given mlt and mlat.
; mlt=. Input mlt in hour.
; mlat=. Input mlat in deg.
; xpos=. Output xpos in pixel #.
; ypos=. Output ypos in pixel #.
; info=. Optional, the return value of mlon_image_info(). To avoid reloading it.
;-

pro mlt_image_mltmlat2xy, mlt=mlt, mlat=mlat, xpos=xpos, ypos=ypos, $
    info=mlt_image_info

    if n_elements(mlt_image_info) eq 0 then mlt_image_info = mlt_image_info()
    mlat_range = mlt_image_info.mlat_range
    min_mlat = mlat_range[0]
    max_mlat = mlat_range[1]
    image_size = mlt_image_info.image_size

    rr = 1-(mlat-min_mlat)/(max_mlat-min_mlat)  ; r in [-1,1].
    tt = (mlt*15-90)*constant('rad')    ; mlt=0 h is along -90 deg.
    xpos = rr*cos(tt)
    ypos = rr*sin(tt)
    xpos = (xpos*0.5+0.5)*(image_size[0]-1)
    ypos = (ypos*0.5+0.5)*(image_size[1]-1)

end
