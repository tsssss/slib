
function themis_asi_r3d_to_elev_azim, rrs

    deg = constant('deg')
    rad = constant('rad')

    dims = size(rrs, dimensions=1)
    ndim = n_elements(dims)
    if ndim eq 1 then begin
        dims = [1]
        ndim = 3
    endif else begin
        dims = dims[0:ndim-2]
        ndim = 3
    endelse

    the_rrs = reform(rrs, [product(dims),ndim])
    
    tts = fltarr([product(dims),2])
    tts[*,0] = asin(the_rrs[*,2])*deg
    tts[*,1] = atan(the_rrs[*,1],the_rrs[*,0])*deg
    tts = reform(tts, [dims,2])
    
    return, tts

end
