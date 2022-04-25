;+
; Plot the mapping from count to width.
;-

test = 0

max_count = 65535
norm_count = findgen(max_count+1)
norm_windows = exp((max_count-norm_count+1e4)/1e4)*2+3


xticklen_chsz = -0.3
yticklen_chsz = -0.4
margins = [8,4,2,1]
poss = panel_pos(pansize=[5,2], fig_size=fsz, margins=margins)

plot_file = join_path([srootdir(),'asf_cal_plot_count_map.pdf'])
if keyword_set(test) then plot_file = 0
sgopen, plot_file, xsize=fsz[0], ysize=fsz[1], xchsz=xchsz, ychsz=ychsz, hsize=hsize

    xrange = [0d,65535]
    xstep = 2e4
    xminor = 4
    xtickv = make_bins(xrange,xstep, inner=1)
    xticks = n_elements(xtickv)-1
    xtitle = "r', weighted count (#)"
    xlog = 0

    yrange = [1,1e4]
    ytickv = [1,10,100,1000,10000]
    yticks = n_elements(ytickv)-1
    ytickn = ['1','10','100','1000','10000']
    yminor = 10
    ytitle = 'w, window size (sec)'
    ylog = 1

    tpos = poss
    xticklen = xticklen_chsz*ychsz/(tpos[3]-tpos[1])
    yticklen = yticklen_chsz*xchsz/(tpos[2]-tpos[0])

    plot, xrange, yrange, $
        xstyle=5, ystyle=5, nodata=1, noerase=1, position=tpos, ylog=ylog, xlog=xlog
    plots, norm_count, norm_windows
    foreach val, [1,2,3,4,5,6]*1e4 do oplot, val+[0,0], yrange, linestyle=1
    foreach val, ytickv do oplot, xrange, val+[0,0], linestyle=1

    plot, xrange, yrange, $
        xstyle=1, xrange=xrange, xtickv=xtickv, xticks=xticks, xminor=xminor, xtitle=xtitle, xticklen=xticklen, $
        ystyle=1, yrange=yrange, ytickv=ytickv, yticks=yticks, yminor=yminor, ytitle=ytitle, yticklen=yticklen, $
        position=tpos, nodata=1, noerase=1, ylog=ylog, xlog=xlog

    

if keyword_set(test) then stop
sgclose

end
