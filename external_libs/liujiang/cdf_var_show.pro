pro cdf_var_show, filename, ncdf = ncdf, zvariable = zvariable, varnames = varnames_out
;;; show all the variable names of a CDF file.
;; filename: the full path of the cdf
;; ncdf: set if loading an ncdf file
;; zvariable: set to list zvariables (does not work for NCDF)
;; varnames: an output, gives the varnames contained by the CDF.

;;; open the file
if keyword_set(ncdf) then cdfid = ncdf_open(filename) else cdfid = cdf_open(filename)
;; get the general info: how many variables
if keyword_set(ncdf) then begin
	info = ncdf_inquire(cdfid)
	nvars = info.nvars
endif else begin
	info = cdf_inquire(cdfid)
	if keyword_set(zvariable) then nvars = info.nzvars else nvars = info.nvars
endelse

;; print the var names
if nvars gt 0 then begin
	varnames_out = strarr(nvars)
	for i = 0, nvars-1 do begin
		if keyword_set(ncdf) then var_prop = ncdf_varinq(cdfid, i) else var_prop = cdf_varinq(cdfid, i, zvariable = zvariable)
		print, var_prop.datatype+'  '+var_prop.name
		varnames_out[i] = var_prop.name
	endfor
endif else begin
	varnames_out = ''
	if keyword_set(zvariable) then print, 'This CDF has no zvar.' else print, 'This CDF has no var.'
endelse
;;; close the file
if keyword_set(ncdf) then ncdf_close, cdfid else cdf_close, cdfid
end
