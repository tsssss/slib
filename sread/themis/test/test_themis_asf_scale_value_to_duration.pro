;+
; Test specific site, pixel, and time_range.
;-



function test_scale_value_to_min_duration, xxs
;    min_durations = exp(xxs/1e4)
;    return, (1-(min_durations-1)/(max(min_durations)-1))*600+1
;    return, exp((2e4/xxs)^1.5)*10
;    return, 1e19/xxs^4
    return, 0.5e3/(xxs/0.5e4)^1.5
end


function test_themis_asf_scale_value_to_duration, input_data, xx=xx, yy=yy

    the_data = smooth(input_data,3, edge_mirror=1, nan=1)
    min_data = min(the_data)
    the_data = the_data-min_data
    value_range = [0,65535]
    ndata = n_elements(the_data)
    

    value_bins = make_bins(value_range, 1e3)
    ; An empirical adaptive threshold to exclude fluctuations due to aurora:
    ; 1. Short duration fluctuations (several min) like auroral streamers.
    ; 2. Longer duration fluctuations (several 10 min) like the stable arcs.
    min_durations = test_scale_value_to_min_duration(value_bins)

    ; Sample merged_data to get an overall AND smooth trend of the data.
    sample_indexs = []
    the_values = []
    the_durations = []
    foreach value, value_bins, value_id do begin
        tindex = where(the_data ge value, count)
        if count eq 0 then continue
        the_index = time_to_range(tindex,time_step=1)
        durations = the_index[*,1]-the_index[*,0]
;        the_duration = min_durations[value_id]
;        the_duration = 6400000d/value
;        the_duration = 0
;        tindex = where(durations ge the_duration, count)
;        if count eq 0 then continue
;        the_index = the_index[tindex,*]
;        sample_indexs = [sample_indexs,the_index]
;        plot, the_data, xstyle=1, yrange=[1e3,1e6], ylog=1
;        plots, [0,ndata-1], value+[0,0], color=sgcolor('red')
;        plots, the_index, the_data[the_index], psym=1, color=sgcolor('red')
        the_values = [the_values,value]
        the_durations = [the_durations,max(durations)]
    endforeach
    xx = the_values
    yy = the_durations

    return, sample_indexs
;    sgopen, 0, size=[12,4]
;
;    plot, the_data, xstyle=1, yrange=[1e3,1e6], ylog=1
;    plots, sample_indexs, sample_values, color=sgcolor('red'), psym=-1
;    stop

end

test_list = list()
test_list.add, dictionary($
    'site', 'chbg', $
    'pixel2d', [40,140], $
    'label', 'cloud', $
    'time_range', ['2015-01-01/00:00','2015-01-01/11:00'] )
test_list.add, dictionary($
    'site', 'atha', $
    'pixel2d', [100,140], $
    'label', 'cloud', $
    'time_range', ['2015-01-01/00:00','2015-01-01/11:00'] )
test_list.add, dictionary($
    'site', 'inuv', $
    'pixel2d', [124,200], $
    'label', 'moon reflection', $
    'time_range', ['2008-01-19/01:47:15','2008-01-19/16:27:03'] )
test_list.add, dictionary($
    'site', 'inuv', $
    'pixel2d', [108,056], $
    'label', 'moon pass', $
    'time_range', ['2008-01-19/01:47:15','2008-01-19/16:27:03'] )

test_list.add, dictionary($
    'site', 'gako', $
    'pixel2d', [48,76], $
    'label', 'stable arc', $
    'time_range', ['2016-10-13/04:06:15','2016-10-13/14:54:03'] )
        
        
ntest = n_elements(test_list)
colors = get_color(ntest)
plot_file = join_path([srootdir(),'test_themis_asf_scale_value_to_duration_v02.pdf'])
sgopen, plot_file, size=[4,4], xchsz=xchsz, ychsz=ychsz, test=1
tpos = sgcalcpos(1, margin=[7,4,2,1])
plot, [0,1],[0,1], xlog=1, ylog=1, psym=-1, xrange=[1e3,1e5], yrange=[0.1,1e5], position=tpos, $
    xstyle=1, ystyle=1, xtitle='ASI count value (#)', ytitle='Max duration (# of rec)', $
    xticklen=-0.02, yticklen=-0.02

foreach test_info, test_list, test_id do begin
    site = test_info['site']
    time_range = time_double(test_info['time_range'])
    pixel2d = test_info['pixel2d']
    label = test_info['label']
    the_var = 'thg_asf_'+site+'_count_'+strjoin(string(pixel2d,format='(I03)'),'_')
    if check_if_update(the_var, time_range) then begin
        asf_var = themis_read_asf(time_range, site=site, get_name=1)
        if check_if_update(asf_var, time_range) then asf_var = themis_read_asf(time_range, site=site)

        asf_images = get_var_data(asf_var, times=times)
        the_counts = asf_images[*,pixel2d[0],pixel2d[1]]
        store_data, the_var, times, the_counts
        add_setting, the_var, smart=1, dictionary($
            'display_type', 'scalar', $
            'short_name', label, $
            'unit', '#', $
            'ylog', 1, $
            'yrange', [1e3,1e5] )
    endif
    the_counts = get_var_data(the_var, times=times)
    min_count = min(the_counts)
    time_step = times[1]-times[0]
    
    color = colors[test_id]
    sample_indexs = test_themis_asf_scale_value_to_duration(the_counts, xx=xx, yy=yy)
    oplot, xx>1, yy, psym=-1, color=color
    ; Print the linear fit of log-log line.
;    res = linfit(alog10(xx), alog10(yy>1))
;    print, res
    tx = tpos[0]+xchsz*0.5
    ty = tpos[1]+ychsz*(test_id+0.5)
    xyouts, tx,ty,normal=1, strupcase(site)+', '+label, color=color
endforeach

xx = make_bins([0,65535], 1e3)>1
yy = test_scale_value_to_min_duration(xx)
oplot, xx, yy, color=sgcolor('black')

sgclose
stop



test_list = list()
;test_list.add, dictionary($
;    'site', 'inuv', $
;    'pixel2d', [68,136], $
;    'label', 'moon glow weak', $
;    'time_range', ['2008-01-19/01:47:15','2008-01-19/16:27:03'] )
test_list.add, dictionary($
    'site', 'inuv', $
    'pixel2d', [40,140], $
    'label', 'streamers+moon glow', $
    'time_range', ['2008-01-19/01:47:15','2008-01-19/16:27:03'] )
;test_list.add, dictionary($
;    'site', 'inuv', $
;    'pixel2d', [120,092], $
;    'label', 'moon ring', $
;    'time_range', ['2008-01-19/01:47:15','2008-01-19/16:27:03'] )
test_list.add, dictionary($
    'site', 'inuv', $
    'pixel2d', [124,200], $
    'label', 'moon reflection', $
    'time_range', ['2008-01-19/01:47:15','2008-01-19/16:27:03'] )
test_list.add, dictionary($
    'site', 'inuv', $
    'pixel2d', [108,056], $
    'label', 'moon pass', $
    'time_range', ['2008-01-19/01:47:15','2008-01-19/16:27:03'] )
    
test_list.add, dictionary($
    'site', 'gako', $
    'pixel2d', [48,76], $
    'label', 'stable arc', $
    'time_range', ['2016-10-13/04:06:15','2016-10-13/14:54:03'] )
;    'time_range', ['2008-01-19/01:47:15','2008-01-19/16:27:03'] )
;test_list.add, dictionary($
;    'site', 'gako', $
;    'pixel2d', [50,130], $
;    'label', 'strong arc', $
;    'time_range', ['2016-10-13/04:06:15','2016-10-13/14:54:03'] )
test_list.add, dictionary($
    'site', 'gako', $
    'pixel2d', [80,140], $
    'label', 'strong arc', $
    'time_range', ['2016-10-13/04:06:15','2016-10-13/14:54:03'] )
test_list.add, dictionary($
    'site', 'gako', $
    'pixel2d', [210,80], $
    'label', 'moon below', $
    'time_range', ['2016-10-13/04:06:15','2016-10-13/14:54:03'] )
test_list.add, dictionary($
    'site', 'gako', $
    'pixel2d', [210,70], $
    'label', 'moon pass', $
    'time_range', ['2016-10-13/04:06:15','2016-10-13/14:54:03'] )
;test_list.add, dictionary($
;    'site', 'gako', $
;    'pixel2d', [45,210], $
;    'label', 'moon reflection', $
;    'time_range', ['2016-10-13/04:06:15','2016-10-13/14:54:03'] )

ntest = n_elements(test_list)
colors = get_color(ntest)
plot_file = join_path([srootdir(),'test_themis_asf_scale_value_to_duration_v01.pdf'])
sgopen, plot_file, size=[4,4], xchsz=xchsz, ychsz=ychsz, test=0
tpos = sgcalcpos(1, margin=[7,4,2,1])
plot, [0,1],[0,1], xlog=1, ylog=1, psym=-1, xrange=[1e3,1e5], yrange=[0.1,1e5], position=tpos, $
    xstyle=1, ystyle=1, xtitle='ASI count value (#)', ytitle='Max duration (# of rec)', $
    xticklen=-0.02, yticklen=-0.02

foreach test_info, test_list, test_id do begin
    site = test_info['site']
    time_range = time_double(test_info['time_range'])
    pixel2d = test_info['pixel2d']
    label = test_info['label']
    the_var = 'thg_asf_'+site+'_count_'+strjoin(string(pixel2d,format='(I03)'),'_')
    if check_if_update(the_var, time_range) then begin
        asf_var = themis_read_asf(time_range, site=site, get_name=1)
        if check_if_update(asf_var, time_range) then asf_var = themis_read_asf(time_range, site=site)

        asf_images = get_var_data(asf_var, times=times)
        the_counts = asf_images[*,pixel2d[0],pixel2d[1]]
        store_data, the_var, times, the_counts
        add_setting, the_var, smart=1, dictionary($
            'display_type', 'scalar', $
            'short_name', label, $
            'unit', '#', $
            'ylog', 1, $
            'yrange', [1e3,1e5] )
    endif
    the_counts = get_var_data(the_var, times=times)
    min_count = min(the_counts)
    time_step = times[1]-times[0]
    
    color = colors[test_id]
    sample_indexs = test_themis_asf_scale_value_to_duration(the_counts, xx=xx, yy=yy)
    oplot, xx>1, yy, psym=-1, color=color
    ; Print the linear fit of log-log line.
;    res = linfit(alog10(xx), alog10(yy>1))
;    print, res
    tx = tpos[0]+xchsz*0.5
    ty = tpos[1]+ychsz*(test_id+0.5)
    xyouts, tx,ty,normal=1, strupcase(site)+', '+label, color=color
endforeach

xx = make_bins([0,65535], 1e3)>1
yy = test_scale_value_to_min_duration(xx)
oplot, xx, yy, color=sgcolor('black')

sgclose

end