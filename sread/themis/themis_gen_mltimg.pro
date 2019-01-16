;+
; Read Themis MLT image per site for asf.
; 
; time0. A number for time in UT sec.
; site. A string for site.
;-
;

pro themis_gen_mltimg, time0, site=site, errmsg=errmsg, $
    min_elev=min_elev

    compile_opt idl2
    on_error, 0
    errmsg = ''
    
    
    if n_elements(time0) eq 0 then begin
        errmsg = handle_error('No input time ...')
        return
    endif
    if size(time0,/type) eq 7 then time0 = time_double(time0)
    
    if n_elements(site) eq 0 then begin
        errmsg = handle_error('No input site ...')
        return
    endif
    pre0 = 'thg_'+site+'_'
    
    tstep = 3600d
    time = time0-(time0 mod tstep)+[0,tstep]
    
    ; Read ASF, after preprocessed.
    themis_read_asf, time, site=site, min_elev=min_elev
    
    
    ; Convert to MLT image.
    
    
    ; Calculate the midnight mlon.
    

end

date = '2014-08-28/10:00'
site = 'whit'
themis_gen_mltimg, date, site=site
end