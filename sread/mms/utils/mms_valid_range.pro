function mms_valid_range, id, probe=probe

    if id eq 'fgm%l2%survey' then return, ['2015-09-01']
    
    return, ['2015-03-01']

end