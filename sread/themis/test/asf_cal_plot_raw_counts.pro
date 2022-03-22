;+
; Plot raw counts at several selected pixels.
;-

test = 1

event_list = list()
event_list.add, dictionary($
    'site', 'gako', $
    'time', '2016-10-13/12:10', $
    'pixels', list([32,32],[190,64]), $
    'pixel_labels', ['edge','stable arc'] )
event_list.add, dictionary($
    'site', 'inuv', $
    'time', '2008-01-19/07:16', $
    'pixels', list([32,32],[140d,60],[130,160]), $
    'pixel_labels', ['edge','moon','streamer'] )

nrow = n_elements(event_list)
margins = [2,3,2,4]
poss = panel_pos(pansize=[1,1]*2, panid=0, $
    xpans=[1,2], ypans=fltarr(nrow)+1, xpads=[8], ypad=4, fig_size=fsz, margins=margins)
zrange = [0d,65535]
image_size = [256d,256]
color_top = 254
ct = 49
xticklen_chsz = -0.3
yticklen_chsz = -0.4
psym = 1
pixel_colors = sgcolor(['green','red','purple','yellow','cyan'])

plot_file = join_path([srootdir(),'asf_cal_plot_raw_counts.pdf'])
if keyword_set(test) then plot_file = 0
sgopen, plot_file, xsize=fsz[0], ysize=fsz[1], xchsz=xchsz, ychsz=ychsz, hsize=hsize

cbpos = poss[*,0,0]
cbpos[1] = cbpos[3]+ychsz*0.5
cbpos[3] = cbpos[1]+ychsz*0.5
ztitle = 'Raw count (#)'
zstep = 2e4
ztickv = make_bins(zrange,zstep, inner=1)
zticks = n_elements(ztickv)-1
sgcolorbar, findgen(color_top+1), position=cbpos, horizontal=1, $
    ztitle=ztitle, zrange=zrange, zstyle=1, zticks=zticks, ztickv=ztickv;, zcharsize=1

foreach event, event_list, event_id do begin
    id_str = string(event_id+1,format='(I0)')
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

;---Draw 2d image.
    img_raw = reform(imgs_raw[time_id,*,*])
    tpos = poss[*,0,event_id]
    sgtv, bytscl(img_raw, min=zrange[0], max=zrange[1], top=color_top), $
        position=tpos, ct=ct
    tx = tpos[0]+xchsz*0.5
    ty = tpos[3]-ychsz*1
    msg = 'a-'+id_str+') '+strupcase(site)
    xyouts, tx,ty,normal=1, msg, color=sgcolor('black')
    ty = tpos[1]+ychsz*0.2
    msg = time_string(time)+' UT'
    xyouts, tx,ty,normal=1, msg, color=sgcolor('black')

    xrange = [0,image_size[0]-1]
    yrange = [0,image_size[1]-1]
    plot, xrange, yrange, $
        xstyle=5, ystyle=5, xrange=xrange, yrange=yrange, $
        position=tpos, nodata=1, noerase=1
    foreach pixel, pixels, pixel_id do begin
        tmp = convert_coord(pixel, data=1, to_normal=1)
        tx = tmp[0]
        ty = tmp[1]
        plots, tx,ty,normal=1, color=pixel_colors[pixel_id], psym=psym
        x1 = tx-xchsz*0
        y1 = ty+ychsz*2
        arrow, x1,y1-ychsz*0.3, tx,ty+ychsz*0.8, normal=1, solid=1, hsize=hsize
        xyouts, x1,y1,normal=1, pixel_labels[pixel_id], alignment=0.5
    endforeach



;---Draw pixel counts.
    tpos = poss[*,1,event_id]
    xticklen = xticklen_chsz*ychsz/(tpos[3]-tpos[1])
    yticklen = yticklen_chsz*xchsz/(tpos[2]-tpos[0])

    xrange = time_range
    xstep = 15*60d
    xminor = 5
    xtickv = make_bins(xrange, xstep, inner=1)
    xticks = n_elements(xtickv)-1
    xtickformat = ''
    xtickn = time_string(xtickv, tformat='hh:mm')
    xtickn[0] = time_string(xtickv[0], tformat='YYYY-MM-DD')

    yrange = zrange
    ystep = 2e4
    yminor = 4
    ytickv = make_bins(yrange,ystep, inner=1)
    yticks = n_elements(ytickv)-1
    ytitle = 'Raw count (#)'

    plot, xrange, yrange, $
        xstyle=5, ystyle=5, xrange=xrange, yrange=yrange, $
        position=tpos, nodata=1, noerase=1

    xxs = times
    foreach pixel, pixels, pixel_id do begin
        yys = imgs_raw[*,pixel[0],pixel[1]]
        plots, xxs, yys, color=pixel_colors[pixel_id]
    endforeach

    plot, xrange, yrange, $
        xstyle=1, xrange=xrange, xtickv=xtickv, xticks=xticks, xminor=xminor, xtickname=xtickn, xticklen=xticklen, $
        ystyle=1, yrange=yrange, ytickv=ytickv, yticks=yticks, yminor=yminor, ytitle=ytitle, yticklen=yticklen, $
        position=tpos, nodata=1, noerase=1

    plots, time+[0,0], yrange, linestyle=1
    tx = tpos[0]
    ty = tpos[3]+ychsz*0.5
    msg = 'b-'+id_str+') Count at fixed pixel'
    xyouts, tx,ty,normal=1, msg

endforeach

if keyword_set(test) then stop
sgclose

end
