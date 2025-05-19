function mms_valid_range, id, probe=probe

    if n_elements(id) eq 0 then id = 'misc'
    id_str = id
    if n_elements(id_str) ge 2 then id_str = strjoin(id_str,'%')
    default_valid_range = ['2015-02-01']
    
    if id_str eq 'misc' then return, default_valid_range
    if id_str eq 'fgm%l2%survey' then return, default_valid_range
    if id_str eq 'feeps%l2%srvy' then return, default_valid_range
    
    return, default_valid_range

end