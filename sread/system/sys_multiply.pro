;+
; Multiply 1 variable by var2 and save the result to a given name.
;-
pro sys_multiply, var1, var2, to=var3, settings=settings

    get_data, var1, times, dat1, limits=info
    
    dat1 *= var2[0]
    store_data, var3, times, dat1
    if size(info,/type) eq 0 then add_setting, var3, /smart, info
    if size(settings,/type) eq 8 then add_setting, var3, /smart, settings

end
