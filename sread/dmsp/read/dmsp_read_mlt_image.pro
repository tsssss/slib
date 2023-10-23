;+
; Read MLT image.
;-

function dmsp_read_mlt_image, input_time_range, probe=probe, id=datatype, $
    errmsg=errmsg, get_name=get_name, update=update

    prefix = 'dmsp'+probe+'_'
    errmsg = ''
    retval = !null
    

    if n_elements(datatype) eq 0 then datatype = 'lbhs'
    mlt_image_var = prefix+'mlt_image_'+datatype
    if keyword_set(get_name) then return, mlt_image_var

    pad_time = 1*3600d
    time_range = time_double(input_time_range)+[-1,1]*pad_time
    if keyword_set(update) then del_data, mlt_image_var
    if ~check_if_update(mlt_image_var, time_range) then return, mlt_image_var
    files = dmsp_load_ssusi(time_range, probe=probe, errmsg=errmsg)
    if errmsg ne '' then begin
        errmsg = 'No ssusi data ...'
        return, retval
    endif

    all_datatypes = ['','1216','1356','lbhs','lbhl','energy']
    datatype_index = where(all_datatypes eq datatype, count)
    if count eq 0 then return, retval
    
    hems = ['NORTH','SOUTH']
    tformat = 'YYYYDOYThhmmss'
    secofday = 86400d


    hem_time_ranges = list()
    hem_tags = list()
    mlt_images = list()
    foreach file, files do begin
        base = file_basename(file)
        info = strsplit(base,'_-',extract=1)
        file_time_range = time_double(info[4:5],tformat=tformat)
        mlat_vars = dmsp_read_mlat_vars(file_time_range, probe=probe, errmsg=errmsg)
        if errmsg ne '' then continue
        mlat_var = mlat_vars[0]
        mlt_var = mlat_vars[1]
        mlats = get_var_data(mlat_var, times=times)
        foreach hem, hems do begin
            suffix = '_'+hem
            time_var = 'UT_'+strmid(hem,0,1)
            
            year = netcdf_read_var('YEAR', filename=file)
            doy = netcdf_read_var('DOY', filename=file)
            date = sfmdate(string(year,format='(I4)')+string(doy,format='(I03)'),'%Y%j')
            
            if datatype eq 'energy' then begin
                the_var = 'ENERGY_FLUX'+suffix+'_MAP'
                mlt_image = netcdf_read_var(the_var, filename=file)
            endif else begin
                the_var = 'DISK_RADIANCEDATA_INTENSITY'+suffix
                data = netcdf_read_var(the_var, filename=file)
                mlt_image = reform(data[*,*,datatype_index])
            endelse
            
            mlat_range = (hem eq 'NORTH')? [50,90]: [-90,-50]
            index = where_pro(mlats, '[]', mlat_range, count=count)
            if count eq 0 then continue
            sections = time_to_range(index,time_step=1)
            nsection = n_elements(sections[*,0])
            if nsection ge 1 then begin
                durations = sections[*,1]-sections[*,0]
                tmp = max(durations, index)
                sections = sections[index,*]
            endif
            the_times = times[sections[0]:sections[1]]
            hem_time_range = minmax(the_times)

            hem_time_ranges.add, hem_time_range
            hem_tags.add, hem
            mlt_images.add, mlt_image
            
            ; Try to get the time range of the image, but the times in file are problematic:
            ; 1. jump when across two days
            ; 2. the north hemisphere times span the entire file time range.
;            orig_times = netcdf_read_var(time_var, filename=file)*3600+date
;            times = sort_uniq(orig_times[where(orig_times ne date)])
;            index = where(times gt file_time_range[1]+600, count)
;            if count ne 0 then times[index] -= secofday
;            times = sort_uniq(times)
;            dtimes = times[1:-1]-times[0:-2]
;            hem_time_range = minmax(times)
;            hem_time = median(times)
        endforeach
    endforeach

    if n_elements(hem_tags) eq 0 then begin
        errmsg = 'No ssusi or position data ...'
        return, retval
    endif
    hem_time_ranges = hem_time_ranges.toarray()
    hem_tags = hem_tags.toarray()
    if datatype eq 'energy' then begin
        unit = 'mW/m!U2!N'
        mlt_images = mlt_images.toarray()
    endif else begin
        unit = 'kR'
        mlt_images = mlt_images.toarray()*1e-3  ; convert R to kR.
    endelse
    common_times = total(hem_time_ranges,2)*0.5
    store_data, mlt_image_var, common_times, mlt_images
    
    image_size = size(reform(mlt_images[0,*,*]),dimensions=1)
    imgsz = image_size[0]
    mlt_range = [-1,1]*12d
    mlat_range = [50d,90]
    minlat = mlat_range[0]
    maxlat = mlat_range[1]
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
    pixel_mlt = mlt_bin_centers
    pixel_mlat = mlat_bin_centers

    zrange = [0.05,5]
    zlog = 1
    ct = 49
    if datatype eq 'energy' then begin
        zrange = [-1,1]*20
        zlog = 0
        ct = 70
    endif
    
    add_setting, mlt_image_var, smart=1, dictionary($
        'requested_time_range', time_range, $
        'display_type', 'mlt_image', $
        'pixel_mlt', pixel_mlt, $
        'pixel_mlat', pixel_mlat, $
        'zlog', zlog, $
        'zrange', zrange, $
        'unit', unit, $
        'wavelength', strupcase(datatype), $
        'color_table', ct, $
        'mlat_range', mlat_range, $
        'mlt_range', mlt_range, $
        'time_range', hem_time_ranges, $
        'hemisphere', hem_tags )

    return, mlt_image_var
end

time_range = time_double(['2015-03-07/06:00','2015-03-07/06:46'])
probe = 'f19'
var = dmsp_read_mlt_image(time_range, probe=probe, id='energy')
stop

;; has glitch in ut_s
;time_range = ['2015-03-12/07:50','2015-03-12/09:10']
;probe = 'f19'
;files = dmsp_load_ssusi(time_range, probe=probe)
;stop
;var = dmsp_read_mlt_image(time_range, probe=probe)

; ut crossing two days have problem.
time_range = ['2013-04-30/22:17','2013-05-01/05:07']
probe = 'f17'
files = dmsp_load_ssusi(time_range, probe=probe)
stop
;time_range = ['2015-03-12/08:50','2015-03-12/09:10']
;probe = 'f19'
;time_range = time_double(['2017-09-07/16:04','2017-09-07/16:17'])
;probe = 'f17'
var = dmsp_read_mlt_image(time_range, probe=probe)
end