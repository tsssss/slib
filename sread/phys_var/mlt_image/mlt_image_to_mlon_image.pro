;+
; Convert MLT image to MLon image.
;
; mlt_image_var. A string of input mlt_image_var.
; output=. A string of output mlon_image_var.
;-

function mlt_image_to_mlon_image, mlt_image_var, output=mlon_image_var, errmsg=errmsg

    errmsg = ''
    retval = ''
    if n_elements(mlt_image_var) eq 0 then begin
        errmsg = 'No input mlt_image_var ...'
        return, retval
    endif
    if n_elements(mlon_image_var) eq 0 then mlon_image_var = streplace(mlt_image_var, 'mlt', 'mlon')
    mlt_images = get_var_data(mlt_image_var, times=times, settings=mlt_image_settings)
    ntime = n_elements(times)
    if ntime eq 1 and times[0] eq 0 then return, retval

    midn_mlons = themis_asi_midn_mlon(times)
    rotation_angles = -(midn_mlons+90)  ; mlon=0 is along positive x, need a further 90 deg to move mlt=0 along negative y.
    mlon_images = temporary(mlt_images)
    for ii=0,ntime-1 do begin
       mlon_images[ii,*,*] = rot(reform(mlon_images[ii,*,*]), rotation_angles[ii])
    endfor

    half_size = mlt_image_settings.half_size
    mlon_image_settings = mlon_image_info(half_size)
    foreach key, ['unit'] do begin
        mlon_image_settings[key] = mlt_image_settings[key]
    endforeach
    mlon_image_var = var_store(mlon_image_var, mlon_images, times, settings=mlon_image_settings)

    return, mlon_image_var
    
end