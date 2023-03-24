;+
; Test the effect of moon tracing and align.
;-

function themis_asi_moon_align_test_prediction, input_time_range, site=site, test=test

    retval = ''

;---Determine the date.
    secofday = constant('secofday')
    time_range = time_double(input_time_range)
    date = time_range[0]-(time_range[0] mod secofday)
    time_range = date+[0,secofday]
    secofhour = constant('secofhour')

;---Check data availability.
    site_info = themis_asi_read_site_info(site)
    midn_ut = date+site_info['midn_ut']
    search_time_range = midn_ut+[-1,1]*9*secofhour
    file_times = themis_asi_read_available_file_times(search_time_range, site=site)
    ; Get the exact time range of data availability.
    asf_var = themis_read_asf(min(file_times)+[0,secofhour], site=site)
    get_data, asf_var, times
    start_time = min(times)
    asf_var = themis_read_asf(max(file_times)+[0,secofhour], site=site)
    get_data, asf_var, times
    end_time = max(times)
    data_time_range = [start_time,end_time]


;---Load Moon's position.
    moon_vars = themis_asi_read_moon_pos(data_time_range, site=site)
    moon_elev_var = moon_vars['moon_elev']
    moon_azim_var = moon_vars['moon_azim']
    moon_elev = get_var_data(moon_elev_var, times=times)
    index = where(moon_elev ge 0, count)
    if count eq 0 then begin
        moon_time_range = []
    endif else begin
        moon_time_range = times[minmax(index)]
    endelse
    if n_elements(moon_time_range) eq 0 then return, retval


;---Load pixel elev and azim.
    pixel_info = themis_read_asi_info(time_range, site=site, id='asf')
    pixel_elevs = pixel_info['asf_elev']
    pixel_azims = pixel_info['asf_azim']


;---Get the test times for moon prediction.
    this_time_step = 1200d   ; 10 min time step.
    test_times = make_bins(moon_time_range, this_time_step, inner=1)
    ntest_time = n_elements(test_times)
    ncol = 10
    if ntest_time lt ncol then return, retval
    ntest_time = floor(ntest_time/ncol)*ncol
    test_times = test_times[0:ntest_time-1]
    

;---Figure settings.
    pan_xsize = 10d
    pan_ysize = 1.6
    asi_ysize = pan_xsize/ncol
    ncol = pan_xsize/asi_ysize
    nrow = ntest_time/ncol
    nxpan = 1
    nypan = 2
    ypads = [4]
    ypans = [pan_ysize,asi_ysize*nrow]

    plot_dir = join_path([srootdir(),'moon_align_test_prediction'])
    plot_file = join_path([plot_dir,'themis_asi_moon_align_test_prediction_'+time_string(date,tformat='YYYY_MMDD')+'_'+site+'_v01.pdf'])
    margins = [1,1,1,2]
    label_size = 0.8
    poss = panel_pos(plot_file, nxpan=nxpan,nypan=nypan, fig_size=fig_size, $
        margins=margins, pansize=[pan_xsize,pan_ysize], ypads=ypads, ypans=ypans)
    
    sgopen, plot_file, size=fig_size, xchsz=xchsz, ychsz=ychsz, test=test  
    pan_poss = sgcalcpos(2, region=poss[*,0], margins=[8,0,8,0])
    asi_poss = sgcalcpos(nrow, ncol, position=poss[*,1], xpad=0, ypad=0)
    
    
;---Plot predicted moon elev and azim.
    options, moon_elev_var, 'constant', [0,30,60]
    options, moon_azim_var, 'constant', [0,180,360]
    
    
    var = moon_elev_var
    yrange = [-10,90]
    ystep = 30
    ytickv = make_bins(yrange+[0,-1], ystep, inner=1)
    yticks = n_elements(ytickv)-1
    yminor = 3
    options, var, 'yrange', yrange
    options, var, 'ytickv', ytickv
    options, var, 'yticks', yticks
    options, var, 'yminor', yminor

    var = moon_azim_var
    yrange = [0,360]
    ystep = 100
    ytickv = make_bins(yrange+[1,0], ystep, inner=1)
    yticks = n_elements(ytickv)-1
    yminor = 2
    options, var, 'yrange', yrange
    options, var, 'ytickv', ytickv
    options, var, 'yticks', yticks
    options, var, 'yminor', yminor
    
    vars = [moon_elev_var,moon_azim_var]
    nvar = n_elements(vars)
    options, vars, 'yticklen', -0.005
    tplot, vars, position=pan_poss, trange=data_time_range
    fig_labels = letters(nvar)+')'
    foreach pan_id, [0,1] do begin
        tpos = pan_poss[*,pan_id]
        msg = fig_labels[pan_id]
        tx = tpos[0]-xchsz*7
        ty = tpos[3]-ychsz*0.8
        xyouts, tx,ty,normal=1, msg
    endforeach
    
    tpos = pan_poss[*,0]
    tpos[1] = min(pan_poss[1,*])
    xrange = data_time_range
    yrange = [0,1]
    plot, xrange, yrange, $
        xstyle=5, ystyle=5, nodata=1, noerase=1, position=tpos
    foreach time, test_times, time_id do begin
        plots, time+[0,0], yrange, linestyle=1
        tmp = convert_coord(time, yrange[1], data=1, to_normal=1)
        tx = tmp[0]
        ty = tmp[1]+ychsz*0.2
        msg = string(time_id+1,format='(I0)')
        xyouts, tx,ty,normal=1, alignment=0.5, msg, charsize=label_size
    endforeach


;---Plot asi snapshots.
    ct = 49
    zrange = [4e3,4e4]
    color_top = 254
    black = sgcolor('black')
    image_size = size(pixel_elevs, dimensions=1)
    xrange = [0,image_size[0]-1]
    yrange = [0,image_size[1]-1]

    time_step = 3d
    foreach time, test_times, time_id do begin
        the_tr = time+[0,time_step]
        asf_var = themis_read_asf(the_tr, site=site)
        if n_elements(asf_var) eq 0 then continue
        
        index2d = array_indices([ncol,nrow], time_id, dimension=1)
        tpos = asi_poss[*,index2d[0],index2d[1]]
        
        
        asf_image = get_var_data(asf_var, at=time)
        moon_elev = get_var_data(moon_elev_var, at=time)
        moon_azim = get_var_data(moon_azim_var, at=time)
        moon_index2d = themis_asi_elev_azim_to_xy(moon_elev,moon_azim, pixel_elevs, pixel_azims)
        

        sgtv, bytscl(asf_image, min=zrange[0], max=zrange[1], top=color_top), ct=ct, position=tpos
        msg = 'c-'+string(time_id+1,format='(I0)')+')'
        tx = tpos[0]+xchsz*0.5
        ty = tpos[3]-ychsz*1
        xyouts, tx,ty,normal=1, msg, color=black

        if time_id eq 0 then begin
            msg = strupcase(site)
            tx = tpos[0]+xchsz*0.5
            ty = tpos[1]+ychsz*0.2
            xyouts, tx,ty,normal=1, msg, color=black, charsize=label_size
        endif
        

        plot, xrange, yrange, $
            xstyle=5, xrange=xrange, $
            ystyle=5, yrange=yrange, $
            nodata=1, noerase=1, position=tpos
        plots, moon_index2d[0], moon_index2d[1], psym=1, color=sgcolor('red')

    endforeach
    sgclose
    
    return, plot_file

end


test = 0
; For a given site over several days.
time_range = ['2015-01-01','2015-02-01']
site = 'whit'
site_info = themis_asi_read_site_info(site)
midn_ut = date+site_info['midn_ut']
search_time_range = midn_ut+[-1,1]*9*60

dates = make_bins(time_double(time_range),constant('secofday'))
foreach date, dates do begin
    date = time_double(date)
    file_times = themis_asi_read_available_file_times(search_time_range, site=site)
    nfile_time = n_elements(file_times)
    if nfile_time eq 0 then continue
    tmp = themis_asi_moon_align_test_prediction(date, site=site, test=test)
endforeach
stop


; For specific days for all sites.
dates = ['2016-01-28','2013-03-17','2008-01-19','2015-01-01','2015-12-07','2015-10-05','2008-02-13']
foreach date, dates do begin
    date = time_double(date)
    all_sites = themis_read_asi_sites()
    foreach site, all_sites do begin
        site_info = themis_asi_read_site_info(site)
        midn_ut = date+site_info['midn_ut']
        search_time_range = midn_ut+[-1,1]*9*60
        file_times = themis_asi_read_available_file_times(search_time_range, site=site)
        nfile_time = n_elements(file_times)
        if nfile_time eq 0 then continue
        tmp = themis_asi_moon_align_test_prediction(date, site=site, test=test)
    endforeach
endforeach


end