;+
; Test when data begins and ends.
;-

time_range = time_double(['2013-03-17/05:00','2013-03-17/08:00'])
site = 'mcgr'
prefix = 'thg_'+site+'_'
asf_var = prefix+'asf'
if check_if_update(asf_var, time_range) then themis_read_asf, time_range, site=site, errmsg=errmsg
mlon_image_var = prefix+'mlon_image'
mlon_image_raw_var = prefix+'mlon_image_raw'
if check_if_update(mlon_image_raw_var, time_range) then begin
    themis_calc_asf_mlon_image_per_site, asf_var
    rename_var, mlon_image_var, to=mlon_image_raw_var
endif
mlon_image_cal_var = prefix+'mlon_image_cal'
if check_if_update(mlon_image_cal_var) then begin
    themis_asf_read_mlon_image_per_site, time_range, site=site, errmsg=errmsg
    rename_var, mlon_image_var, to=mlon_image_cal_var
endif
end