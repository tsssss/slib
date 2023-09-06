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


input_time_range = ['2015-01-01','2015-04-01']
probes = 'f'+['16','17','18','19']
local_root = join_path([default_local_root(),'dmsp','survey_plot'])

time_range = time_double(input_time_range)
secofday = constant('secofday')
days = make_bins(time_range, secofday)
foreach day, days do begin
    print, 'Processing '+time_string(day)+' ...'
    the_time_range = day+[0,secofday]
    year = time_string(day,tformat='YYYY')
    monthday = time_string(day,tformat='MMDD')
    plot_dir = join_path([local_root,year,monthday])

    foreach probe, probes do begin
        print, 'Processing '+strupcase(probe)+' ...'
        files = dmsp_gen_polar_region_survey_plot_v02(the_time_range, probe=probe)
    endforeach
endforeach

stop
end