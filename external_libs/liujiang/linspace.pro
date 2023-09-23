function linspace, start_value, end_value, npts, increment = increment, type = type, strict = strict
;; use as matlab's linspace
;; type: force the output to be of this type. float, etc. default is double, cannot do integers such as int and long.
;; strict: only useful when using increment. Set this so that if increment is smaller than the difference between start and end values there will be strictly only one point.
;; npts has high priority than increment

if ~keyword_set(npts) and keyword_set(increment) then begin
	if keyword_set(strict) then npts = floor((end_value-start_value)/increment)+1 $
	else npts = round((end_value-start_value)/increment)+1
	if npts lt 0 then message, 'Increment or start/end value set wrong!'
	end_value_new = start_value+(npts-1)*increment
endif else end_value_new = end_value

indarr = dindgen(npts)


if npts gt 1 then begin
	out_arr = indarr/(npts-1)*(end_value_new-start_value)+start_value
endif else begin
	out_arr = mean([start_value, end_value_new])
endelse

if keyword_set(type) then begin
	case type of
	'float': out_arr = float(out_arr)
	'int': out_arr = fix(out_arr)
	'long': out_arr = long(out_arr)
	endcase
endif

return, out_arr

end
