;+
; Un-compress an MLT image in [m] to an array in [nxn], where m is the number of 
; "good pixels", i.e., pixels with non-zero brightness. The original image size
; is [nxn].
; 
; info. An info structure, containing {index,value,elev,image_size}. If pointer
;   is set, info is a pointer to info.
;-

function themis_asi_unzip_mltimg, info, elev=elev, errmsg=errmsg, pointer=pointer
    
    if keyword_set(pointer) then info = *info
    
    ; Image size.
    image_size = info.image_size
    
    ; Re-construct images.
    npixel = image_size[0]*image_size[1]
    mltimg = fltarr(npixel)
    elev = fltarr(npixel)
    
    mltimg[info.index] = info.value
    elev[info.index] = info.elev
    
    mltimg = reform(mltimg, image_size)
    elev = reform(elev, image_size)
    
    return, mltimg
    
end