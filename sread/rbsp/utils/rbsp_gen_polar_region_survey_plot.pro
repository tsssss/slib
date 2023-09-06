;+
; Wrapper of the different versions.
;-

function rbsp_gen_polar_region_survey_plot, input_time_range, probe=probe, $
    plot_dir=plot_dir, position=full_pos, errmsg=errmsg, test=test, xpansize=xpansize, $
    version=version, local_root=local_root

    if n_elements(version) eq 0 then version = 'v05'

    routine = 'rbsp_gen_polar_region_survey_plot_'+version
    return, call_function(routine, input_time_range, probe=probe, $
    plot_dir=plot_dir, position=full_pos, errmsg=errmsg, test=test, xpansize=xpansize, $
    local_root=local_root)

end

test = 0


input_list = list()
input_list.add, ['2016-10-14','2016-10-15']
;input_list.add, ['2012-12-01','2013-07-01']
;input_list.add, ['2014-10-01','2015-04-01']
input_list.add, ['2016-08-01','2019-02-01']
input_list.add, ['2012-10-01','2019-09-01']
probes = ['a','b']

foreach input_time_range, input_list do begin
    time_range = time_double(input_time_range)
    secofday = constant('secofday')
    days = make_bins(time_range+[0,-1]*secofday, secofday)
    foreach day, days do begin
        print, 'Processing '+time_string(day)+' ...'
        the_time_range = day+[0,secofday]
        year = time_string(day,tformat='YYYY')
        monthday = time_string(day,tformat='MMDD')

        foreach probe, probes do begin
            print, 'Processing '+strupcase(probe)+' ...'
            files = rbsp_gen_polar_region_survey_plot(the_time_range, probe=probe, xpansize=6, test=test)
        endforeach
    endforeach
endforeach

end