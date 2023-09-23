function tv_exist, tv_name
;;; tell a tplot variable specified by tv_name whether exist
store_data, 'NO_USE_USED_BY_TV_EXIST', data = 0
tplot_names, tv_name, names = ex_this
del_data, 'NO_USE_USED_BY_TV_EXIST'
if strcmp(ex_this(0), '') then begin
	return, 0
endif else begin
	return, 1
endelse
end
