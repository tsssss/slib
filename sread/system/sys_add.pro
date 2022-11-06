;+
; Add two variables and save the result to a given name.
;-
pro sys_add, var1, var2, to=var3, settings=settings

    get_data, var1, times, dat1, limits=info
    if size(var2,/type) eq 7 then get_data, var2, times, dat2 else dat2=var2
    
    dat1 += dat2
    store_data, var3, times, dat1
    if size(info,/type) eq 0 then add_setting, var3, /smart, info
    if size(settings,/type) eq 8 then add_setting, var3, /smart, settings

end