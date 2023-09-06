;+
; Test to read MLT image for a given time.
;
; The basic procedure is to
;   1. identify which asi sites have data.
;   2. we determine the mapping index to map pixels to the overall image.
;   3. we rotate the overall image from mlon to mlt.
;-

time_range = time_double(['2008-01-19/08:00','2008-01-19/09:00'])
input_sites = ['inuv','fsim','gill']
datatype = 'ast'


; Test Homayons examples.
time_range = time_double(['2015-12-02/08:00','2015-12-02/09:00'])
input_sites = ['rank']  ; fsim has cloud?
datatype = 'asf'

time_range = time_double(['2015-10-25/07:00','2015-10-25/08:00'])
input_sites = ['gill','whit']
datatype = 'asf'


;time_range = time_double(['2016-01-28/08:00','2016-01-28/09:00'])
;input_sites = ['whit','snkq','inuv','tpas','atha','gbay',$
;    'fsmi','gill','kuuj','fykn','fsim','pina','rank']
;input_sites = ['fykn','whit','fsim','rank','gill','snkq','gbay']   ; other sites have cloud.
;datatype = 'asf'

time_range = time_double(['2013-03-17/07:00','2013-03-17/08:00'])
sites = themis_read_asi_sites()
input_sites = ['mcgr','fykn','gako','fsim',$
    'talo','fsmi','tpas','gill','snkq','kapu']
;input_sites = ['mcgr','fykn','gako','fsmi']


window = 60

min_mlat = 50d
min_elev = 5d
min_count = 10
mlat_range = [min_mlat,90d]

rad = constant('rad')
deg = constant('deg')

npx = (datatype eq 'asf')? 256: 32
isz = (datatype eq 'asf')? 3*npx+1d: 6*npx+1d
isz = (datatype eq 'asf')? 501d: 6*npx+1d

time_step = 3d
common_times = make_bins(time_range+[0,-1]*time_step, time_step)
ncommon_time = n_elements(common_times)


;---To avoid reloading stuff.
    mltimg_info_var = 'thg_mltimg_info_'+datatype
    if check_if_update(mltimg_info_var) then begin
        mltimg_info = dictionary()

        ; Available sites.
        sites = themis_asi_read_available_sites(common_times[0], id='l1%'+datatype, sites=input_sites)


        ; For each site, read data and get the mapping indices.
        foreach site, sites do begin
            asi_var = 'thg_'+site+'_'+datatype
            if check_if_update(asi_var, time_range) then begin
                routine = 'themis_read_'+datatype
                call_procedure, routine, time_range, site=site

                ; Ensure all data are mapped to the common times.
                get_data, asi_var, times, imgs, limits=lim
                ntime = n_elements(times)
                if ntime eq 1 then continue
                if ntime ne ncommon_time then begin
                    index = where_pro(times, '[]', time_range, count=ntime)
                    times = times[index]
                    imgs = imgs[index,*,*]
                    if ntime eq ncommon_time then begin
                        store_data, asi_var, common_times, imgs[index,*,*]
                    endif else begin
                        image_size = lim.image_size
                        new_imgs = fltarr([ncommon_time,image_size])+!values.f_nan
                        index = (times-common_times[0])/time_step
                        new_imgs[index,*,*] = imgs
                        store_data, asi_var, common_times, new_imgs
                    endelse
                endif

                ; Normalize raw count.
                ;themis_asi_cal_brightness, asi_var;, newname=asi_var
            endif

            get_data, asi_var, limits=lim
            mlat = lim.pixel_mlat
            mlon = lim.pixel_mlon
            elev = lim.pixel_elev

            ; Get the index for mapping mlat and mlon to pixels.
            r = (90-mlat)/(90-min_mlat)
            t = (mlon-90)*rad
            xc = r*cos(t)
            yc = r*sin(t)   ; xc,yc in [-1,1].
            pixel_x = round((xc+1)*(isz-1)*0.5)
            pixel_y = round((yc+1)*(isz-1)*0.5)

            asi_index = where(elev ge min_elev and $
                pixel_x ge 0 and pixel_y le isz-1 and $
                pixel_y ge 0 and pixel_y le isz-1 and $
                finite(xc) and finite(yc), count)
            mltimg_index = pixel_x[asi_index]*isz+pixel_y[asi_index]
            mltimg_info[site] = dictionary($
                'asi_index', asi_index, $
                'mltimg_index', mltimg_index, $
                'pixel_count', count, $
                'mlonmlat_x', pixel_x, $
                'mlonmlat_y', pixel_y )
        endforeach
        store_data, mltimg_info_var, 0, mltimg_info
    endif


;---Get the MLT image.
    imfs = dblarr(ncommon_time,isz*isz)
    imcs = dblarr(ncommon_time,isz*isz)
    mltimg_info = get_var_data(mltimg_info_var)
    sites = mltimg_info.keys()
    foreach site, sites do begin
        asi_var = 'thg_'+site+'_'+datatype
        asi_imgs = get_var_data(asi_var, limits=lim)
        asi_imgs = reform(asi_imgs,[ncommon_time,product(lim.image_size)])
        the_info = mltimg_info[site]
        asi_index = the_info.asi_index
        mltimg_index = the_info.mltimg_index
        pixel_count = the_info.pixel_count

        for pixel_id=0, pixel_count-1 do begin
            imcs[*,mltimg_index[pixel_id]] += 1
            imfs[*,mltimg_index[pixel_id]] += asi_imgs[*,asi_index[pixel_id]]
        endfor
    endforeach
    imfs = imfs/imcs
    imfs = reform(imfs, [ncommon_time,isz,isz])

;---Rotate from mlon to mlt.
    midn_mlons = themis_asi_midn_mlon(common_times)
    for ii=0,ncommon_time-1 do begin
        imfs[ii,*,*] = rot(reform(imfs[ii,*,*]), midn_mlons[ii])
    endfor

    index = where(finite(imfs,nan=1), count)
    if count ne 0 then imfs[index] = 0

;---Prepare to plot.
    sgopen, 0, xsize=isz, ysize=isz, xchsz=xchsz, ychsz=ychsz

    tmp = smkarthm(0,2*!dpi,50,'n')
    circ_x = cos(tmp)
    circ_y = sin(tmp)
    mlats = make_bins([min_mlat,90], 10, inner=1)
    tpos = [0.1,0.1,0.9,0.9]
    stop
    foreach time, common_times, time_id do begin
;time_id = 47d*60/3+30/3
        sgtv, bytscl(rotate(reform(imfs[time_id,*,*]),5),min=-800,max=800), ct=70, position=tpos
        plot, [-1,1], [-1,1], $
            xstyle=5, ystyle=5, $
            noerase=1, nodata=1, position=tpos
        foreach mlat, mlats do begin
            r = (90-mlat)/(90-min_mlat)
            plots, r*circ_x, r*circ_y, linestyle=1
            xyouts, r*cos(!dpi*0.25),r*sin(!dpi*0.25),data=1, string(mlat,format='(I0)'), alignment=0.5
        endforeach
        plots, [-1,1], [0,0], linestyle=1
        plots, [0,0], [-1,1], linestyle=1
        xyouts, 0,1,data=1, '12', alignment=0.5
        xyouts, 0,-1,data=1, '00', alignment=0.5
        xyouts, -1,0,data=1,'18', alignment=0.5
        xyouts, 1,0,data=1, '06', alignment=0.5

        tx = tpos[0]+xchsz*0.5
        ty = tpos[1]+ychsz*0.2
        xyouts,tx,ty,normal=1, time_string(common_times[time_id])
;stop
    endforeach


end
