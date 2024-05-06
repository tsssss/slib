function mms_valid_range, id, probe=probe

    id_str = id
    if n_elements(id_str) ge 2 then id_str = strjoin(id_str,'%')

    if id_str eq 'fgm%l2%survey' then return, ['2015-09-01']
    if id_str eq 'feeps%l2%srvy' then return, ['2015-09-01']
    
    return, ['2015-03-01']

end