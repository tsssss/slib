;+
; Get the prefix of a tplot variable.
;-
function get_prefix, tvar
    return, strmid(tvar,0,strpos(tvar,'_')+1)
end

print, get_prefix('rbspb_efw_eb1')
end