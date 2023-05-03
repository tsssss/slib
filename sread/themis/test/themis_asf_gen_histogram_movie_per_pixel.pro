;+
; Check if the images contain clouds.
;-

function themis_asf_gen_histogram_movie_per_pixel, input_time_range, site=site, asf_var=asf_var, movie_file=movie_file, test=test


;---Handle input.
    if n_elements(asf_var) eq 0 then begin
        time_range = time_double(input_time_range)
        asf_var = themis_read_asf(time_range, site=site, get_name=1)
    endif else begin
        if n_elements(site) eq 0 then site = get_setting(asf_var, 'site')
        if n_elements(input_time_range) ne 2 then input_time_range = minmax(get_var_time(asf_var))
    endelse
    time_range = time_double(input_time_range)
    if check_if_update(asf_var, time_range) then begin
        asf_var = themis_read_asf(time_range, site=site)
        options, asf_var, 'requested_time_range', time_range
    endif



;---Settings.
    if n_elements(movie_file) eq 0 then begin
        movie_base = 'themis_asf_gen_histogram_movie_per_pixel_'+strjoin(time_string(time_range,tformat='YYYY_MMDD_hhmm'),'_')+'_'+site+'_v01.mp4'
        movie_file = join_path([homedir(),'themis_asf',movie_base])
    endif
    movie_dir = file_dirname(movie_file)
    
    get_data, asf_var, times, asf_images, limits=lim
    center_index = lim.center_index
    the_size = size(asf_images, dimensions=1)
    nframe = the_size[0]
    image_size = the_size[1:2]
    time_step = 3d


;---Prepare the plots.
    nxpan = 4
    nypan = 1
    xpans = [1,3,1,1]
    xpad = [8,2,2]
    margins = [6,4,2,2]
    poss = panel_pos(nxpan=nxpan, nypan=nypan, pansize=[2,2], xpans=xpans, xpad=xpad, fig_size=fig_size, margins=margins)

    fig_labels = letters(nxpan)+') '+['ASI','ASI Count per pixel','Histogram per frame','Histogram per pixel']


    npixel = product(image_size)
    step = 4d

    xrange = [0,image_size[0]-1]
    yrange = [0,image_size[1]-1]

    value_yrange = [1e3,1e5]
    value_range = [0,65536]
    value_step = 1e3
    value_bins = make_bins(value_range, value_step, inner=1)
    nvalue_bin = n_elements(value_bins)
    
    time_tickv = make_bins(time_range, 3600, inner=1)
    time_ticks = n_elements(time_tickv)-1
    time_tickn = time_string(time_tickv,tformat='hh:mm')
    index = where((time_tickv mod 86400) eq 0, count)
    if count eq 0 then index = []
    index = sort_uniq([0,index])
    time_tickn[index] += '!C'+time_string(time_tickv[index],tformat='YYYY-MM-DD')
    time_minor = 6
    
    

;---Start to generate plots.
    files = []
    for ii=0,image_size[0]-1 do begin
        for jj=0,image_size[1]-1 do begin
            if (ii mod step) ne 0 then continue
            if (jj mod step) ne 0 then continue
            
            pixel_id = ii*image_size[1]/step/step+jj/step         
            the_index = floor(nframe*pixel_id/(npixel/step/step))

            
            
            the_image = reform(asf_images[the_index,*,*])
            the_time = times[the_index]
            
            
            plot_file = join_path([movie_dir,'tmp','themis_asi_pixel_count_movie_pixel_'+string(ii,format='(I0)')+'_'+string(jj,format='(I0)')+'.png'])
            files = [files,plot_file]
            sgopen, plot_file, size=fig_size, xchsz=xchsz, ychsz=ychsz, test=test
            
           
            foreach fig_label, fig_labels, id do begin
                tpos = poss[*,id]
                tx = tpos[0]
                ty = tpos[3]+ychsz*0.5
                xyouts, tx,ty,normal=1, fig_label
            endforeach


        ;---The image.
            tpos = poss[*,0]
            sgtv, bytscl(the_image, min=-20000, max=20000, top=254), ct=70, position=tpos

            tx = tpos[0]+xchsz*0.5
            ty = tpos[1]+ychsz*0.5
            msg = strupcase(site)+' '+time_string(the_time)
            xyouts, tx,ty, msg, normal=1
            
            plot, xrange, yrange, xrange=xrange, yrange=yrange, $
                xstyle=1, ystyle=1, xticklen=-0.02, yticklen=-0.02, $
                nodata=1, noerase=1, position=tpos
            plots, ii, jj, psym=1, color=sgcolor('red')
            
            
        ;---Plot the histogram for the image.
            tpos = poss[*,2]
            the_data = (the_image[*])[center_index]
            hist = fltarr(nvalue_bin)
            foreach value, value_bins, value_id do begin
                tmp = where(the_data ge value, count)
                hist[value_id] = count
            endforeach
            plot, hist, value_bins, $
                xstyle=1, xlog=1, xticklen=-0.02, xrange=[1e0,1e5], xtitle='Pixel count (#)', $
                yrange=value_yrange, ystyle=1, ylog=1, yticklen=-0.02, ytitle=' ', ytickformat='(A1)', $
                nodata=1, noerase=1, position=tpos
            plots, hist>1, value_bins, psym=-1, symsize=0.2
            
            
        ;---Plot the count per pixel in time.
            tpos = poss[*,1]
            plot, times, asf_images[*,ii,jj], $
                yrange=value_yrange, ylog=1, noerase=1, xstyle=1, $
                position=tpos, ytitle='ASI Count (#)', ytickformat='', xticklen=-0.02, yticklen=-0.02/3, $
                xticks=time_ticks, xtickv=time_tickv, xminor=time_minor, xtickname=time_tickn
            plots, the_time+[0,0], [1e3,1e5], linestyle=1
            
            msg = 'Pixel ['+string(ii,format='(I03)')+','+string(jj,format='(I03)')+']'
            tx = tpos[0]+xchsz*0.5
            ty = tpos[3]-ychsz*1
            xyouts, tx,ty,normal=1, msg
            
            
        ;---Plot the histogram.
            tpos = poss[*,3]
            ;the_data = (the_image[*])[center_index]
            the_data = asf_images[*,ii,jj]
            hist = fltarr(nvalue_bin)
            foreach value, value_bins, value_id do begin
                tmp = where(the_data ge value, count)
                hist[value_id] = count
            endforeach
            hist *= time_step
            plot, hist, value_bins, $
                xstyle=1, xlog=1, xticklen=-0.02, xrange=[1e-1,1e5], xtitle='Duration (sec)', $
                yrange=value_yrange, ystyle=1, ylog=1, ytickformat='(A1)', yticklen=-0.02, $
                nodata=1, noerase=1, position=tpos
            plots, hist>1, value_bins, psym=-1, symsize=0.2
            
            sgclose
        endfor
    endfor
    
    fig2movie, movie_file, fig_files=files
    foreach file, files do file_delete, file
    return, movie_file



end


; Moon and streamers.
site = 'inuv'
date = '2008-01-19'

; Clouds.
site = 'atha'
date = '2015-01-01'

; Moon and strong arc.
site = 'gako'
date = '2016-10-13'

; Clouds.
site = 'fsim'
date = '2015-01-01'

time_range = themis_asf_read_time_range_per_night(date, site=site, find_closest=1)
movie_file = themis_asf_gen_histogram_movie_per_pixel(time_range, site=site, test=0)
end
