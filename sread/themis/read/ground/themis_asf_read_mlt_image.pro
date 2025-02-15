;+
; Read ASI mlt image.
; calibration_method=. 'simple','moon','moon_smooth',to be continued.
;-

function themis_asf_read_mlt_image, input_time_range, sites=sites, $
    errmsg=errmsg, get_name=get_name, update=update, $
    calibration_method=calibration_method, min_elev=min_elev, merge_method=merge_method, _extra=extra

    errmsg = ''
    retval = ''
    mlt_image_var = 'thg_asf_mlt_image'
    if keyword_set(get_name) then return, mlt_image_var
    if keyword_set(update) then del_data, mlt_image_var
    time_range = time_double(input_time_range)
    if ~check_if_update(mlt_image_var, time_range) then return, mlt_image_var
    
    mlon_image_var = themis_asf_read_mlon_image(input_time_range, sites=sites, $
        errmsg=errmsg, get_name=get_name, update=update, $
        calibration_method=calibration_method, min_elev=min_elev, merge_method=merge_method)
    if errmsg ne '' then return, retval

;---Rotate from mlon to mlt.
    mlt_image_var = mlon_image_to_mlt_image(mlon_image_var, output=mlt_image_var)
    options, mlt_image_var, 'requested_time_range', time_range
    return, mlt_image_var
    
end


time_range = ['2014-03-29/09:00','2014-03-29/10:00']
;sites = ['inuv','fsim','fsmi']
sites = ['inuv','fykn','fsmi','gill']
merge_method = 'merge_elev'
min_elev = 2.5


time_range = ['2008-02-25/05:10','2008-02-25/05:50']
;sites = ['inuv','fsim','fsmi']
sites = ['rank','gill']
merge_method = 'merge_elev'
min_elev = [10,5]

time_range = ['2014-12-30/05:43','2014-12-30/05:44:12']
sites = ['gill']
min_elev = 10

time_range = ['2014-11-16/03:15','2014-11-16/03:15:24']
sites = ['fsim']
min_elev = 10

;time_range = time_double(['2013-03-17/08:30','2013-03-17/09:30'])
;sites = ['chbg']

time_range = ['2016-08-03/05:30','2016-08-03/06:30']
sites = ['gill','tpas','pina']
min_elev = 2.5
merge_method = 'max_elev'

var = themis_asf_read_mlt_image(time_range, sites=sites, merge_method=merge_method, min_elev=min_elev)
get_data, var, times, mlt_images, limits=lim
sgopen, 1, size=[6,6]
;sgtv, bytscl(reform(mlt_images[-1,*,*]), min=0,max=1d4, top=254), position=tpos, ct=49, resize=1
;plot, minmax(lim.mlt_bins), minmax(lim.mlat_bins), nodata=1, xstyle=1, ystyle=1, position=tpos, noerase=1
;foreach ty, [65,70] do plots, !x.crange, ty+[0,0], linestyle=1
stop
foreach time, times, tid do sgtv, bytscl(reform(mlt_images[tid,*,*]),min=0,max=1d4, top=254), position=[0,0,1,1], ct=49
stop

time_range = time_double(['2013-03-17/07:00','2013-03-17/08:00'])
sites = ['mcgr','fykn','gako','fsim', $
    'fsmi','tpas','gill','snkq','pina','kapu']
end