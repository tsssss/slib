;+
; Read Polar MLT image.
;-

pro polar_read_mlt_image, time, errmsg=errmsg, $
    local_root=local_root, version=version, renew_file=renew_file, _extra=extra

    compile_opt idl2
    on_error, 0
    errmsg = ''

;---Check inputs.
    sync_threshold = 0
    if n_elements(local_root) eq 0 then local_root = join_path([diskdir('data'),'polar'])
    if n_elements(version) eq 0 then version = 'v01'


;---Init settings.
    valid_range = time_double(['1996-03-20/00:00','2008-04-16/24:00'])
    base_name = 'po_uvi_mltimg_%Y_%m%d_'+version+'.cdf'
    local_path = [local_root,'uvi','mltimg','%Y']

    request = dictionary($
        'pattern', dictionary($
            'local_file', join_path([local_path,base_name]), $
            'local_index_file', join_path([local_path,default_index_file()])), $
        'valid_range', valid_range, $
        'cadence', 'day', $
        'extension', fgetext(base_name), $
        'var_list', list($
            dictionary($
                'in_vars', ['mltimg'], $
                'out_vars', ['po_mltimg'], $
                'time_var_name', 'ut_sec', $
                'time_var_type', 'unix')))

;---Find files, read variables, and store them in memory.
    files = prepare_files(request=request, errmsg=errmsg, local_files=files, $
        file_times=file_times, time=time, nonexist_files=nonexist_files)
    if n_elements(nonexist_files) ne 0 then begin
        foreach file, request.nonexist_files do begin
            file_time = file.file_time
            local_file = file.local_file
            polar_read_mlt_image_gen_file, file_time, filename=local_file
        endforeach
        files = prepare_files(request=request, errmsg=errmsg, local_files=files, $
            file_times=file_times, time=time, nonexist_files=nonexist_files)
    endif
    if n_elements(files) eq 0 then begin
        errmsg = 'Not enough info for MLT image ...'
        return
    endif

;---Read data from files and save to memory.
    read_files, time, files=files, request=request

    mlt_bins = cdf_read_var('mlt_bins', filename=files[0])
    mlat_bins = cdf_read_var('mlat_bins', filename=files[0])
    
    imgsz = (size(mlt_bins,dimensions=1))[0]
    mltimg_size = [imgsz,imgsz]
    mlt_range = [-1,1]*12d
    minlat = 50d
    maxlat = 90d
    mlat_range = [minlat,maxlat]
    ; Pixel x and y coord, in [0,1].
    xx_bins = (dblarr(imgsz)+1) ## smkarthm(0,1,imgsz,'n')
    yy_bins = transpose(xx_bins)
    ; Convert to [-1,1].
    xx_bins = xx_bins*2-1
    yy_bins = yy_bins*2-1
    rr_bins = sqrt(xx_bins^2+yy_bins^2)
    tt_bins = atan(yy_bins,xx_bins)     ; in [-pi,pi]
    ; Convert to mlat and mlt.
    ; in mlat_range.
    mlat_bin_centers = max(maxlat)-rr_bins*abs(maxlat-minlat);/max(rr_bins)
    ; in [-12,12], i.e., 0 at midnight. Need to shift by 90 deg.
    mlt_bin_centers = (tt_bins*constant('deg')+90)/15
    index = where(mlt_bin_centers lt -12, count)
    if count ne 0 then mlt_bin_centers[index] += 24
    index = where(mlt_bin_centers gt 12, count)
    if count ne 0 then mlt_bin_centers[index] -= 24
    mlt_bins = mlt_bin_centers
    mlat_bins = mlat_bin_centers
    
    store_data, 'po_mltimg', limits={$
        mlt_bins: mlt_bins, $
        mlat_bins: mlat_bins }

end

time_range = time_double(['2001-10-22','2001-10-23'])
polar_read_mlt_image, time_range
get_data, 'po_mltimg', times, img
ntime = n_elements(times)
img_size = size(img[0,*,*],dimensions=1)

min_vals = fltarr(ntime)+!values.f_nan
max_vals = fltarr(ntime)+!values.f_nan
mean_vals = fltarr(ntime)+!values.f_nan
stddev_vals = fltarr(ntime)+!values.f_nan
counts = fltarr(ntime)+!values.f_nan
night_counts = fltarr(ntime)+!values.f_nan
for time_id=0,ntime-1 do begin
    timg = reform(img[time_id,*,*])
    index = where(timg gt 0, count)
    if count eq 0 then continue
    tmp = where(timg[*,0:img_size[1]/2] gt 0, night_count)
    timg = timg[index]
    counts[time_id] = count
    night_counts = night_count
    min_vals[time_id] = min(timg)
    max_vals[time_id] = max(timg)
    mean_vals[time_id] = mean(timg)
    stddev_vals[time_id] = stddev(timg)
endfor

ct = 40
top = 254
fig_xsize = img_size[0]*2
fig_ysize = img_size[1]*2

min_count = 5e3
min_stddev_val = 20
bad_index = where(counts le min_count or stddev_vals le min_stddev_val or finite(counts,/nan), $
    count, complement=good_index)
    
    foreach time_id, good_index do begin
        timg = reform(img[time_id,*,*])
        sgopen, 1, xsize=fig_xsize, ysize=fig_ysize
        sgtv, bytscl(timg, min=50, max=300, top=top), ct=ct, position=[0,0,1,1]
        wait, 0.2
    endforeach
stop
foreach time_id, bad_index do begin
    timg = reform(img[time_id,*,*])
    sgopen, 0, xsize=fig_xsize, ysize=fig_ysize
    sgtv, timg, ct=ct, position=[0,0,1,1]
    wait, 0.2
endforeach

end
