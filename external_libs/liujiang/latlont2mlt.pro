@aacgmidl.pro ;; need to compile this library

function latlont2mlt, time, latitude = latitude, longitude = longitude, mlat = mlat, mlon = mlon
;;; given time, (geographic) latitude, and longitude, compute the MLT
;; Inputs:
;;		time: can be time double or string, must be vertical
;;		latitude: geographic latitude, must be vertical
;;		longitude: geographic longitude, must be vertical
;;		The three inputs must have the same dimension, and must be vertical
;; Outputs:
;;		return value: the MLT, having the same dimension as the inputs.
;;		mlat: magnetic latitude
;;		mlon: magnetic longitude

aacgmidl ;; run this to use calc_MLT

tstruct = time_struct(time)
tsecs = double(tstruct.doy)*3600*24.+double(tstruct.hour)*3600.+double(tstruct.min)*60+double(tstruct.sec)+double(tstruct.fsec)
years_all = tstruct.year
magnetic = geo2mag_latlon([latitude, longitude])
mlat = magnetic[0,*]
mlon = magnetic[1,*]
mlt = dblarr(size(mlon,/dim))
for i = 0, n_elements(mlt)-1 do begin
	mlt[i] = calc_mlt(years_all[i], tsecs[i], mlon[i])
endfor

return, mlt
end
