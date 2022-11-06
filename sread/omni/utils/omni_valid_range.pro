function omni_valid_range, type

    info = hash($
        'cdaweb%hourly', ['1963'], $
        'cdaweb%hro%1min', ['1981'], $
        'cdaweb%hro%5min', ['1981'], $
        'cdaweb%hro2%1min', ['1995'], $
        'cdaweb%hro2%5min', ['1995'] )
    if ~info.haskey(type) then begin
        errmsg = 'Invalid input type :'+type+' ...'
        return, !null
    endif
    valid_range = time_double(info[type])
    if n_elements(valid_range) eq 1 then valid_range = [valid_range, systime(1)]
    return, valid_range
end