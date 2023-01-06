;+
; Return all available asi sites.
;-
function themis_read_asi_sites

    return, ['atha','chbg','ekat','fsmi','fsim','fykn',$
        'gako','gbay','gill','inuv','kapu','kian',$
        'kuuj','mcgr','pgeo','pina','rank','snkq',$
        'tpas','whit','yknf','nrsq','snap','talo']

end

sites = themis_read_asi_sites()
end