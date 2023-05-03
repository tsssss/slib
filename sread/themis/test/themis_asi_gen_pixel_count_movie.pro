;+
; Generate a movie of pixel count per pixel.
; 
; asf_images.
; movie_file=.
;-

function themis_asi_gen_pixel_count_movie, input_time_range, site=site, asf_var=asf_var, movie_file=movie_file, no_more=no_more


;---Handle input.
    if n_elements(asf_var) eq 0 then begin
        time_range = time_double(input_time_range)
        asf_var = themis_read_asf(time_range, site=site, get_name=1)
    endif else begin
        if n_elements(site) eq 0 then site = get_setting(asf_var, 'site')
        if n_elements(input_time_range) ne 2 then input_time_range = minmax(get_var_time(asf_var))
    endelse
    time_range = time_double(input_time_range)
    if check_if_update(asf_var, time_range) then asf_var = themis_read_asf(time_range, site=site)



;---Settings.
    if n_elements(movie_file) eq 0 then begin
        movie_base = 'themis_asi_pixel_count_movie_'+strjoin(time_string(time_range,tformat='YYYY_MMDD_hhmm'),'_')+'_'+site+'_v01.mp4'
        movie_file = join_path([homedir(),'themis_asi_pixel_count_movie',movie_base])
    endif
    movie_dir = file_dirname(movie_file)
    
    get_data, asf_var, times, asf_images
    the_size = size(asf_images, dimensions=1)
    nframe = the_size[0]
    image_size = the_size[1:2]
    
    
    nxpan = 2
    nypan = 1
    xpans = [1,3]
    xpad = 8
    margins = [8,4,2,1]
    poss = panel_pos(nxpan=nxpan, nypan=nypan, pansize=[2,2], xpans=xpans, xpad=xpad, fig_size=fig_size, margins=margins)

    npixel = product(image_size)
    step = 4d

    xrange = [0,image_size[0]-1]
    yrange = [0,image_size[1]-1]


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
            sgopen, plot_file, size=fig_size, xchsz=xchsz, ychsz=ychsz

            tpos = poss[*,0]
            sgtv, bytscl(alog10(the_image), min=3, max=5, top=254), ct=49, position=tpos

            tx = tpos[0]+xchsz*0.5
            ty = tpos[1]+ychsz*0.5
            msg = time_string(the_time)
            xyouts, tx,ty, msg, normal=1
            
            plot, xrange, yrange, xrange=xrange, yrange=yrange, $
                xstyle=1, ystyle=1, xticklen=-0.02, yticklen=-0.02, $
                nodata=1, noerase=1, position=tpos
            plots, ii, jj, psym=1, color=sgcolor('red')
            
            
            

            tpos = poss[*,1]
            plot, times-times[0], asf_images[*,ii,jj], $
                yrange=[1e3,1e5], ylog=1, noerase=1, xstyle=1, $
                position=tpos, ytitle='Count (#)', xticklen=-0.02, yticklen=-0.02/3, xtitle='Seconds from '+time_string(times[0])
            plots, the_time-times[0]+[0,0], [1e3,1e5], linestyle=1
            
            msg = '['+string(ii,format='(I03)')+','+string(jj,format='(I03)')+']'
            tx = tpos[0]+xchsz*0.5
            ty = tpos[3]-ychsz*1
            xyouts, tx,ty,normal=1, msg
            
            sgclose
        endfor
    endfor
    
    fig2movie, movie_file, fig_files=files
    foreach file, files do file_delete, file
    if keyword_set(no_more) then return, movie_file

;---Check if has moon.
    has_moon = themis_asi_check_if_has_moon(time_range, site=site)
    if has_moon then begin
        movie_base = 'themis_asi_pixel_count_movie_'+strjoin(time_string(time_range,tformat='YYYY_MMDD_hhmm'),'_')+'_'+site+'_moon_align_v01.mp4'
        ma_file = join_path([movie_dir,movie_base])
        ma_var = themis_asi_moon_align(time_range, site=site, asf_var=asf_var, get_name=1)
        ma_file = themis_asi_gen_pixel_count_movie(time_range, site=site, asf_var=ma_var, movie_file=ma_file, no_more=1)

        return, [movie_file, ma_file]
    endif else begin
        return, movie_file
    endelse

    
end


;---An event with moon.
;    time_range = time_double(['2008-01-19/07:00','2008-01-19/08:00'])   ; moon and background fluctuations.
    time_range = time_double(['2008-01-19/01:47:15','2008-01-19/16:27:03'])   ; moon and background fluctuations.
    
    site = 'inuv'
    test_time = '2008-01-19/07:04'
    ; moon center: 140,60
    ; moon reflection: 135,215
    ; moon edge: 130,70
    ; moon glow: 130,95


;;---An event without moon.
;    time_range = time_double(['2016-10-13/12:00','2016-10-13/13:00'])   ; stable arc.
;    site = 'gako'
;    test_time = '2016-10-13/12:10'
;    ; image edge: 20,120
;    ; stable arc: 100,50
;    
;
;;---An arc and moon.
;    time_range = time_double(['2016-10-13/08:00','2016-10-13/09:00'])   ; stable arc.
;    site = 'gako'
;    test_time = !null
;    ; image edge: 20,120
;    ; stable arc: 100,50


    asf_var = themis_read_asf(time_range, site=site, get_name=1)
    asf_movie = themis_asi_gen_pixel_count_movie(time_range, site=site, asf_var=asf_var)


end