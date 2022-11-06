;+
; Return the x and y position for given glon and glat.
; glon=. Input glon in deg.
; glat=. Input glat in deg.
; xpos=. Output xpos in pixel #.
; ypos=. Output ypos in pixel #.
; info=. Optional, the return value of glon_image_info(). To avoid reloading it.
;-

pro glon_image_lonlat2xy, glon=glon, glat=glat, xpos=xpos, ypos=ypos, $
    info=glon_image_info

    if n_elements(glon_image_info) eq 0 then glon_image_info = glon_image_info()
    glat_range = glon_image_info.glat_range
    min_glat = glat_range[0]
    max_glat = glat_range[1]
    image_size = glon_image_info.image_size

    rr = 1-(glat-min_glat)/(max_glat-min_glat)  ; r in [-1,1].
    tt = glon*constant('rad')
    xpos = rr*cos(tt)
    ypos = rr*sin(tt)
    xpos = (xpos*0.5+0.5)*(image_size[0]-1)
    ypos = (ypos*0.5+0.5)*(image_size[1]-1)
    
end