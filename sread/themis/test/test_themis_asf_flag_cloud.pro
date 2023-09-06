;+
; Check how to determine if we have significant clouds.
;-

function test_themis_asf_flag_cloud, input_time_range, site=site

    time_range = time_double(input_time_range)
    asf_var = themis_read_asf(time_range, site=site, get_name=1)
    if check_if_update(asf_var, time_range) then begin
        asf_var = themis_read_asf(time_range, site=site)
        options, asf_var, 'requested_time_range', time_range
    endif

    get_data, asf_var, times, asf_images, limits=lim
    center_index = lim.center_index
    ncenter_index = n_elements(center_index)
    

    ntime = n_elements(times)
    flag_cloud = fltarr(ntime)
    
    value_step = 1e3
    value_bins = make_bins([0,65535], value_step, inner=1)
    nvalue_bin = n_elements(value_bins)
    
    ; min value does not work b/c there are ground objects that can give rise to the min value.
    ;min_values = fltarr(ntime)
    slopes = fltarr(ntime)
    min_values = fltarr(ntime)
    max_values = fltarr(ntime)
    
    foreach time, times, time_id do begin
        the_image = reform(asf_images[time_id,*,*])
        the_pixel = the_image[center_index]
        hist = fltarr(nvalue_bin)
        for ii=0,nvalue_bin-1 do begin
            index = where(the_pixel ge value_bins[ii], count)
            hist[ii] = count
        endfor

        hist_range = ncenter_index*[0.002,0.2]
        index = where_pro(hist, '[]', hist_range)
        min_values[time_id] = value_bins[min(index)]
        max_values[time_id] = value_bins[max(index)]
    endforeach
    
    store_data, site+'_min_value', times, min_values
    store_data, site+'_max_value', times, max_values



end


time_range = ['2015-01-01','2015-01-01/10:00']
site = 'atha'
foreach site, ['atha','talo'] do $
    tmp = test_themis_asf_flag_cloud(time_range, site=site)
end