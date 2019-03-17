;+
; Read Themis MLT image per site for asf.
;
; time0. A number for time in UT sec.
; site. A string for site.
;-
;

pro themis_read_asf, time, site=site, errmsg=errmsg, extra=_extra

    compile_opt idl2
    on_error, 0
    errmsg = ''
    
    if size(time[0],/type) eq 7 then time = time_double(time)    
    pre0 = 'thg_'+site+'_'

    ; Read the raw image. 
    asf_var = pre0+'asf' 
    themis_read_asi, time, id='asf', site=site, errmsg=errmsg
    if errmsg ne '' then return
    
    
    ; Read the raw image, convert it to float.
    get_data, asf_var, times, raw_images
    ntime = n_elements(times)
    if ntime eq 1 then raw_images = reform(raw_images, [1,size(raw_images,/dimensions)])
    raw_images = float(raw_images)  ; It's crucial to cast uint to float.
    
    ; Save the raw image.
    store_data, asf_var, times, raw_images
    add_setting, asf_var, /smart, {$
        display_type: 'image', $
        unit: 'Count', $
        short_name: 'ASF/'+strupcase(site[0])}
        
end

time = time_double(['2014-08-28/09:55','2014-08-28/10:05'])
site = 'whit'
themis_read_asf, time, site=site
end