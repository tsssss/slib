function strmatch_or, str, str_arr, fold_case = fold_case
;;; make strmatch with an array of strings (str_arr), return true if matches any of them

for i = 0, n_elements(str_arr)-1 do begin
	match_this = strmatch(str, str_arr[i], fold_case = fold_case)
	if total(match_this) gt 0 then return, 1
endfor

return, 0
end
