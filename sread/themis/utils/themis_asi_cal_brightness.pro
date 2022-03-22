;+
; Calibrate the background count for given asf image.
;-

function calc_baseline, asi_raw, width

    ; Truncate data into sectors of the wanted width
    nframe = n_elements(asi_raw)
    nx = floor(nframe/width)
    sec_pos = findgen(nx)/(nx-1)*(nframe-1)
    nsec = n_elements(sec_pos)-1
    frames = dindgen(nframe)

    ; Get the min value within each sector.
    xxs = fltarr(nsec)
    yys = fltarr(nsec)
    for kk=0,nsec-1 do begin
        yys[kk] = min(asi_raw[sec_pos[kk]:sec_pos[kk+1]-1], index)
        ;xxs[kk] = sec_pos[kk]+index  ; This causes weird result.
        xxs[kk] = (sec_pos[kk]+sec_pos[kk+1])*0.5
    endfor
    ; Add sample points at the beginning and end of the raw data.
    tx = 0
    ty = min([yys[tx],asi_raw[tx]])
    xxs = [tx,xxs]
    yys = [ty,yys]
    tx = -1
    ty = min([yys[tx],asi_raw[tx]])
    xxs = [xxs,nsec+tx]
    yys = [yys,ty]

    ; Smooth after interpolation to make the background continuous.
    time_bg = smooth(interpol(yys,xxs,frames), width*0.5, edge_mirror=1)
    return, time_bg

end


; sample width does not significantly affect algorithm speed.
pro themis_asi_cal_brightness, asf_var, newname=newname, sample_widths=sample_widths

    if n_elements(newname) eq 0 then newname = asf_var+'_norm'
    get_data, asf_var, times, imgs_raw, limits=lim
    image_size = size(reform(imgs_raw[0,*,*]), dimensions=1)
    nframe = n_elements(times)
    max_count = 65535

;---Mapping the count to wanted width.
    counts = findgen(max_count+1)
    widths = (1-tanh((counts-1.2e4)/1e4))*0.5*(600-3)+3
;    widths = (1-tanh((counts-1.5e4)/0.5e4))*0.5*(600-3)+3    
;    adaptive_widths = widths[imgs_raw]

;---Calculate a smooth background to extract fast moving structures.
    if n_elements(sample_widths) eq 0 then sample_widths = [600d,250,50,10,1]
    nsample_width = n_elements(sample_widths)
    sample_bgs = fltarr(nframe,nsample_width)
    imgs_bg = imgs_raw

    if nframe le max(sample_widths) then begin
        for ii=0,image_size[0]-1 do begin
            for jj=0,image_size[1]-1 do begin
                bg = imgs_raw[*,ii,jj]
                imgs_bg[*,ii,jj] = min(bg)
            endfor
        endfor
    endif else begin
        for ii=0,image_size[0]-1 do begin
            for jj=0,image_size[1]-1 do begin
                bg = imgs_raw[*,ii,jj]
                bg_min = min(bg)
                if bg_min eq max(bg) then begin
                    imgs_bg[*,ii,jj] = bg_min
                    continue
                endif

                ; Calculate the backgrounds at sample width.
                for kk=0,nsample_width-1 do begin
                    wd = sample_widths[kk]
                    if wd eq 600 then begin
                        sample_bgs[*,kk] = bg_min
                        continue
                    endif else if wd eq 1 then begin
                        sample_bgs[*,kk] = bg
                    endif else begin
                        sample_bgs[*,kk] = calc_baseline(bg, wd)
                    endelse
                endfor

                ; Calculate the background at the wanted width.
                relative_count = round(sample_bgs[*,-2])<max_count;-sample_bgs[*,0])
                for kk=0,nframe-1 do begin
;                   wd = adaptive_widths[kk,ii,jj]*0.5
                    wd = widths[relative_count[kk]]
                    imgs_bg[kk,ii,jj] = interpol(sample_bgs[kk,*],sample_widths,wd, quadratic=1)
                endfor
            endfor
        endfor
    endelse
    
    index = where(imgs_raw eq max_count*0.8, count)
    if count ne 0 then imgs_bg[index] = imgs_raw[index]
    
    store_data, newname, times, imgs_raw-imgs_bg, limits=lim
end



time_range = time_double(['2016-01-28/08:00','2016-01-28/09:00'])
site = 'snkq'
site = 'whit'
test_time = '2016-01-28/08:47:30'

time_range = time_double(['2008-01-19/07:00','2008-01-19/08:00'])   ; moon and background fluctuations.
site = 'inuv'
test_time = '2008-01-19/07:04'
;
;time_range = time_double(['2016-10-13/12:00','2016-10-13/13:00'])   ; stable arc.
;site = 'gako'
;test_time = '2016-10-13/12:10'
;
;time_range = time_double(['2015-12-02/08:00','2015-12-02/09:00'])   ; Homayon example.
;site = 'rank'
;test_time = '2015-12-02/08:10'
;
;time_range = time_double(['2008-02-13/02:00','2008-02-13/03:00'])   ; Chu+2015.
;site = 'gill'   ; gill, kuuj, snkq
;test_time = '2008-02-13/02:44'

;time_range = time_double(['2015-10-05/09:00','2015-10-05/10:00'])   ; Homayon example
;site = 'snkq'
;
;time_range = time_double(['2015-12-07/08:00','2015-12-07/09:00'])   ; Homayon example
;site = 'inuv'   ;'kuuj','gill','rank','fsim'
;
time_range = time_double(['2013-03-17/07:00','2013-03-17/08:00'])   ; garbrielse's example
site = 'gako'


asi_var = 'thg_'+site+'_asf'
asi_norm_var = asi_var+'_norm'
if check_if_update(asi_var, time_range) then begin
    themis_read_asf, time_range, site=site
endif
tic
themis_asi_cal_brightness, asi_var, newname=asi_norm_var
toc
get_data, asi_norm_var, times, imgs_cal
end
