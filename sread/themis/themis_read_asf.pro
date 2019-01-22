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
    pre0 = 'thg_'+site+'_'

    ; Read the raw image. 
    asf_var = pre0+'asf' 
    themis_read_asi, time, id='asf', site=site
    if keyword_set(raw_image) then return


    ; Preliminary image processing.
    ; Read elevation for preprocessing image.
    lprmsg, 'Preprocess raw image ...'
    elev_var = pre0+'asf_elev'
    themis_read_asc, time, site=site, vars=['elev'], id='asf%v01'
    elev = get_var_data(elev_var)
    if n_elements(min_elev) eq 0 then begin
        center = where(finite(elev), complement=edge)
    endif else begin
        center = where(elev ge min_elev and finite(elev), complement=edge)
    endelse
    std_elev = 10   ; degree.
    center0 = where(elev ge std_elev and finite(elev), complement=edge0)
    
    
    get_data, asf_var, times, raw_images
    ntime = n_elements(times)
    if ntime eq 1 then raw_images = reform(raw_images, [1,size(raw_images,/dimensions)])
    raw_images = float(raw_images)  ; It's crucial to cast uint to float.
    for i=0, ntime-1 do begin
        timg = reform(raw_images[i,*,*])
        tut = times[i]
        lprmsg, '    '+time_string(tut)+' ...'
        ;bg_count = mean(timg[0:10,0:10], /nan)
        bg_count = median(timg[edge0]) ; Sheng: I think use median is better than mean.
        timg = (timg-bg_count)>0
        timg *= 64d/(median(timg[center0])>1)   ; Sheng: scale to median=64.
        timg[edge] = 0
        raw_images[i,*,*] = timg
    endfor
    store_data, asf_var, times, raw_images
    add_setting, asf_var, /smart, {$
        display_type: 'image', $
        unit: 'Count', $
        short_name: 'ASF/'+strupcase(site[0])}
        
end

time = time_double(['2014-08-28/09:55','2014-08-28/10:05'])
site = 'whit'
themis_read_asf, time, site=site, min_elev=10
end