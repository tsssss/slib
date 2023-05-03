;+
; Return the file_times for a given time and site.
; 
; input_time_range.
; site=.
; find_closest=. A boolean, set to return the closes file_times.
; return_directly=. A boolean for internal usages.
;-

function themis_asf_read_file_times_per_night_directly, search_time_range, site=site

    flag_var = themis_asf_read_flag_avail(search_time_range, site=site)
    get_data, flag_var, times, flags
    index = where(flags eq 1, nfile_time)
    if nfile_time eq 0 then return, []
    return, times[index]

end


function themis_asf_read_file_times_per_night, input_time_range, site=site, $
    msg=msg, find_closest=find_closest

    msg = ''
    retval = !null
    
    secofday = constant('secofday')
    secofhour = constant('secofhour')
    the_time = time_double(input_time_range[0])
    date = the_time-(the_time mod secofday)

    site_info = themis_asi_read_site_info(site)
    midn_ut = date+site_info['midn_ut']
    search_time_range = midn_ut+[-1,1]*10*secofhour
    ; Check the current and previous 24 hour.
    file_times = themis_asf_read_file_times_per_night_directly(search_time_range, site=site)
    ; Check the next 24 hour b/c we floored the_time.
    next_file_times = themis_asf_read_file_times_per_night_directly(search_time_range+secofday, site=site)
    all_file_times = [file_times, next_file_times]
    if n_elements(all_file_times) eq 0 then begin
        msg = 'No data within a day ...'
        return, retval
    endif

    ; The given time is within the file_times of the night.
    if n_elements(file_times) ne 0 then begin
        index = lazy_where(the_time, '[]', minmax(file_times), count=count)
        if count ne 0 then begin
            return, file_times
        endif
    endif
        
    
    ; The given time is within the file_times of the next night.
    if n_elements(next_file_times) ne 0 then begin
        index = lazy_where(the_time, '[]', minmax(next_file_times), count=count)
        if count ne 0 then begin
            return, next_file_times
        endif
    endif

    
    msg = 'Given time is outside the night ...'
    if ~keyword_set(find_closest) then return, retval
    
    if n_elements(file_times) eq 0 then begin
        msg += '!CNo data the night before ...'
        return, next_file_times
    endif
    
    if n_elements(next_file_times) eq 0 then begin
        msg += '!CNo data the night after ...'
        return, file_times
    endif

    if the_time-max(file_times) gt min(next_file_times)-the_time then begin
        retval = next_file_times
    endif else begin
        retval = file_times
    endelse
    return, retval


end


test_times = make_bins(time_double(['2015-09-28','2015-09-29']), 3600)
;    '2015-09-28/22:00',$    ; first hour of the night.
;    '2015-09-28/20:00',$    ; before first hour of the night.
;    '2015-09-29/08:00',$    ; last hour of the night.
;    '2015-09-29/04:00',$    ; somewhere middle of the night.
;    '2015-09-28/22:00']     ; first hour of the night.
site = 'gbay'
foreach time, test_times do begin
    file_times = themis_asf_read_file_times_per_night(time, site=site, msg=msg)

    print, ''
    print, time_string(time)
    print, ''
    if n_elements(file_times) eq 0 then begin
        print, msg
    endif else begin
        foreach file_time, file_times do print, time_string(file_time)
    endelse
endforeach
end