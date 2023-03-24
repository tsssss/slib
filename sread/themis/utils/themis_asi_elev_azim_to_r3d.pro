
function themis_asi_elev_azim_to_r3d, elevs, azims

    deg = constant('deg')
    rad = constant('rad')
    
    dims = size(elevs, dimensions=1)
    if n_elements(elevs) eq 1 then dims = [1]
    ndim = 3
    
    theta = elevs*rad
    phi = azims*rad
    
    rrs = fltarr([product(dims),ndim])
    rrs[*,0] = cos(theta)*cos(phi)
    rrs[*,1] = cos(theta)*sin(phi)
    rrs[*,2] = sin(theta)
    
    rrs = reform(rrs, [dims,ndim])
    return, rrs
    
end

