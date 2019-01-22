;+
; Compress a nxn MLT image to an array in [m], where m is the number of 
; "good pixels", i.e., pixels with non-zero brightness. To keep the 
; flexibility of merging MLT images from sites, we also need to compress
; the elevation of the good pixels. To be able to recover the image, we
; need the image size of the MLT image and the indices of the good pixels.
; 
; Return a structure, which has index, value, elev. If pointer is set, return
; a pointer points to the structure.
;-

function themis_asi_zip_mltimg, mltimg, elev=elev, pointer=pointer
    
    ; Image size.
    image_size = size(mltimg, /dimensions)
    
    good_pixels = where(mltimg gt 0, ngood_pixel)
    info = {index: good_pixels, $
        value: mltimg[good_pixels], $
        elev: elev[good_pixels], $
        image_size:image_size}
    
    if keyword_set(pointer) then return, ptr_new(info) else return, info
    
end