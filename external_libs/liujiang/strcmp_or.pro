function strcmp_or, str, str_arr, n, fold_case = fold_case
;;; make strcmp with an array of strings (str_arr), return true if matches any of them
if keyword_set(n) then arr = strcmp(str, str_arr, n, fold_case = fold_case) else arr = strcmp(str, str_arr, fold_case = fold_case)
no_use = where(arr ne 0, j)
if j gt 0 then return, 1 else return, 0
end
