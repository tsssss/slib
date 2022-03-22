;+
; Return all available asi sites.
;-
function themis_read_asi_sites

    return, themis_asi_sites()

end

sites = themis_read_asi_sites()
end