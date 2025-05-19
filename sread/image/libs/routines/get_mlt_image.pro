


pro get_mlt_image, $
;input variables
	image, $
	magentic_lat, $
	mlt, $
	min_lat, $
	sphere, $
	mcell = mcell, $
;output variable
	mlt_image

;23 nov 98 m. brittnacher - new algorithm, not flux preserving but rather intensity preserving;
;undersampled data is restored by averaging nearest neighbors

;inputs:
;image     		calibrated image in photon flux units (col * row)
;magentic_lat   magnetic latitude (col * row)
;mlt       		mlt hour angle (col * row)
;min_lat   		minimum latitude (scalar)
;sphere_flag	1: northern hemisphere, -1: southern hemisphere

;output		   	[ ncell = 4*(90 - min_lat) ]
;mlt_image   	transformed image (ncell * ncell)

dims = size(image, /dimensions)
col = dims[0]
row = dims[1]

coef = 4
if n_elements(mcell) eq 0 then begin
    ncell = fix(coef * (90.0 - min_lat))
    mcell = ncell + 1
endif else begin
    ncell = mcell-1
endelse
lat_lim = (90.0 - min_lat)
del = 2.0 * lat_lim / float(ncell)

; use area weighting to populate cells
mlt_image = replicate(0.,mcell,mcell)
mlt_cnt = replicate(0.,mcell,mcell)
total_cnts = 0.

case sphere of
	1: $
	begin
;======= northern hemisphere ==========
;transform from lat/lon to cartesian coordinates
	  xpr = lat_lim + (90.0 - magentic_lat) * sin(15d * mlt * !dtor)
	  ypr = lat_lim - (90.0 - magentic_lat) * cos(15d * mlt * !dtor)

		for j = 0, row - 1 do begin
			for i = 0, col - 1 do begin
;		   		m = floor(xpr[i, j]/del)
;			   	n = floor(ypr[i, j]/del)
			    m = xpr[i,j] / del
				n = ypr[i,j] / del
		    	if (magentic_lat[i,j] gt min_lat) then begin
		  	  		mlt_image[m,n] = mlt_image[m,n] + image[i, j]
		    		mlt_cnt[m, n] = mlt_cnt[m, n] + 1
					total_cnts = total_cnts + image[i, j]
			    endif
			endfor
		endfor

;create mlt and lat arrays
		x = (del * findgen(mcell) - lat_lim) # replicate(1.0, mcell)
		y = transpose(x)
		mlat = 90.0 - sqrt(x * x + y * y)
		mlon = (atan(-x, y) / !dtor + 180.0) / 15.0

;fill in undersampled bins within the mlt dial
		usndx = where(mlt_cnt eq 0.0 and mlat ge min_lat, uscount)
		subarr = fltarr(3,3)
		temp_image = replicate(0.0, mcell, mcell)
		if (uscount gt 0) then begin
			for i = 0, uscount - 1 do begin
			m = usndx[i] mod mcell
			n = floor(1.0 * usndx[i] / mcell)
		    if (m * n gt 0 and m lt mcell - 1 and n lt mcell - 1) then begin
				subimg = mlt_image[m-1:m+1, n-1:n+1]
				subcnt = mlt_cnt[m-1:m+1, n-1:n+1]
				good_ndx = where(subcnt gt 0, ngdndx)
				if (ngdndx gt 0) then $
;					temp_image[m, n] = total(subimg(good_ndx))/ngdndx
					temp_image[m,n] = total(subimg[good_ndx]) / total(subcnt[good_ndx])
				endif
			endfor
		endif
		mlt_image = mlt_image + temp_image
	endcase

	0: $
	begin

;========== southern hemisphere =========
;transform from lat/lon to cartesian coordinates
		xpr = lat_lim - (-90.0 - magentic_lat) * sin(15d * mlt * !dtor)
		ypr = lat_lim + (-90.0 - magentic_lat) * cos(15d * mlt * !dtor)

		for j = 0, row - 1 do begin
			for i = 0, col - 1 do begin
;				m = floor(xpr[i, j]/del)
;				n = floor(ypr[i, j]/del)
				m = xpr[i, j] / del
				n = ypr[i, j] / del
				if (magentic_lat[i, j] lt -min_lat) then begin
					mlt_image[m, n] = mlt_image[m, n] + image[i, j]
					mlt_cnt[m, n] = mlt_cnt[m, n] + 1
					total_cnts = total_cnts + image[i, j]
				endif
			endfor
		endfor

;create mlt and lat arrays
		x = (del * findgen(mcell) - lat_lim) # replicate(1.0, mcell)
		y = transpose(x)
		mlat = 90.0 - sqrt(x * x + y * y)
		mlon = (atan(-x, y) / !dtor + 180.0) / 15.0

;fill in undersampled bins within the mlt dial
		usndx = where(mlt_cnt eq 0.0 and mlat ge min_lat, uscount)
		subarr = fltarr(3, 3)
		temp_image = replicate(0.0, mcell, mcell)
		if (uscount gt 0) then begin
			for i = 0, uscount - 1 do begin
				m = usndx[i] mod mcell
				n = floor(1.0 * usndx[i] / mcell)
				if (m * n gt 0 and m lt mcell - 1 and n lt mcell - 1) then begin
					subimg = mlt_image[m-1:m+1, n-1:n+1]
					subcnt = mlt_cnt[m-1:m+1, n-1:n+1]
					good_ndx = where(subcnt gt 0, ngdndx)
					if (ngdndx gt 0) then $
;						temp_image[m, n] = total(subimg(good_ndx))/ngdndx
						temp_image[m, n] = total(subimg[good_ndx]) / total(subcnt[good_ndx])
				endif
			endfor
		endif

		mlt_image = mlt_image + temp_image
	endcase
;==========================================
endcase

; average all bins
mlt_cnt = mlt_cnt > 1.  ; make sure we do not divide by 0
mlt_image = mlt_image / mlt_cnt
;
;print,'before scaling: ',max(mlt_image),mean(mlt_image),$
;	total_cnts,total(mlt_image),total_cnts/total(mlt_image)
;
;mlt_image=mlt_image*total_cnts/total(mlt_image)

end
