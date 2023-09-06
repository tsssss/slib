;+
; Interpolate a given data to given times.
;
; var. A string of a variable name.
; times. An array of times to be interpolated to.
; to=. A string specified the varialbe, whos times will be used.
; data_gap_window=. A number n sec, time diff larger than this will be NaN'ed.
;-

pro interp_time, var, times, to=new_var, data_gap_window=data_gap_window, _extra=ex

    get_data, var, old_times, old_data, val
    if keyword_set(new_var) then get_data, new_var, times
    dat = sinterpol(old_data, old_times, times, /nan, _extra=ex)
    ndim = size(old_data,/n_dimension)

    ; Treat data gap on beginning and end.
    fillval = !values.d_nan
    bad_index = []
    index = where_pro(times,')(',minmax(old_times), count=count)
    if count ne 0 then bad_index = [bad_index,index]
    
    ; Treat NaN.
    ndim = size(old_data,/n_dimensions)
    if ndim eq 1 then begin
        index = where(finite(old_data,/nan), count)
    endif else begin
        index = where(finite(snorm(old_data),/nan), count)
    endelse
    if count ne 0 then begin
        nan_time_ranges = old_times[time_to_range(index,time_step=1)]
        nnan_time_range = n_elements(nan_time_ranges)*0.5
        for ii=0,nnan_time_range-1 do begin
            index = where_pro(times, '[]', nan_time_ranges[ii,*], count=count)
            if count eq 0 then continue
            bad_index = [bad_index,index]
        endfor
    endif
    
    ; Treat data gap in between.
    new_time_step = total(times[0:1]*[-1,1])
    old_time_step = total(old_times[0:1]*[-1,1])
    the_time_step = max([new_time_step,old_time_step])
    if n_elements(data_gap_window) eq 0 then data_gap_window = the_time_step*4
    dtimes = old_times[1:-1]-old_times[0:-2]
    index = where(dtimes ge data_gap_window, count)
    if count ne 0 then begin
        gap_time_ranges = [[old_times[index]],[old_times[index+1]]]
        ngap_time_range = n_elements(gap_time_ranges)*0.5
        for ii=0, ngap_time_range-1 do begin
            index = where_pro(times, '[]', gap_time_ranges[ii,*], count=count)
            if count eq 0 then continue
            bad_index = [bad_index,index]
        endfor
    endif

    
    if n_elements(bad_index) ne 0 then dat[bad_index,*] = fillval


    ndim = size(val,/n_dimension)
    if ndim eq 2 then begin
        val = sinterpol(val, old_times, times, /nan)
        if count ne 0 then val[bad_index,*] = fillval
    endif
    if ndim eq 0 then begin
        store_data, var, times, dat
    endif else begin
        store_data, var, times, dat, val
    endelse

end

ntime = 1200
times = findgen(ntime)
data = findgen(ntime)
data[50:650] = !values.f_nan
var = 'test'
store_data, var, times, data
new_times = times[0:*:10]
interp_time, var, new_times
end
