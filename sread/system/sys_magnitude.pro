;+
; Get the magnitude of a variable and save the result to a given name.
; 
; var1. A string of the given variable name.
; to. A string to save the magnitude.
; settings. A structure of settings for the magnitude variable.
;-
pro sys_magnitude, var1, to=var2, settings=settings

    get_data, var1, times, dat1, limits=info
    store_data, var2, times, snorm(dat1)
    if size(info,/type) eq 8 then begin
        tags = strlowcase(tag_names(info))
        tinfo = {display_type:'scalar'}
        keys = ['unit','short_name']
        nkey = n_elements(keys)
        for i = 0, nkey-1 do begin
            idx = where(tags eq keys[i], cnt)
            if cnt eq 0 then continue
            tinfo = create_struct(keys[i], info.(idx[0]), tinfo)
        endfor
        add_setting, var2, /smart, tinfo
    endif
    if size(settings,/type) eq 8 then add_setting, var2, /smart, settings
    
end
