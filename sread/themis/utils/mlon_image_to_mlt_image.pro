;+
; Convert MLon image to MLT image.
;
; mlon_image_var. A string of input mlon_image_var.
; to=. A string of output mlt_image_var.
;-

pro mlon_image_to_mlt_image, mlon_image_var, to=mlt_image_var, errmsg=errmsg

    errmsg = ''
    if n_elements(mlt_image_var) eq 0 then begin
        errmsg = 'No input mlt_image_var ...'
        return
    endif
    get_data, mlon_image_var, times, mlon_images, limits=lim
    ntime = n_elements(times)
    if ntime eq 1 and times[0] eq 0 then return

    midn_mlons = themis_asi_midn_mlon(times)
    rotation_angles = -midn_mlons  ; mlon=0 is along positive x, need a further 90 deg to move mlt=0 along negative y.
    mlt_images = temporary(mlon_images)
    for ii=0,ntime-1 do begin
       mlt_images[ii,*,*] = rot(reform(mlt_images[ii,*,*]), rotation_angles[ii])
    endfor

    store_data, mlt_image_var, times, mlt_images, limits=lim

    mlt_image_info = mlt_image_info()
    options, mlt_image_var, 'mlt_range', mlt_image_info.mlt_range
    options, mlt_image_var, 'pixel_mlt', mlt_image_info.pixel_mlt

end