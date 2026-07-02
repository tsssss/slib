
compile_opt idl2

test = 0

test_events = list()
test_events.add, dictionary($
    'time_range', time_double(['2000-222','2000-227'],tformat='YYYY-DOY'), $
    'plot_base', 'geopack_w_test_qin_2007_fig1.pdf' )
test_events.add, dictionary($
    'time_range', time_double(['2000-308','2000-313'],tformat='YYYY-DOY'), $
    'plot_base', 'geopack_w_test_qin_2007_fig2.pdf' )

plot_dir = sparentdir(srootdir())
foreach test_event, test_events do begin
    time_range = test_event['time_range']
    plot_base = test_event['plot_base']
    plot_file = join_path([plot_dir,plot_base])

    param_vars = list()
    param_vars.add, geopack_read_w(time_range)
    param_vars.add, geopack_read_denton_w(time_range)

    nparam_var = n_elements(param_vars)
    nparam = 6
    times = var_get_time(param_vars[0])
    ntime = n_elements(times)
    plot_vars = list()
    for ii=0,nparam-1 do begin
        param_data = fltarr(ntime,nparam_var)
        foreach param_var, param_vars, jj do begin
;            dtime = (jj eq 0)? 0: -1800
            dtime = 0
            param_data[*,jj] = (var_get_data(param_var, at=times+dtime))[*,ii]
        endforeach
        param_str = 'w'+string(ii+1,format='(I0)')
        settings = dictionary($
            'display_type', 'stack', $
            'labels', ['Test','Qin-hourly'], $
            'colors', sgcolor(['blue','red']), $
            'yrange', [0.01,100], $
            'ylog', 1, $
            'ytitle', strupcase(param_str) )
        plot_vars.add, var_store(param_str, param_data, times, settings=settings)
    endfor
    plot_vars = plot_vars.toarray()

    if keyword_set(test) then plot_file = 0
    fig_size = [6,6]
    sgopen, plot_file, size=fig_size
    tplot, plot_vars, trange=time_range
    if keyword_set(test) then stop
    sgclose
endforeach




end