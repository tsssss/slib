;+
; Test specific site, pixel, and time_range.
;-


function test_themis_asf_calc_background, input_data, moon_angles, min_data=min_data, test=test

    the_data = smooth(input_data, 3, edge_mirror=1, nan=1)
    if n_elements(min_data) eq 0 then min_data = min(the_data)
    the_data = the_data-min_data
    value_range = [0d,65535]
    value_step = 1e3
;    trial_offsets = [0,0.25,0.5,0.75]*value_step
    trial_offsets = [0,0.5]*value_step
    ntrial = n_elements(trial_offsets)
    ndata = n_elements(the_data)
    common_indexs = findgen(ndata)

    trial_bgs = fltarr(ndata,ntrial)
    foreach trial_offset, trial_offsets, trial_id do begin
        value_bins = make_bins(value_range, value_step)+trial_offset
        nvalue = n_elements(value_bins)
        min_durations = themis_asf_scale_value_to_min_duration(value_bins)

        ; Sample merged_data to get an overall AND smooth trend of the data.
        sample_indexs = [0,ndata-1]
        value_durations = dblarr(nvalue)
        foreach value, value_bins, value_id do begin
            tindex = where(the_data ge value, count)
            if count eq 0 then continue
            the_index = time_to_range(tindex,time_step=1)
            durations = the_index[*,1]-the_index[*,0]
            value_durations[value_id] = max(durations)
            the_duration = min_durations[value_id]
            tindex = where(durations ge the_duration, count)
            if count eq 0 then continue
            the_index = the_index[tindex,*]
            sample_indexs = [sample_indexs,the_index[*]]
        endforeach

        max_val = max(the_data)
        the_index = where(the_data eq max_val, count)
        if count ge themis_asf_scale_value_to_min_duration(max_val) then sample_indexs = [sample_indexs,the_index]

        sample_indexs = sort_uniq(sample_indexs)
        sample_values = the_data[sample_indexs]
        sample_indexs0 = sample_indexs
        sample_values0 = sample_values


        ; sample_index are sparse at low values, need to add some more (but not too close).
        nsample_index = n_elements(sample_indexs)
        for ii=1,nsample_index-1 do begin
            i0 = sample_indexs[ii-1]+600
            i1 = sample_indexs[ii]-600
            if i0 gt i1 then continue
            iis = make_bins([i0,i1], 1200, inner=1)
            if n_elements(iis) eq 0 then continue
            sample_indexs = [sample_indexs,iis]
            ;        sample_values = [sample_values,fltarr(n_elements(iis))]
            sample_values = [sample_values,the_data[iis]]
        endfor
        index = sort_uniq_index(sample_indexs)
        sample_indexs = sample_indexs[index]
        sample_values = sample_values[index]
        nsample = n_elements(sample_indexs)


        ; Now we calc another set of sample_indexs, which estimates the lower envelope.
        middle_indexs = (sample_indexs[1:nsample-1]+sample_indexs[0:nsample-2])*0.5
        middle_values = fltarr(nsample-1)
        for ii=0,nsample-2 do begin
            i0 = sample_indexs[ii]
            i1 = sample_indexs[ii+1]
            middle_values[ii] = min(the_data[i0:i1])
        endfor

        middle_indexs = [0,middle_indexs,ndata-1]
        middle_values = [the_data[0],middle_values,the_data[ndata-1]]
        bg0 = interpol(middle_values, middle_indexs, common_indexs)

        dbg = smooth(the_data-bg0,3, edge_zero=1)
        index = where(dbg lt 0, count)
        if count ne 0 then begin
            sectors = time_to_range(index, time_step=1)
            nsector = n_elements(sectors)*0.5
            for ii=0,nsector-1 do begin
                i0 = sectors[ii,0]
                i1 = sectors[ii,1]
                tmp = min(dbg[i0:i1], index)
                middle_indexs = [middle_indexs,i0+index]
                middle_values = [middle_values,tmp+bg0[i0+index]]
            endfor
        endif
        index = sort_uniq_index(middle_indexs)
        middle_indexs = middle_indexs[index]
        middle_values = middle_values[index]
        ; bg1 is a step-wise background, almost works except introducing contours.
        trial_bgs[*,trial_id] = interpol(middle_values, middle_indexs, common_indexs)
    endforeach
    
    ;bg1 = fltarr(ndata)
    ;for ii=0,ndata-1 do bg1[ii] = min(trial_bgs[ii])
    bg1 = total(trial_bgs,2)/ntrial
    weight = (tanh((bg1-2.5e3)/5e3)+1)*0.5
    bg1 *= weight
    
;    plot, the_data, yrange=[1,65536], xstyle=1
;    oplot, bg1, color=sgcolor('red')
;    plots, middle_indexs, middle_values, psym=1, color=sgcolor('red')
;    oplot, bg1*weight, color=sgcolor('blue')
;    stop
    return, bg1+min_data
    

end
    



test_list = list()
test_list.add, dictionary($
    'site', 'inuv', $
    'pixel2d', [56,160], $
    'label', 'moon glow weak', $
    'time_range', ['2008-01-19/01:47:15','2008-01-19/16:27:03'] )
test_list.add, dictionary($
    'site', 'gako', $
    'pixel2d', [80,140], $
    'label', 'saturate arc', $
    'time_range', ['2016-10-13/04:06:15','2016-10-13/14:54:03'] )
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
    
    
;test_list.add, dictionary($
;    'site', 'inuv', $
;    'pixel2d', [36,144], $
;    'label', 'moon glow', $
;    'time_range', ['2008-01-19/01:47:15','2008-01-19/16:27:03'] )
;test_list.add, dictionary($
;    'site', 'inuv', $
;    'pixel2d', [128,128], $
;    'label', 'center', $
;    'time_range', ['2008-01-19/01:47:15','2008-01-19/16:27:03'] )
;test_list.add, dictionary($
;    'site', 'inuv', $
;    'pixel2d', [40,140], $
;    'label', 'streamers', $
;    'time_range', ['2008-01-19/01:47:15','2008-01-19/16:27:03'] )
;test_list.add, dictionary($
;    'site', 'inuv', $
;    'pixel2d', [120,092], $
;    'label', 'moon ring', $
;    'time_range', ['2008-01-19/01:47:15','2008-01-19/16:27:03'] )
;
;test_list.add, dictionary($
;    'site', 'gako', $
;    'pixel2d', [48,76], $
;    'label', 'stable arc', $
;    'time_range', ['2016-10-13/04:06:15','2016-10-13/14:54:03'] )
;test_list.add, dictionary($
;    'site', 'gako', $
;    'pixel2d', [50,130], $
;    'label', 'strong arc', $
;    'time_range', ['2016-10-13/04:06:15','2016-10-13/14:54:03'] )
;test_list.add, dictionary($
;    'site', 'gako', $
;    'pixel2d', [80,140], $
;    'label', 'saturate arc', $
;    'time_range', ['2016-10-13/04:06:15','2016-10-13/14:54:03'] )
;test_list.add, dictionary($
;    'site', 'gako', $
;    'pixel2d', [210,80], $
;    'label', 'moon below', $
;    'time_range', ['2016-10-13/04:06:15','2016-10-13/14:54:03'] )
;test_list.add, dictionary($
;    'site', 'gako', $
;    'pixel2d', [210,70], $
;    'label', 'moon pass', $
;    'time_range', ['2016-10-13/04:06:15','2016-10-13/14:54:03'] )
;test_list.add, dictionary($
;    'site', 'gako', $
;    'pixel2d', [45,210], $
;    'label', 'moon reflection', $
;    'time_range', ['2016-10-13/04:06:15','2016-10-13/14:54:03'] )

ntest = n_elements(test_list)
colors = get_color(ntest)


foreach test_info, test_list, test_id do begin
    site = test_info['site']
    time_range = time_double(test_info['time_range'])
    pixel2d = test_info['pixel2d']
    label = test_info['label']
    the_var = 'thg_asf_'+site+'_count_'+strjoin(string(pixel2d,format='(I03)'),'_')
    asf_var = themis_read_asf(time_range, site=site, get_name=1)
    if check_if_update(the_var, time_range) then begin
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
    the_counts = get_var_data(the_var, times=times, limits=lim)
    ntime = n_elements(times)-1
    min_count = min(the_counts)
    time_step = times[1]-times[0]
    
    xstep = 3600d
    xrange = minmax(times)
    xtickv = make_bins(xrange, xstep, inner=1)
    xticks = n_elements(xtickv)-1
    xminor = 6
    xtickn = time_string(xtickv,tformat='hh:mm')
    index = where((xtickv mod 86400) eq 0, count)
    index = sort_uniq([0,index])
    xtickn[index] += '!C'+time_string(xtickv[index],tformat='YYYY-MM-DD')
    
;    ; moon angle.
;    min_moon_angle = 40d
;    deg = constant('deg')
;    var_info = themis_asi_read_moon_pos(time_range, site=site, get_name=1)
;    moon_elev_var = var_info['moon_elev']
;    moon_azim_var = var_info['moon_azim']
;    if check_if_update(moon_elev_var, time_range) then var_info = themis_asi_read_moon_pos(time_range, site=site)
;    moon_elevs = get_var_data(moon_elev_var, at=times)
;    moon_azims = get_var_data(moon_azim_var, at=times)
;    moon_r3d = themis_asi_elev_azim_to_r3d(moon_elevs, moon_azims)
;
;    pixel_elevs = get_setting(asf_var, 'pixel_elev')
;    pixel_azims = get_setting(asf_var, 'pixel_azim')
;    pixel_elev = pixel_elevs[pixel2d[0],pixel2d[1]]
;    pixel_azim = pixel_azims[pixel2d[0],pixel2d[1]]
;    pixel_r3d = themis_asi_elev_azim_to_r3d(pixel_elev,pixel_azim)
;
;    moon_angles = acos($
;        pixel_r3d[0]*moon_r3d[*,0]+$
;        pixel_r3d[1]*moon_r3d[*,1]+$
;        pixel_r3d[2]*moon_r3d[*,2])*deg
;;    moon_weight = exp((2.5-moon_angles)/2.5)*2+1

    plot_file = join_path([srootdir(),'test_themis_asf_calc_background.pdf'])
    plot_file = 1
    sgopen, plot_file, size=[12,4], xchsz=xchsz, ychsz=ychsz
    tpos = sgcalcpos(1, margin=[7,4,2,1])
    plot, [0,1],[0,1], xlog=0, ylog=1, psym=-1, xrange=xrange, yrange=[1e3,1e5], position=tpos, $
        xstyle=1, ystyle=1, xtitle='', ytitle='ASI Count (#)', $
        xticklen=-0.02, yticklen=-0.02/3, xticks=xticks, xtickv=xtickv, xminor=xminor, xtickname=xtickn
    
    plot, [0,1],[0,1], xlog=0, ylog=1, psym=-1, xrange=[0,ntime-1], yrange=[1e3,1e5], position=tpos, $
        xstyle=5, ystyle=5, nodata=1, noerase=1
    oplot, the_counts

;    sample_indexs = test_themis_asf_calc_background(the_counts, test=1, moon_angles)
tic
    bg2 = test_themis_asf_calc_background(the_counts, test=1)
toc
    oplot, bg2, color=sgcolor('red')
stop
        
endforeach



end