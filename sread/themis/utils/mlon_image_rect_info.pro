
function mlon_image_rect_info

;    sites = themis_read_asi_sites()
;    mlon_range = list()
;    mlat_range = list()
;    foreach site, sites do begin
;        asf_info = themis_asi_read_pixel_info([0,0], site=site, errmsg=errmsg)
;        mlon_range.add, minmax(asf_info.pixel_mlon)
;        mlat_range.add, minmax(asf_info.pixel_mlat)
;    endforeach
;    mlon_range = minmax(mlon_range.toarray())
;    mlat_range = minmax(mlat_range.toarray())

    mlon_range = [-135d,45]
    mlat_range = [50,85]

    if n_elements(dmlat) eq 0 then dmlat = 0.1d
    if n_elements(dmlon) eq 0 then dmlon = 0.2d

    mlat_bins = make_bins(mlat_range, dmlat, inner=1)
    mlon_bins = make_bins(mlon_range, dmlon, inner=1)
    nmlat_bin = n_elements(mlat_bins)
    nmlon_bin = n_elements(mlon_bins)
    image_size = [nmlon_bin,nmlat_bin]
    mlon = mlon_bins # (fltarr(image_size[1])+1)
    mlat = (fltarr(image_size[0])+1) # mlat_bins
    xpos = (mlon-mlon_range[0])/(mlon_range[1]-mlon_range[0])*(image_size[0]-1)
    ypos = (mlat-mlat_range[0])/(mlat_range[1]-mlat_range[0])*(image_size[1]-1)


    return, dictionary($
        'image_size', image_size, $
        'mlat_range', mlat_range, $
        'mlon_range', mlon_range, $
        'mlon_bins', mlon_bins, $
        'mlat_bins', mlat_bins, $
        'dmlon', dmlon, $
        'dmlat', dmlat, $
        'pixel_mlon', mlon, $
        'pixel_mlat', mlat, $
        'pixel_xpos', xpos, $
        'pixel_ypos', ypos )

end


info = mlon_image_rect_info()
end