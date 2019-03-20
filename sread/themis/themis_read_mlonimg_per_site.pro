;+
; Read "MLon image" for a given time and site. An MLon image is the image
; has uniform MLon and MLat as its coordinate. The main difference between
; the MLon image and the raw ASF image is the former unwraps the fish-eye
; perspective in the latter.
;
; Note: the value at each pixel is in the raw count, not some physical unit.
;
; time. A time or time range in UT sec.
; site. A string for the site, see themis_asi_sites for available sites.
; height. A number sets the assumed emission height in km altitude. The default value is 110 km. Do not recommend to set this unless intentional.
;-

pro themis_read_mlonimg_per_site, time, site=site, errmsg=errmsg, $
    height=height, extra=_extra

    compile_opt idl2
    on_error, 0
    errmsg = ''


;---Check inputs.
    if n_elements(time) eq 0 then begin
        errmsg = handle_error('No input time ...')
        return
    endif
    if size(time0,/type) eq 7 then time0 = time_double(time0)

    if n_elements(site) eq 0 then begin
        errmsg = handle_error('No input site ...')
        return
    endif
    pre0 = 'thg_'+site+'_'
    pre1 = pre0+'asf_'

    if n_elements(height) eq 0 then height = 110d   ; km.


;---Read ASF raw image, after preprocessed; convert to MLon image.
    ; thg_site_asf and thg_site_asf_elev
    themis_read_asf, time, site=site, errmsg=errmsg, extra=_extra
    if errmsg ne '' then return

    ; Check for the mapping indices.
    ; thg_site_asf_[old,new]_dict
    themis_read_mlonimg_metadata, time, site=site, errmsg=errmsg

    asfimg_var = pre0+'asf'
    old_image_size = get_var_data(pre1+'old_image_size')
    get_data, asfimg_var, times, oldimgs
    nrec = n_elements(times)
    tmp = (size(oldimgs,/dimensions))[1:2]
    if tmp[0] ne old_image_size[0] or tmp[1] ne old_image_size[1] then begin
        errmsg = handle_error('ASF image size does not agree with meta-data ...')
        return
    endif

    mlonimg_var = pre1+'mlonimg'
    new_image_size = get_var_data(pre1+'new_image_size')
    newimgs = fltarr([nrec,new_image_size])
    new_1d_size = product(new_image_size)

    new_dict = get_var_data(pre1+'new_dict')
    new_uniq_index = get_var_data(pre1+'new_uniq_index')

    lprmsg, 'Converting ASF raw image to MLon image ...'
    for jj=0, nrec-1 do begin
        lprmsg, '    '+time_string(times[jj])+' ...'
        old_image = (oldimgs[jj,*,*])[*]
        new_image = fltarr(new_1d_size)
        foreach new_index_1d, new_uniq_index, ii do begin
            old_index_1d = new_dict[ii]
            val = old_image[old_index_1d]
            if n_elements(val) gt 1 then val = median(val)
            new_image[new_index_1d] = val
        endforeach
        newimgs[jj,*,*] = reform(new_image, new_image_size)
    endfor

    store_data, mlonimg_var, times, newimgs

end


time = time_double(['2014-08-28/10:00','2014-08-28/10:01'])
site = 'whit'
themis_read_mlonimg_per_site, time, site=site

end
