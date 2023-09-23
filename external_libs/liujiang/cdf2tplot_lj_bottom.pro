pro cdf2tplot_lj_bottom, filename, ncdf = ncdf, zvariable = zvariable, suffix = suffix, outnames = outnames
;;;; get the varnames of a cdf and store to be a tplot variable, bottom level (does not combine time and value into one tname.
;; filename: the full path of the cdf
;; ncdf: set if loading an ncdf file
;; suffix: the suffix to add to the tplot variables.
;; outnames: out put, the var names that have been loaded
;; The stored tplot names will be in the name 'name_RAW'+suffix, containing a struct {data:data, type:type_string}

if keyword_set(suffix) then suffix_add = suffix else suffix_add = ''

if ~keyword_set(varnames) then begin
	cdf_var_show, filename, ncdf = ncdf, zvariable = zvariable, varnames = varnames_load
endif else varnames_load = varnames

if (n_elements(varnames_load) gt 1) or ~strcmp(varnames_load[0], '') then begin
	outnames = strarr(n_elements(varnames_load))
	if keyword_set(ncdf) then cdfid = ncdf_open(filename) else cdfid = cdf_open(filename)
	for i = 0, n_elements(varnames_load)-1 do begin
		if keyword_set(ncdf) then begin
			;info_strt = ncdf_varinq(cdfid, varnames_load[i]) 
			type_this = 'ncdf' ;; finish the previous line to get actual type
			ncdf_varget, cdfid, varnames_load[i], value ;;; Not sure whether load only one record or entire record, need to check.
		endif else begin
			info_strt1 = cdf_varinq(cdfid, varnames_load[i], zvariable = zvariable)
			type_this = info_strt1.datatype
			cdf_control, cdfid, var=varnames_load[i], get_var_info = info_strt2, zvariable = zvariable
			cdf_varget, cdfid, varnames_load[i], value, zvariable = zvariable, REC_COUNT = info_strt2.maxrec+1
			;stop
		endelse

		store_data, varnames_load[i]+'_RAW'+suffix_add, data = {data:value, type:type_this}
		outnames[i] = varnames_load[i]+'_RAW'+suffix_add 
	endfor
	if keyword_set(ncdf) then ncdf_close, cdfid else cdf_close, cdfid
endif else begin
	message, 'Varnames not right'
endelse
end
