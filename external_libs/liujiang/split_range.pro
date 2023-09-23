function split_range, arr, gap_value, decrease = decrease, increase = increase, i_duan = i_duan, no_sort_array = no_sort_array
;; split the ranges of arr. useful for times and all other things
;; To spit two-element ranges, use union_ranges.pro
;; gap_value: the value of the gap to tell things apart. If positive, gap need to be larger than or equal to this. If negative, gap_value need to be smaller than or equal to this.
;;	if gap_value is 0, need to set decrease or increase, which will be counted as gap. Default is decrease.
;; no_sort_array: do not sort the array, directly cut it. Default is sorting it.
;; NaN value will be treated as no gap.

if n_elements(arr) eq 1 then return, [arr, arr]
if n_elements(arr) eq 2 then begin
	arr_sort = arr(sort(arr))
	if arr_sort[1]-arr_sort[0] ge gap_value then $
		return, [[arr_sort[0], arr_sort[0]], [arr_sort[1], arr_sort[1]]] $
	else return, arr_sort
endif

if keyword_set(no_sort_array) then arr_sort = arr else arr_sort = arr(sort(arr))
arr_dif = arr_sort[1:*]-arr_sort[0:-2]

case 1 of
gap_value gt 0 : i_duan = where(arr_dif ge gap_value, n_duan)
gap_value lt 0 : i_duan = where(arr_dif le gap_value, n_duan)
else: begin ;;; gap value is 0 
	if keyword_set(increase) then i_duan = where(arr_dif ge gap_value, n_duan) else i_duan = where(arr_dif le gap_value, n_duan)
	end
endcase

if n_duan lt 1 then begin
	return, [arr_sort[0], arr_sort[-1]]
endif else begin
	ranges = make_array(2, n_duan+1, type = size(arr, /type))
	i_duan = [-1, i_duan, -1]

	for i = 1, n_elements(i_duan)-1 do begin
		ranges[0,i-1] = arr_sort[i_duan[i-1]+1]
		ranges[1,i-1] = arr_sort[i_duan[i]]
	endfor
	return, ranges
endelse
end
