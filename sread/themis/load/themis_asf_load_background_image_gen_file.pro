;+
; Load calibrated asf images.
;-

function themis_asf_load_background_image_gen_file, input_time_range, site=site, errmsg=errmsg, $
    filename=files, file_pattern=file_pattern, get_name=get_name


    retval = !null
    errmsg = ''


;---Handle input.
    the_time = time_double(input_time_range[0])

;---Get the file_times for the night.
    file_times = themis_asf_read_file_times_per_night(the_time, site=site)
    nfile_time = n_elements(file_times)
    if nfile_time eq 0 then return, retval

    if n_elements(files) ne nfile_time then begin
        if n_elements(file_pattern) eq 0 then begin
            errmsg = 'No input file_pattern ...'
            return, retval
        endif else files = apply_time_to_pattern(file_pattern, file_times)
    endif
    if keyword_set(get_name) then return, files


;---Get the exact start and end times for the night.
    time_range = themis_asf_read_time_range_per_night(the_time, site=site)


;---Get the background images.
    asf_var = themis_read_asf(time_range, site=site, get_name=1)
    if check_if_update(asf_var, time_range) then asf_var = themis_read_asf(time_range, site=site)
    bg_var = themis_asf_calc_background_image(time_range, site=site, get_name=1)
    if check_if_update(bg_var, time_range) then begin
        ; Load the original asf images.
        get_data, asf_var, times, orig_images, limits=lim
        image_size = lim.image_size
        ncenter_index = n_elements(center_indices)

        ; A minimum background per pixel over the entire night.
        min_bg_image = fltarr(image_size)
        for ii=0,image_size[0]-1 do begin
            for jj=0,image_size[1]-1 do begin
                min_bg_image[ii,jj] = min(orig_images[*,ii,jj])
            endfor
        endfor

        bg_var = themis_asf_calc_background_image(time_range, site=site, $
            asf_var=asf_var, min_bg_image=min_bg_image)
    endif
    
    
;---Prepare the data to be saved.
    asf_bg = get_var_data(bg_var, times=times, limits=lim)
    ntime = n_elements(times)
    center_index = get_setting(asf_var, 'center_index')
    image_size = get_setting(asf_var, 'image_size')
    npixel = product(image_size)
    asf_bg = reform(asf_bg, [ntime,npixel])
    asf_bg = asf_bg[*,center_index]
    

;---Save the data to file.
    secofhour = constant('secofhour')
    foreach file_time, file_times, file_id do begin
        the_time_range = file_time+[0,secofhour]
        time_index = lazy_where(times, '[)', the_time_range, count=count)
        if count eq 0 then continue

        file = files[file_id]
;        if file_test(file) ne 0 then file_delete, file
        if file_test(file) ne 0 then continue
        gatt = dictionary($
            'title', 'ASI image background, calculated based on L1 data', $
            'text', 'Calculated by Sheng Tian at AOS UCLA, email:ts0110@atmos.ucla.edu', $
            'time_range', the_time_range, $
            'site', site )
        cdf_save_setting, gatt, filename=file


        ; Save the time.
        time_var = 'unix_time'
        val = times[time_index]
        vatt = dictionary($
            'FIELDNAM', 'unix time', $
            'UNITS', 'sec', $
            'VAR_TYPE', 'support_data' )
        cdf_save_var, time_var, value=val, filename=file, cdf_type='CDF_DOUBLE'
        cdf_save_setting, vatt, varname=time_var, filename=file
        
        ; Save the center_index.
        center_var = 'center_index'
        val = center_index
        vatt = dictionary($
            'FIELDNAM', 'index of the field of view', $
            'VAR_TYPE', 'support_data' )
        cdf_save_var, center_var, value=val, filename=file
        cdf_save_setting, vatt, varname=center_var, filename=file
        

        var = 'thg_'+site+'_asf_bg'
        vatt = dictionary($
            'DEPEND_0', time_var, $
            'DEPEND_1', center_var, $
            'FIELDNAM', 'asf background', $
            'UNITS', '#', $
            'image_size', image_size, $
            'VAR_TYPE', 'data' )
        cdf_save_var, var, value=asf_bg[time_index,*,*], filename=file
        cdf_save_setting, vatt, varname=var, filename=file
    endforeach

    
    return, files

end

test_list = list()
test_list.add, dictionary($
    'time_range', time_double(['2008-01-19/07:00','2008-01-19/08:00']), $   ; moon and background fluctuations.
    'site', 'inuv')
test_list.add, dictionary($
    'time_range', time_double(['2016-10-13/12:00','2016-10-13/13:00']), $   ; stable arc.
    'site', 'gako')
;test_list.add, dictionary($
;    'time_range', time_double(['2008-02-13/02:00','2008-02-13/03:00']), $   ; Chu+2015.
;    'site', 'gill')   ; gill, kuuj, snkq

version = 'v11'

foreach test_info, test_list do begin
    time_range = test_info['time_range']
    site = test_info['site']
    
    
    file_pattern = join_path([homedir(),'thg_asf_bg_'+site+'_%Y_%m%d_%H_'+version+'.cdf'])
    tic
    files = themis_asf_load_background_image_gen_file(time_range, site=site, file_pattern=file_pattern)
    toc
    stop
    asf_var = 'thg_'+site+'_asf'
    bg_var = asf_var+'_bg'
    asf_images = get_var_data(asf_var)
    times = cdf_read_var('unix_time', filename=cdf_file)
    ntime = n_elements(times)
    gatt = cdf_read_setting(filename=cdf_file)
    image_size = gatt['image_size']
    npixel = product(image_size)
    asf_bgs = reform(asf_images, [ntime,npixel])
    center_index = cdf_read_var('center_index', filename=cdf_file)
    asf_bgs[*,center_index] = cdf_read_var(bg_var, filename=cdf_file)
    asf_bgs = reform(asf_bgs, [ntime,image_size])
    
;    test_time = time_double('2008-01-19/06:34:21')
;    test_index = where(times eq test_time, count)
;    if count eq 0 then stop
;    sgopen, 0, size=[4,4]
;    tpos = [0,0,1,1]
;    sgtv, bytscl(reform(asf_bgs[test_index,*,*]),min=-20000,max=20000, top=254), position=tpos, ct=70
;    plot, [0,255],[0,255], xstyle=5, ystyle=5, position=tpos, nodata=1, noerase=1
;stop

    movie_file = join_path([homedir(),'test_themis_asf_background_removal_'+time_string(time_range[0],tformat='YYYY_MMDD')+'_'+site+'_'+version+'.mp4'])
    movie_dir = file_dirname(movie_file)
    if file_test(movie_dir) eq 0 then file_mkdir, movie_dir
    plot_dir = join_path([movie_dir,'tmp'])
    ntime = n_elements(times)
    plot_files = strarr(ntime)

    poss = sgcalcpos(1,3, position=[0,0,1,1], xpad=0)
    foreach time, times, time_id do begin
        if time_id mod 9 ne 0 then continue
        plot_file = join_path([plot_dir,'test_themis_asf_background_removal_'+time_string(time,tformat='YYYY_MMDD_hhmm_ss')+'_'+site+'_'+version+'.png'])
        sgopen, plot_file, size=[12,4], xchsz=xchsz, ychsz=ychsz

        asf_img = bytscl(reform(asf_images[time_id,*,*]),min=-20000,max=20000, top=254)
        asf_bg = bytscl(reform(asf_bgs[time_id,*,*]),min=-20000,max=20000, top=254)
        asf_cal = bytscl(reform(asf_images[time_id,*,*]-asf_bgs[time_id,*,*]),min=-20000,max=20000, top=254)

        tpos = poss[*,0]
        sgtv, asf_img, ct=70, position=tpos
        tx = tpos[0]+xchsz*0.5
        ty = tpos[3]-ychsz*1
        msg = 'Original'
        xyouts, tx,ty,normal=1, msg

        tpos = poss[*,1]
        sgtv, asf_bg, ct=70, position=tpos
        tx = tpos[0]+xchsz*0.5
        ty = tpos[3]-ychsz*1
        msg = 'Background'
        xyouts, tx,ty,normal=1, msg

        tpos = poss[*,2]
        sgtv, asf_cal, ct=70, position=tpos
        tx = tpos[0]+xchsz*0.5
        ty = tpos[3]-ychsz*1
        msg = 'Diff = Original-Background'
        xyouts, tx,ty,normal=1, msg

        msg = strupcase(site)+' '+time_string(time)+' UT'
        tx = xchsz*0.5
        ty = ychsz*0.3
        xyouts, tx,ty,normal=1, msg

        sgclose
        plot_files[time_id] = plot_file
    endforeach

    fig2movie, movie_file, fig_files=plot_files
    foreach file, plot_files do if file ne '' then file_delete, file
    file_delete, plot_dir
endforeach

end