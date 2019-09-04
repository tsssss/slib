;+
; Return basic sc info.
;-

function polar_info, key

    info = dictionary($
        'spin_period', 6d, $
        'boom_length', [100d,130,14], $
        'v_uvw_data_rate', 0.4d)
    
    if n_elements(key) eq 0 then return, info
    if info.haskey(key) then return, info[key] else return, info

end

print, polar_info('spin_period')
end