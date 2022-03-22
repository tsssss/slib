;+
; Plot ASI images before and after the calibration.
;-

test = 0

event_list = list()
event_list.add, dictionary($
    'site', 'inuv', $
    'time', '2008-02-15/07:49:12', $
    'pixels', list([75,60],[65,90]), $
    'pixel_labels', ['moon','streamer'] )

;event_list.add, dictionary($
;    'site', 'gako', $
;    'time', '2016-10-13/12:10', $
;    'pixels', list([190,64]), $
;    'pixel_labels', ['stable arc'] )
;event_list.add, dictionary($
;    'site', 'inuv', $
;    'time', '2008-01-19/07:16', $
;    'pixels', list([140d,60],[130,160]), $
;    'pixel_labels', ['moon','streamer'] )

nrow = 0
nletter = 0
ypads = []
ypans = []
foreach event, event_list do begin
    npan = n_elements(event.pixel_labels)
    nrow += 1+npan
    nletter += 2
    ypads = [ypads,0.4+fltarr(npan),3]
    ypans = [ypans,1,fltarr(npan)+0.6]
endforeach
ypads = ypads[0:-2]
margins = [1,3,2,4]
poss = panel_pos(pansize=[1,1]*2, panid=0, $
    xpans=[1,1,1], ypans=ypans, xpad=0.5, ypads=ypads, fig_size=fsz, margins=margins)
zrange_raw = [0d,65535]
zrange_cal = [0d,10000]
color_top = 254
ct = 49
fig_letters = letters(nletter)
xticklen_chsz = -0.3
yticklen_chsz = -0.4
image_size = [256d,256]
psym = 1


plot_file = join_path([srootdir(),'asf_cal_plot_old_vs_new.pdf'])
if keyword_set(test) then plot_file = 0
sgopen, plot_file, xsize=fsz[0], ysize=fsz[1], xchsz=xchsz, ychsz=ychsz, hsize=hsize

cbpos = poss[*,0,0]
cbpos[1] = cbpos[3]+ychsz*0.5
cbpos[3] = cbpos[1]+ychsz*0.5
cbpos[2] = poss[2,1,0]
ztitle = 'Raw count (#)'
zstep = 2e4
ztickv = make_bins(zrange_raw,zstep, inner=1)
zticks = n_elements(ztickv)-1
sgcolorbar, findgen(color_top+1), position=cbpos, horizontal=1, ct=ct, $
    ztitle=ztitle, zrange=zrange_raw, zstyle=1, zticks=zticks, ztickv=ztickv;, zcharsize=1

cbpos = poss[*,2,0]
cbpos[1] = cbpos[3]+ychsz*0.5
cbpos[3] = cbpos[1]+ychsz*0.5
ztitle = 'Cal count (#)'
zstep = 5e3
ztickv = make_bins(zrange_cal,zstep, inner=1)
zticks = n_elements(ztickv)-1
sgcolorbar, findgen(color_top+1), position=cbpos, horizontal=1, ct=ct, $
    ztitle=ztitle, zrange=zrange_cal, zstyle=1, zticks=zticks, ztickv=ztickv;, zcharsize=1

panel_id = 0
letter_id = 0
foreach event, event_list, event_id do begin
    letter = fig_letters[letter_id]

    site = event.site
    time = time_double(event.time)
    pixels = event.pixels
    pixel_labels = event.pixel_labels

;---Load data.
    prefix = 'thg_'+site+'_'
    asf_var = prefix+'asf'
    time_range = time-(time mod 3600)+[0,3600]
    if check_if_update(asf_var, time_range) then themis_read_asf, time_range, site=site
    get_data, asf_var, times, imgs_raw
    tmp = min(times-time, abs=1, time_id)
    asf_cal_var = asf_var+'_cal'
    if check_if_update(asf_cal_var, time_range) then themis_asi_cal_brightness, asf_var, newname=asf_cal_var
    get_data, asf_cal_var, times, imgs_cal

;---Draw 2d raw image.
    img_raw = reform(imgs_raw[time_id,*,*])
    tpos = poss[*,0,panel_id]
    sgtv, bytscl(img_raw, min=zrange_raw[0], max=zrange_raw[1], top=color_top), $
        position=tpos, ct=ct
    tx = tpos[0]+xchsz*0.5
    ty = tpos[3]-ychsz*1
    msg = letter+'-1) Raw'
    xyouts, tx,ty,normal=1, msg, color=sgcolor('black')
    ty = tpos[1]+ychsz*0.2
    msg = time_string(time)+' UT'
    xyouts, tx,ty,normal=1, msg, color=sgcolor('black')

;---Draw 2d background image.
    img_cal = reform(imgs_cal[time_id,*,*])
    imgs_bg = imgs_raw-imgs_cal
    img_bg = reform(imgs_bg[time_id,*,*])
    tpos = poss[*,1,panel_id]
    sgtv, bytscl(img_bg, min=zrange_raw[0], max=zrange_raw[1], top=color_top), $
        position=tpos, ct=ct
    tx = tpos[0]+xchsz*0.5
    ty = tpos[3]-ychsz*1
    msg = letter+'-2) Background'
    xyouts, tx,ty,normal=1, msg, color=sgcolor('black')
    ty = tpos[1]+ychsz*0.2
    msg = time_string(time)+' UT'
    xyouts, tx,ty,normal=1, msg, color=sgcolor('black')

;---Draw 2d calibrated image.
    tpos = poss[*,2,panel_id]
    sgtv, bytscl(img_cal, min=zrange_cal[0], max=zrange_cal[1], top=color_top), $
        position=tpos, ct=ct
    tx = tpos[0]+xchsz*0.5
    ty = tpos[3]-ychsz*1
    msg = letter+'-3) Calibrated'
    xyouts, tx,ty,normal=1, msg, color=sgcolor('black')
    ty = tpos[1]+ychsz*0.2
    msg = time_string(time)+' UT'
    xyouts, tx,ty,normal=1, msg, color=sgcolor('black')


;---Add pixels.
    pixels = event.pixels
    pixel_labels = event.pixel_labels
    for ii=0,2 do begin
        tpos = poss[*,ii,panel_id]
        plot, [0,image_size[0]-1], [0,image_size[1]-1], $
            xstyle=5, ystyle=5, nodata=1, noerase=1, position=tpos
        foreach pixel, pixels, pixel_id do begin
            tmp = convert_coord(pixel, data=1, to_normal=1)
            tx = tmp[0]
            ty = tmp[1]
            plots, tx,ty,normal=1, psym=psym
            x1 = tx-xchsz*0
            y1 = ty+ychsz*2
            arrow, x1,y1-ychsz*0.3, tx,ty+ychsz*0.8, normal=1, solid=1, hsize=hsize
            xyouts, x1,y1,normal=1, pixel_labels[pixel_id], alignment=0.5
        endforeach

    endfor


;---Prepare labels.
    xrange = time_range
    xstep = 15*60d
    xminor = 5
    xtickv = make_bins(xrange, xstep, inner=1)
    xticks = n_elements(xtickv)-1
    xtickformat = ''
    xtickn = time_string(xtickv, tformat='hh:mm')
    xtickn[0] = time_string(xtickv[0], tformat='YYYY-MM-DD')

    yrange = zrange_raw
    ystep = 2e4
    yminor = 4
    ytickv = make_bins(yrange,ystep, inner=1)
    yticks = n_elements(ytickv)-1
    ytitle = 'Raw count (#)'


;---Draw counts.
    letter_id += 1
    letter = fig_letters[letter_id]
    foreach pixel, event.pixels, pixel_id do begin
        panel_id += 1
        tpos = poss[*,0,panel_id]
        tpos[0] = 9*xchsz
        tpos[2] = 1-2*xchsz
        xticklen = xticklen_chsz*ychsz/(tpos[3]-tpos[1])
        yticklen = yticklen_chsz*xchsz/(tpos[2]-tpos[0])
        xtickformat = '(A1)'
        if pixel_id eq n_elements(event.pixels)-1 then xtickformat = ''

        plot, xrange, yrange, $
            xstyle=5, ystyle=5, xrange=xrange, yrange=yrange, $
            position=tpos, nodata=1, noerase=1

        xxs = times
        yys = imgs_raw[*,pixel[0],pixel[1]]
        plots, xxs, yys
        yys = imgs_bg[*,pixel[0],pixel[1]]
        plots, xxs, yys, color=sgcolor('red')

        plot, xrange, yrange, $
            xstyle=1, xrange=xrange, xtickv=xtickv, xticks=xticks, xminor=xminor, xtickname=xtickn, xticklen=xticklen, $
            ystyle=1, yrange=yrange, ytickv=ytickv, yticks=yticks, yminor=yminor, ytitle=ytitle, yticklen=yticklen, $
            position=tpos, nodata=1, noerase=1, xtickformat=xtickformat

        plots, time+[0,0], yrange, linestyle=1

        tx = tpos[0]+xchsz*1
        ty = tpos[3]-ychsz*1
        msg = 'Raw'
        xyouts, tx+xchsz*6,ty,msg, normal=1, alignment=0
        plots, normal=1, tx+xchsz*0+[0,5]*xchsz,ty+ychsz*0.3+[0,0], color=sgcolor('black')
        ty = tpos[3]-ychsz*2
        msg = 'Background'
        xyouts, tx+xchsz*6,ty,msg, normal=1, alignment=0
        plots, normal=1, tx+xchsz*0+[0,5]*xchsz,ty+ychsz*0.3+[0,0], color=sgcolor('red')

        tx = tpos[2]-xchsz*0.5
        ty = tpos[3]-ychsz*1
        msg = strupcase(site)
        xyouts, tx,ty,msg, normal=1, alignment=1

        ty = tpos[3]-ychsz*2
        msg = 'Pixel ('+strjoin(string(pixel,format='(I0)'),',')+')'
        xyouts, tx,ty,msg, normal=1, alignment=1

        tx = tpos[0]-xchsz*8
        ty = tpos[3]-ychsz*0.8
        msg = letter+'-'+string(pixel_id+1,format='(I0)')+')'
        xyouts, tx,ty,normal=1, msg
    endforeach
    panel_id += 1
    letter_id += 1
endforeach

if keyword_set(test) then stop
sgclose
end
