;+
; A wrapper for different versions.
;-

function dmsp_gen_polar_region_survey_plot, input_time_range, probe=probe, $
    plot_dir=plot_dir, position=full_pos, errmsg=errmsg, test=test, $
    local_root=local_root

    version = 'v02'
    routine = 'dmsp_gen_polar_region_survey_plot_'+version
    return, call_function(routine, input_time_range, probe=probe, $
        local_root=local_root, errmsg=errmsg, test=test, $
        plot_dir=plot_dir, position=full_pos )

end


probes = 'f'+['16','17','18','19']
local_root = join_path([default_local_root(),'dmsp','survey_plot'])


;the_time_range = time_double(['2017-03-21/04:30','2017-03-21/08:30'])
;probes = ['f17','f18']
;foreach probe, probes do files = dmsp_gen_polar_region_survey_plot(the_time_range, probe=probe, test=0)
;stop


;storm_list = ts_load_storm_list(['2012-10-01','2019-10-01'])
;nstorm = n_elements(storm_list[*,0])
;
;secofday = constant('secofday')
;days = []
;for storm_id=0,nstorm-1 do begin
;    the_tr = storm_list[storm_id,*]
;    the_tr = the_tr-(the_tr mod secofday)+[0,secofday]
;    the_days = make_bins(the_tr,secofday)
;    days = [days,the_days]
;    print, time_string(minmax(the_days))
;endfor
;
;stop


; Time range.
input_time_range = ['2017-12-26','2018-12-31']
input_time_range = ['2013-06-06','2013-06-10']
;input_time_range = ['2015-03-04','2015-05-31']
; '2015-03-03 has problem.
secofday = constant('secofday')
time_range = time_double(input_time_range)
days = make_bins(time_range, secofday)


foreach day, days do begin
    print, 'Processing '+time_string(day)+' ...'
    the_time_range = day+[0,secofday]
    year = time_string(day,tformat='YYYY')
    monthday = time_string(day,tformat='MMDD')
    plot_dir = join_path([local_root,year,monthday])

    foreach probe, probes do begin
        print, 'Processing '+strupcase(probe)+' ...'
        files = dmsp_gen_polar_region_survey_plot(the_time_range, probe=probe)
    endforeach
endforeach

stop
end