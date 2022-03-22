;+
; Calibrate the background count for given asf image.
; This is a previous version, not current.
;-

function calc_lower_limit_using_smooth, img_raw, time_width

    ; Get the moving average at a small window.
    time_bg = smooth(img_raw, $
        time_width, nan=1, edge_mirror=1)
    ; Offset the moving average by the local noise level.
    img_cal = img_raw-time_bg
    img_offset = smooth(abs(img_cal), time_width, nan=1, edge_mirror=1)
    time_bg -= img_offset

    return, time_bg

end

; Use window will introduce artificial structures in 2D image.
function calc_lower_limit_using_window, img_raw, time_width

    ; Get the sections.
    ntime = n_elements(img_raw)
    width1 = time_width

    nx = floor(ntime/width1)
    section_times = smkarthm(0,ntime-1, nx, 'n')
    nsection = n_elements(section_times)-1
    times = dindgen(ntime)

    xxs = fltarr(nsection)
    yys = fltarr(nsection)
    for kk=0,nsection-1 do begin
        yys[kk] = min(img_raw[section_times[kk]:section_times[kk+1]-1], index)
;        xxs[kk] = section_times[kk]+index
        xxs[kk] = (section_times[kk]+section_times[kk+1])*0.5  ; this works slightly better than above.
    endfor
    tx = 0
    ty = min([yys[tx],img_raw[tx]])
    xxs = [tx,xxs]
    yys = [ty,yys]
    tx = -1
    ty = min([yys[tx],img_raw[tx]])
    xxs = [xxs,nsection+tx]
    yys = [yys,ty]


    time_bg = smooth(interpol(yys,xxs,times), width1*0.5, edge_mirror=1)
;    time_bg = interpol(yys,xxs,times)
;
;    img_cal = img_raw-time_bg
;    img_offset = min(img_cal)
;    time_bg += img_offset

    return, time_bg

end

pro themis_asi_cal_brightness1, asf_var, newname=newname, test_time=test_time

    if n_elements(newname) eq 0 then newname = asf_var+'_norm'
;if n_elements(test_time) eq 0 then stop
;test_time = time_double(test_time)

    get_data, asf_var, times, imgs_raw, limits=lim
    image_size = lim.image_size
    ntime = n_elements(times)
    time_step = 3   ; sec.
    img_zrange = [1,65535]

;---Calculate a smooth background to extract fast moving structures.
    time_window = 3*60    ; sec.
    time_width = time_window/time_step
    time_bgs = imgs_raw
    max_count = 65535
    time_width_long = 15*60/time_step


    for ii=0,image_size[0]-1 do begin
        for jj=0,image_size[1]-1 do begin
;            ii = 70
;            jj = 80
;ii = 190
;jj = 64

;ii = 64
;jj = 190

;ii = 140
;jj = 50

;ii = 130
;jj = 50

            bg_raw = imgs_raw[*,ii,jj]
            bg0 = bg_raw

        ;---Mean count is high -> moon -> need a smaller width.
            mean_count = mean(bg0)
            ; This scaling is empirical
            time_width = round((1-tanh((mean_count-1e4)/1e4))*0.5*(600-3)+3)
            time_width = round((1-tanh((mean_count-1e4)/0.5e4))*0.5*(600-3)+3)

            ; A smooth bg.
;            bg1 = calc_lower_limit_using_smooth(bg0, time_width)
;            bg2 = calc_lower_limit_using_window(bg0-bg1, 600)
 ;           bg_long = bg1+bg2
;            bg_long = calc_lower_limit_using_window(bg0, time_width)
            bg_long = calc_lower_limit_using_smooth(bg0, time_width)

;
            ; To further remove moon.
            index = where(bg0 ge max_count*0.9, count)
            if count ne 0 then begin
                bg_long[index] = bg0[index]
            endif

            time_bgs[*,ii,jj] = bg_long
;            stop
        endfor
    endfor

    imgs_cal = imgs_raw-time_bgs

    ; Calibrate overall count toward 0.
    time_bg0 = fltarr(ntime)
    for ii=0,ntime-1 do time_bg0[ii] = min(imgs_cal[ii,*,*])
    imgs_cal -= mean(time_bg0)


    index = where(imgs_raw eq max_count*0.9, count)
    if count ne 0 then imgs_cal[index] = 0
;    scale = 500d/stddev(imgs_cal, nan=1)
;    imgs_cal *= scale

stop

    sgopen, 0, xsize=256*2, ysize=256*2
    tpos = [0,0,1,1]
    ct = 49
    top_color = 254
    foreach time, times, time_id do begin
        sgtv, bytscl(reform(imgs_cal[time_id,*,*]),min=0,max=10000, top=top_color), position=tpos, ct=ct
        xyouts, 1,1,device=1, time_string(time)+' UT', color=sgcolor('black')
    endforeach
stop

    test_time = time_double('2015-10-05/09:57:30')
    tmp = min(times-test_time, abs=1, time_id)
    time = times[time_id]
    sgtv, bytscl(reform(imgs_cal[time_id,*,*]),min=0,max=10000, top=top_color), position=tpos, ct=ct
    xyouts, 1,1,device=1, time_string(time)+' UT', color=sgcolor('black')


stop

    store_data, newname, times, imgs_cal, limits=lim
    return


    imgs = time_bgs
    tmp = min(times-test_time, abs=1, time_id)
    timg = reform(imgs[time_id,*,*])
    width = 64+32d
    width = 128d
    bgx = fltarr(image_size)
    bgy = fltarr(image_size)
    for ii=0,image_size[0]-1 do begin
        tmp = reform(timg[ii,*])
        tbg = smooth(tmp, width, nan=1, edge_mirror=1)
        del = tmp-tbg
        offset = smooth(abs(del), width, nan=1, edge_mirror=1)
        tbg -= offset
        bgx[ii,*] = tbg
    endfor

    for jj=0,image_size[1]-1 do begin
        tmp = reform(timg[*,jj])
        tbg = smooth(tmp, width, nan=1, edge_mirror=1)
        del = tmp-tbg
        offset = smooth(abs(del), width, nan=1, edge_mirror=1)
        tbg -= offset
        bgy[*,jj] = tbg
    endfor

    ; Method 3: first x then y.
    bg2 = fltarr(image_size)
    for jj=0,image_size[1]-1 do begin
        tmp = reform(bgx[*,jj])
        tbg = smooth(tmp, width, nan=1, edge_mirror=1)
        del = tmp-tbg
        offset = smooth(abs(del), width, nan=1, edge_mirror=1)
        tbg -= offset
        bg2[*,jj] = tbg
    endfor

    ; Method 1: smooth image.
    tmp = timg
    bg0 = smooth(timg, width, nan=1, edge_mirror=1)
    del = tmp-bg0
    offset = smooth(abs(del), width, nan=1, edge_mirror=1)
    bg0 -= offset
    tmp[0:width-1,0:width-1] = img_zrange[1]

    ; Method 2: min of bgx and bgy.
    bg1 = bgx<bgy


    min_bg = median(bg1[0:20,0:20])
    max_bg = img_zrange[1]*0.9
    min_bg = 1e4
    max_bg = 6e4
    thres = 1.5e4
    thres_ratio = 0.15
    thres_width = 0.05
    thres_ratio = 0.
    thres_width = 0.3
    ww = (timg-min_bg)/(max_bg-min_bg)
    ww = (tanh((ww-thres_ratio)/thres_width)+1)*0.5

    bg0 = (1-ww)*bg0+ww*timg
    bg1 = (1-ww)*bg1+ww*timg
    bg2 = (1-ww)*bg2+ww*timg



    img_cal = reform(imgs_cal[time_id,*,*])

    sgopen, 0, xsize=image_size[0]*4, ysize=image_size[1]*2
    device, decomposed=0
    loadct, 49
    tv, bytscl(reform(tmp), max=img_zrange[1], min=img_zrange[0]), 0
    tv, bytscl(reform(bg0), max=img_zrange[1], min=img_zrange[0]), 1
    tv, bytscl(reform(bg1), max=img_zrange[1], min=img_zrange[0]), 2
    tv, bytscl(reform(bg2), max=img_zrange[1], min=img_zrange[0]), 3

    tv, bytscl(reform(timg), max=img_zrange[1]*0.15, min=img_zrange[0]), 4
    tv, bytscl(reform(img_cal+timg-bg1), max=img_zrange[1]*0.1, min=img_zrange[0]), 6
    tv, bytscl(reform(img_cal+timg-bg2), max=img_zrange[1]*0.1, min=img_zrange[0]), 7

    loadct, 70
    tv, bytscl(reform(img_cal), max=img_zrange[1]*0.02, min=-img_zrange[1]*0.02), 5


    stop
get_data, asi_var, times, imgs_raw, limits=lim
imgs_bg = themis_asi_calc_bg_count(imgs_raw)
imgs_cal = imgs_raw-imgs_bg

ntime = n_elements(times)
imgs_mean = fltarr(ntime)
foreach time, times, time_id do begin
    imgs_mean[time_id] = mean(imgs_raw[time_id,*,*])
endforeach

end


;counts = findgen(65535)
;tmp = map_count_to_weight(counts)
;stop

time_range = time_double(['2016-01-28/08:00','2016-01-28/09:00'])
site = 'snkq'
site = 'whit'
test_time = '2016-01-28/08:47:30'

;time_range = time_double(['2008-01-19/07:00','2008-01-19/08:00'])   ; moon and background fluctuations.
;site = 'inuv'
;test_time = '2008-01-19/07:04'
;
;time_range = time_double(['2016-10-13/12:00','2016-10-13/13:00'])   ; stable arc.
;site = 'gako'
;test_time = '2016-10-13/12:10'
;;
;time_range = time_double(['2015-12-02/08:00','2015-12-02/09:00'])   ; Homayon example.
;site = 'rank'
;test_time = '2015-12-02/08:10'
;
;
;time_range = time_double(['2008-02-13/02:00','2008-02-13/03:00'])   ; Chu+2015.
;site = 'gill'   ; gill, kuuj, snkq
;test_time = '2008-02-13/02:44'

time_range = time_double(['2015-10-05/09:00','2015-10-05/10:00'])   ; Homayon example
site = 'snkq'

;time_range = time_double(['2015-12-07/08:00','2015-12-07/09:00'])   ; Homayon example
;site = 'inuv'   ;'kuuj','gill','rank','fsim'


asi_var = 'thg_'+site+'_asf'
asi_norm_var = asi_var+'_norm'
if check_if_update(asi_var, time_range) then begin
    themis_read_asf, time_range, site=site
endif
;if check_if_update(asi_norm_var, time_range) then begin
    themis_asi_cal_brightness1, asi_var, test_time=test_time, newname=asi_norm_var
;endif

get_data, asi_norm_var, times, imgs_cal, limits=lim
stop
for time_id=50,100 do begin
    timg = reform(imgs_raw[time_id,*,*])
    tv, bytscl(timg,max=65535, min=5e3)
    msg = string(time_id)+string(mean(timg))
    xyouts, 5,5, device=1, msg, color=255
    wait, 0.5
endfor


end
