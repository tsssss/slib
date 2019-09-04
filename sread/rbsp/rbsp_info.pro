;+
; Return basic sc info.
;-

function rbsp_info, key

    info = dictionary($
        'spin_period', 10.95d, $
        'boom_length', [100d,100,12], $
        'v_uvw_data_rate', 0.03125d)

    if n_elements(key) eq 0 then return, info
    if info.haskey(key) then return, info[key] else return, info

end

print, rbsp_info('spin_period')
end