;+
; Read ASI mlt image. Can merge asf and ast.
;
; sites=.
; calibration_method=. 'simple','moon','moon_smooth',to be continued.
;-

function themis_read_mlt_image, input_time_range, sites=sites, $
    min_elevs=min_elevs, resolutions=resolutions, $
    merge_method=merge_method, update=update, $
    get_name=get_name, calibration_method=calibration_method, _extra=extra

    errmsg = ''
    retval = ''
    mlt_image_var = 'thg_mlt_image'
    if keyword_set(get_name) then return, mlt_image_var
    if keyword_set(update) then del_data, mlt_image_var
    time_range = time_double(input_time_range)
    if ~check_if_update(mlt_image_var, time_range) then return, mlt_image_var
    if time_range[-1] lt time_range[0] then message, 'Inconsistent ...'
    if total(time_range*[-1,1]) ge 12*3600d then message, 'Time range too long ...'

;---Get mlon image.
    mlon_image_var = themis_read_mlon_image(input_time_range, sites=sites, $
        min_elevs=min_elevs, resolutions=resolutions, $
        merge_method=merge_method, errmsg=errmsg, $
        calibration_method=calibration_method)
    if errmsg ne '' then return, retval

;---Rotate from mlon to mlt.
    mlt_image_var = mlon_image_to_mlt_image(mlon_image_var, output=mlt_image_var)
    options, mlt_image_var, 'requested_time_range', time_range
    return, mlt_image_var

end

time_range = time_double(['2015-01-04/12:30','2015-01-04/13:30'])
sites = ['fykn','whit','fsim','atha','gill']
nsite = n_elements(sites)
min_elevs = fltarr(nsite)+7.5
min_elevs = [10d,3,10,8,8]
resolutions = strarr(nsite)+'asf'
index = where(sites eq 'mcgr', count)
if count ne 0 then resolutions[index] = 'ast'
mlt_image_var = themis_read_mlt_image(time_range, sites=sites, merge_method='merge_elev', min_elevs=min_elevs, resolutions=resolutions, calibration_method='simple')

mlt_images = get_var_data(mlt_image_var, times=times, settings=settings)
sgopen, 0, size=[6,6]

stop
zrange = [-1,1]*1e4
ct = 70
tpos = [0,0,1,1]
foreach time, times, time_id do sgtv, bytscl(reform(mlt_images[time_id,*,*]), min=zrange[0], max=zrange[1], top=254), position=tpos, ct=ct
stop


time_range = time_double(['2013-03-17/07:00','2013-03-17/08:00'])
sites = ['mcgr','fykn','gako','fsim', $
    'fsmi','tpas','gill','snkq','pina','kapu']

sites = ['kapu','snkq','gill','pina','fsmi','fsim']
time_range = time_double(['2013-03-17/05:30','2013-03-17/09:30'])
var = themis_asf_read_mlt_image(time_range, sites=sites, merge_method='merge_elev', min_elev=2.5)
end
