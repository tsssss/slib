function strcmp_or, str, str_arr, n, fold_case = fold_case
;;; make strcmp with an array of strings (str_arr), return true if matches any of them
if n_elements(str) eq 1 then begin
	if keyword_set(n) then arr = strcmp(str, str_arr, n, fold_case = fold_case) else arr = strcmp(str, str_arr, fold_case = fold_case)
	no_use = where(arr ne 0, j)
	if j gt 0 then return, 1 else return, 0
endif else begin
	ifmatch = intarr(n_elements(str))
	for i = 0, n_elements(str)-1 do begin
		if keyword_set(n) then arr = strcmp(str[i], str_arr, n, fold_case = fold_case) else arr = strcmp(str[i], str_arr, fold_case = fold_case)
		no_use = where(arr ne 0, j)
		if j gt 0 then ifmatch[i] = 1 else ifmatch[i] = 0
	endfor
	return, ifmatch
endelse
end
