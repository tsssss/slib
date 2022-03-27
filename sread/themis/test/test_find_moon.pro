;+
; Test to find the moon.
;-


time_range = time_double(['2013-03-17/05:00','2013-03-17/06:00'])
site = 'mcgr'
;site = 'gako'
;site = 'mcgr'
;site = 'fykn'
;site = 'fsmi'
site = 'tpas'

;time_range = time_double(['2008-03-23/09:00','2008-03-23/10:00'])
;site = 'rank'
;site = 'kapu'
;site = 'fsmi'
;site = 'gbay'
;site = 'kuuj'
;site = 'snkq'
;site = 'gill'
;site = 'tpas'
;site = 'atha'
;site = 'yknf'
;site = 'fsim'
;site = 'gako'
;site = 'kian'
;site = 'mcgr'


;time_range = time_double(['2008-01-17/03:00','2008-01-17/04:00'])
;site = 'kuuj'
;
;time_range = time_double(['2008-02-19/07:00','2008-02-19/08:00'])
;site = 'inuv'

prefix = 'thg_'+site+'_'
asf_var = prefix+'asf'
if check_if_update(asf_var, time_range) then themis_read_asf, time_range, site=site, errmsg=errmsg
asf_cal_var = prefix+'asf_cal'
if check_if_update(asf_cal_var, time_range) then themis_asi_cal_brightness, asf_var, to=asf_cal_var
get_data, asf_var, times, asf_images, limits=lim
get_data, asf_cal_var, times, cal_images
glon = lim.asc_glon
glat = lim.asc_glat

elevs = lim.pixel_elev
azims = lim.pixel_azim
image_size = lim.image_size
sgopen, 0, size=image_size
xrange = [0,image_size[0]-1]
yrange = [0,image_size[1]-1]
tpos = [0d,0,1,1]
rad = constant('rad')
deg = constant('deg')
xpos = cos(elevs*rad)*cos(azims*rad)
ypos = cos(elevs*rad)*sin(azims*rad)
zpos = sin(elevs*rad)

moon_elevs = moon_elev(times, glon, glat, azimuth=moon_azims, deg=1)
foreach time, times, time_id do begin
    asf_image = bytscl(reform(asf_images[time_id,*,*]), min=0,max=6e4, top=254)
    cal_image = bytscl(reform(cal_images[time_id,*,*]), min=0,max=1e4, top=254)
;    sgtv, asf_image, position=tpos, ct=49
    sgtv, cal_image, position=tpos, ct=49
    plot, xrange, yrange, $
        xstyle=5, ystyle=5, nodata=1, noerase=1
    
    moon_elev = moon_elevs[time_id]
    moon_azim = moon_azims[time_id]
        
    tx = cos(moon_elev*rad)*cos(moon_azim*rad)
    ty = cos(moon_elev*rad)*sin(moon_azim*rad)
    tz = sin(moon_elev*rad)
    
    dis = sqrt((xpos-tx)^2+(ypos-ty)^2+(zpos-tz)^2)
    contour, dis, noerase=1, position=tpos, iso=1, xstyle=5, ystyle=5, levels=findgen(10)*0.2
    print, time_string(time)
endforeach
end