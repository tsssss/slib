pro combine_spec, tp1, tp2, newname = newname, interpol2more = interpol2more, eV2keV_1st = eV2keV_1st, eV2keV_2nd = eV2keV_2nd, MeV2keV_2nd = MeV2keV_2nd, trim_high = trim_high, seperation = seperation
;;;; combine two spectrums (tplot variable), tp1 and tp2
;;;; make sure time ranges are the same
;;;; interpol2more: set to force the fewer data points interpolate to more data points, default is from more to less
;;;; eV2keV: transform eV unit to keV
;;;; MeV2keV: transform MeV unit to keV, if this set, will chech whether the variable is REPT, if so , the value of fluxes will also be changed to /keV by dividing by 1000.
;;;; seperation: an output, the seperation energy of the two combined spectra
;;;; Note: the output's energy values is always in keV
;;;; the data value can be either flux or eflux
;;;; For overlapping energy ranges: default: trim the upper energies of the lower-energy data. If trim_high is set, then trim the lower energy of the higher-energy data.
;;;; Dependent on: TV_EXIST
;; Created: 05/04/2012, Jiang Liu
;; Updated: 09/18/2023, Jiang Liu

if keyword_set(newname) then outname = newname else outname = 'combined'

if tv_exist(tp1) and (~tv_exist(tp2)) then begin
	print, 'COMBINE_SPEC: '+tp1+' does not exist, the combined spec is identical to '+tp2
	copy_data, tp1, outname
endif

if tv_exist(tp2) and (~tv_exist(tp1)) then begin
	print, 'COMBINE_SPEC: '+tp2+' does not exist, the combined spec is identical to '+tp1
	copy_data, tp2, outname
endif

if tv_exist(tp1) and tv_exist(tp2) then begin
	get_data, tp1, x1, y1, v1
	get_data, tp2, x2, y2, v2
	if keyword_set(eV2keV_1st) then begin
		v1 = v1/1000.
	endif
	if keyword_set(eV2keV_2nd) then begin
		v2 = v2/1000.
	endif
	if keyword_set(MeV2keV_2nd) then begin
		v2 = v2*1000.
		if strmatch(tp2, '*rept*') then begin
			;; change flux value to /keV
			y2 = y2/1000.
		endif
	endif
	
	;;; decide which one is the lower range
	v_small1 = min(v1, /nan)
	v_small2 = min(v2, /nan)
	if v_small1 lt v_small2 then begin
		v_small = v_small2 ;; v_small: the lower energy range of the higher energy data
		tp_h = tp2
		x_h = x2
		y_h = y2
		v_h = v2
		tp_l = tp1
		x_l = x1
		y_l = y1
		v_l = v1
	endif else begin
		v_small = v_small1
		tp_h = tp1
		x_h = x1
		y_h = y1
		v_h = v1
		tp_l = tp2
		x_l = x2
		y_l = y2
		v_l = v2
	endelse
	seperation = v_small

	
	;;; trim the low energy range data
	i_l_use = where(v_l[0,*] lt v_small, nbins_l_use) ;; trim the lower energy data's bins that is higher than higher energy data's lower end
	if nbins_l_use gt 1 then begin
		y_l_use = y_l[*,i_l_use]
		v_l_use = v_l[*,i_l_use]

		;;;; add NaN bins if the two are seperated too apart (10 times)
		;rate_h = v_h[0,1]/v_h[0,0]
		;rate_l = v_l_use[0,-1]/v_l_use[0,-2]
		;rate_hl = min(v_h)/max(v_l_use)
		;if (rate_hl gt 10*rate_l) and (rate_hl gt 10*rate_h) then begin
		;	v_l_use_add = replicate(rate_hl^(1./3), n_elements(x_l))
		;	v_h_add = replicate(rate_hl^(2./3), n_elements(x_h))
		;	v_l_use = [[v_l_use], [v_l_use_add]]
		;	v_h = [[v_h_add], [v_h]]
		;	y_l_use = [[y_l_use], [replicate(0, n_elements(x_l))]]
		;	y_h = [[replicate(-1, n_elements(x_h))], [y_h]]
		;endif

		;;;; interpolate the data
		;; find out which have more counts
		ndata_h = n_elements(x_h)
		ndata_l = n_elements(x_l)
		;; interpolate to less
		if ((ndata_h gt ndata_l) and ~keyword_set(interpol2more)) or ((ndata_h lt ndata_l) and keyword_set(interpol2more)) then begin
			ndata_full = ndata_l
		endif else begin
			ndata_full = ndata_h
		endelse
	
		if ndata_full eq ndata_h then begin
			;; interpolate the low energy variable
			x_full = x_h
			y_l_new = dblarr(ndata_full, nbins_l_use)
			v_l_new = dblarr(ndata_full, nbins_l_use)
			for i = 0, nbins_l_use-1 do begin
				y_l_new[*,i] = interpol(y_l_use[*,i], x_l, x_h)
				v_l_new[*,i] = interpol(v_l_use[*,i], x_l, x_h)
			endfor
			y_full = [[y_l_new], [y_h]]
			v_full = [[v_l_new], [v_h]]
		endif else begin
			;; interpolate the high energy variable
			x_full = x_l
			nbins_h = n_elements(y_h[0,*])
			y_h_new = dblarr(ndata_full, nbins_h)
			v_h_new = dblarr(ndata_full, nbins_h)
			for i = 0, nbins_h-1 do begin
				y_h_new[*,i] = interpol(y_h[*,i], x_h, x_l)
				v_h_new[*,i] = interpol(v_h[*,i], x_h, x_l)
			endfor
			y_full = [[y_l_use], [y_h_new]]
			v_full = [[v_l_use], [v_h_new]]
		endelse
		store_data, outname, data = {x:x_full, y:y_full, v:v_full}
		options, outname, ysubtitle = '[keV]'
	endif else begin
		print, 'RBSP_COMBINE_SPEC: No combined spectrum generated because energy ranges do not compliment!'
	endelse
endif
end
