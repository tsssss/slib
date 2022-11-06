;+
; Calculate the lower envelope for the time series at a certain pixel.
;-

test = 1

event_list = list()
event_list.add, dictionary($
    'site', 'gako', $
    'time', '2016-10-13/12:10', $
    'pixels', list([190,64]), $
    'pixel_labels', ['stable arc'] )
event_list.add, dictionary($
    'site', 'inuv', $
    'time', '2008-01-19/07:16', $
    'pixels', list([140d,60],[130,160]), $
    'pixel_labels', ['moon','streamer'] )


sample_widths = [250,50,10]
nsample_width = n_elements(sample_widths)
sample_colors = sgcolor(['blue','purple','red','cyan'])


ypads = []
nrow = 0
foreach event, event_list do begin
    npan = n_elements(event.pixel_labels)
    nrow += npan
    if npan gt 1 then ypads = [ypads,fltarr(npan-1)+0.4]
    ypads = [ypads,4]
endforeach
ypads = ypads[0:-2]
margins = [10,3,2,1]
poss = panel_pos(pansize=[5,1.2], nypan=nrow, ypads=ypads, fig_size=fsz, margins=margins)
ct = 59
zrange = [0d,65535]
image_size = [256d,256]
color_top = 254
ct = 49
xticklen_chsz = -0.3
yticklen_chsz = -0.4
psym = 1
fig_letters = letters(n_elements(event_list))
time_step = 3d

plot_file = join_path([srootdir(),'asf_cal_plot_low_env.pdf'])
if keyword_set(test) then plot_file = 0
sgopen, plot_file, xsize=fsz[0], ysize=fsz[1], xchsz=xchsz, ychsz=ychsz, hsize=hsize

pan_id = 0
foreach event, event_list, event_id do begin
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

    foreach pixel, pixels, pixel_id do begin
        id_str = string(pan_id+1,format='(I0)')
        xtickformat = '(A1)'
        if pixel_id eq n_elements(pixels)-1 then xtickformat = ''

    ;---Draw pixel counts.
        tpos = poss[*,pan_id]
        xticklen = xticklen_chsz*ychsz/(tpos[3]-tpos[1])
        yticklen = yticklen_chsz*xchsz/(tpos[2]-tpos[0])

        plot, xrange, yrange, $
            xstyle=5, ystyle=5, xrange=xrange, yrange=yrange, $
            position=tpos, nodata=1, noerase=1

        xxs = times
        yys = imgs_raw[*,pixel[0],pixel[1]]
        plots, xxs, yys
        foreach sample_width, sample_widths, sample_id do begin
            tyy = calc_lower_limit_using_window(yys, sample_width)
            plots, xxs, tyy, color=sample_colors[sample_id]
        endforeach
        plots, xrange, min(yys)+[0,0], linestyle=1

        plot, xrange, yrange, $
            xstyle=1, xrange=xrange, xtickv=xtickv, xticks=xticks, xminor=xminor, xtickname=xtickn, xticklen=xticklen, $
            ystyle=1, yrange=yrange, ytickv=ytickv, yticks=yticks, yminor=yminor, ytitle=ytitle, yticklen=yticklen, $
            position=tpos, nodata=1, noerase=1, xtickformat=xtickformat

;        plots, time+[0,0], yrange, linestyle=1
        tx = tpos[0]-xchsz*8
        ty = tpos[3]-ychsz*0.8
        msg = fig_letters[event_id]+'-'+string(pixel_id+1,format='(I0)')+')'
        xyouts, tx,ty,normal=1, msg
        
        tx = tpos[2]-xchsz*0.5
        ty = tpos[3]-ychsz*1
        msg = strupcase(site)
        xyouts, tx,ty,msg, normal=1, alignment=1
        
        ty = tpos[3]-ychsz*2
        msg = 'Pixel ('+strjoin(string(pixel,format='(I0)'),',')+')'
        xyouts, tx,ty,msg, normal=1, alignment=1
        
        if pan_id eq 0 then begin
            tx = tpos[0]+xchsz*0.5
            foreach sample_width, sample_widths, sample_id do begin
                sample_window = sample_width*time_step
                ty = tpos[3]-(sample_id+1)*ychsz
                tmp = convert_coord(xrange[0]+sample_window,0, data=1, to_normal=1)
                msg = string(sample_window,format='(I0)')+' sec'
                xyouts, tx+xchsz*5,ty,msg, normal=1, color=sample_colors[sample_id], alignment=1
                plots, normal=1, $
                    tx+xchsz*6+[0,tmp[0]-tpos[0]], ty+ychsz*0.3+[0,0], color=sample_colors[sample_id]
            endforeach
            ty = tpos[3]-(nsample_width+1)*ychsz
            msg = 'min val'
            xyouts, tx+xchsz*5,ty,msg, normal=1, alignment=1
            plots, normal=1, tx+xchsz*6+[0,5]*xchsz,ty+ychsz*0.3+[0,0], linestyle=1
        endif

        pan_id += 1
    endforeach
endforeach

if keyword_set(test) then stop
sgclose


end
