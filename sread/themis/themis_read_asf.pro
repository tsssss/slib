;+
; Read Themis MLT image per site for asf, after preprocessing.
;
; time0. A number for time in UT sec.
; site. A string for site.
;-
;

pro themis_read_asf, time, site=site, errmsg=errmsg, min_elev=min_elev, $
    raw_image=raw_image

    compile_opt idl2
    on_error, 0
    errmsg = ''
    
    if size(time[0],/type) eq 7 then time = time_double(time)
    if n_elements(min_elev) eq 0 then min_elev = 10
    
    
    ; Read the raw image. 
    asf_var = 'thg_'+site+'_asf' 
    themis_read_asi, time, id='asf', site=site
    if keyword_set(raw_image) then return


    ; Preliminary image processing.
    ; Read calibration data.
    lprmsg, 'Preprocess raw image ...'
    asc_vars = 'thg_asf_'+site+'_'+['time','elev']
    themis_read_asi, time, id='asc', site=site, in_vars=asc_vars
    
    asc_times = get_data(asc_vars[0])
    asc_elevs = get_data(asc_vars[1])
    get_data, asf_var, times, raw_images
    ntime = n_elements(times)
    if ntime eq 1 then raw_images = reform(raw_images, [1,size(raw_images,/dimensions)])
    for i=0, ntime-1 do begin
        timg = reform(raw_images[i,*,*])
        tut = times[i]
        lprmsg, '    '+time_string(tut)+' ...'
        index = where(asc_times lt tut, count)
        if count eq 0 then begin
            errmsg = handle_error('Wrong input time: '+time_string(tut)+' ...')
            return
        endif
        telev = reform(asc_elevs[index[count-1],*,*])
        edge = where(telev lt min_elev or ~finite(telev), complement=center)
        timg[edge] = mean(timg[0:10,0:10], /nan)
        timg = (timg-timg[0])>0
        timg *= 64d/(median(timg[center])>1)
        timg[edge] = 0
        raw_images[i,*,*] = timg
    endfor
    store_data, asf_var, times, raw_images    
    
end

time = time_double(['2014-08-28/09:55','2014-08-28/10:05'])
site = 'whit'
themis_read_asf, time, site=site
end