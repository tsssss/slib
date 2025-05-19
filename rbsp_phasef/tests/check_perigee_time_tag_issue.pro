;+
; Check spikes around the day change.
;-

;---Settings.
    time_range = time_double(['2016-10-20','2016-10-21'])
    time_range = time_double(['2016-10-21','2016-10-22'])
    time_range = time_double(['2016-10-22','2016-10-23'])
    time_range = time_double(['2016-11-19','2016-11-21'])
    time_range = time_double(['2016-11-24','2016-11-25'])
    time_range = time_double(['2016-12-02','2016-12-03'])
    time_range = time_double(['2017-04-13','2017-04-14'])
    secofday = constant('secofday')
    time_range = time_double('2013-01-02')+[0,1]*secofday
    time_range = time_double('2013-05-19')+[0,2]*secofday
    time_range = time_double('2014-01-02')+[0,2]*secofday
    time_range = time_double('2014-05-07')+[0,2]*secofday
    time_range = time_double('2014-05-11')+[0,2]*secofday
    time_range = time_double('2014-05-22')+[0,1]*secofday
    time_range = time_double('2015-07-01')+[-1,1]*secofday
    probe = 'a'
    
    
    time_range = time_double('2013-01-06')+[0,2]*secofday
    time_range = time_double('2013-02-20')+[0,1]*secofday
    probe = 'b'
    
    
    
    time_range = time_double(['2014-01-05/12:42:34.450798','2014-01-05/13:27:05.419235'])+[-1,1]*300
    time_range = time_double(['2014-04-23/18:17:28.683166','2014-04-23/18:57:11.651718'])+[-1,1]*300
    time_range = time_double(['2014-04-24/15:26:31.677452','2014-04-24/16:06:46.645874'])+[-1,1]*300
    time_range = time_double(['2014-05-22/06:31:51.498458','2014-05-22/07:10:14.466918'])+[-1,1]*300
    time_range = time_double(['2014-06-16/00:00:07.590774','2014-06-16/04:52:24.342498'])+[-1,1]*300
    time_range = time_double(['2014-06-20/00:00:02.727035','2014-06-20/08:09:23.317199'])+[-1,1]*300
    time_range = time_double(['2014-07-08/07:28:46.208732','2014-07-08/08:05:33.177345'])+[-1,1]*300
    time_range = time_double(['2014-07-09/03:09:01.203872','2014-07-09/03:46:20.172317'])+[-1,1]*300
    time_range = time_double(['2014-07-09/22:55:24.198844','2014-07-09/23:32:43.167533'])+[-1,1]*300
    time_range = time_double(['2014-07-11/14:26:34.189186','2014-07-11/15:03:05.157585'])+[-1,1]*300
    time_range = time_double(['2016-08-09/23:59:51.192207','2016-08-10/00:36:22.160964'])+[-1,1]*300
    time_range = time_double(['2016-10-20/01:57:14.236579','2016-10-20/02:31:05.205253'])+[-1,1]*300
    time_range = time_double(['2016-10-20/19:27:37.236976','2016-10-20/20:00:56.205871'])+[-1,1]*300
    time_range = time_double(['2016-10-21/12:57:28.237754','2016-10-21/13:30:15.206344'])+[-1,1]*300
    time_range = time_double(['2016-10-22/06:26:47.238235','2016-10-22/06:58:46.207061'])+[-1,1]*300
    time_range = time_double(['2016-10-22/23:55:50.238731','2016-10-23/00:00:05.234603'])+[-1,1]*300
    time_range = time_double(['2016-10-29/13:22:21.244438','2016-10-29/13:55:24.213134'])+[-1,1]*300
    time_range = time_double(['2016-11-02/05:12:40.247650','2016-11-02/05:47:03.216316'])+[-1,1]*300
    time_range = time_double(['2016-11-02/22:52:07.248321','2016-11-02/23:27:34.217048'])+[-1,1]*300
    time_range = time_double(['2016-11-11/07:29:00.256393','2016-11-11/08:04:11.225013'])+[-1,1]*300
    time_range = time_double(['2016-11-14/22:25:12.260253','2016-11-14/23:13:43.228935'])+[-1,1]*300
    time_range = time_double(['2016-11-20/00:00:04.239898','2016-11-20/00:09:07.235038'])+[-1,1]*300
;    time_range = time_double(['2016-11-21/06:48:35.267776','2016-11-21/07:49:22.236633'])+[-1,1]*300
;    time_range = time_double(['2016-11-24/02:32:49.271362','2016-11-24/03:41:36.240249'])+[-1,1]*300
;    time_range = time_double(['2019-06-06/00:00:29.803977','2019-06-06/00:03:40.801582'])+[-1,1]*300
    probe = 'a'
    
    
;    time_range = time_double(['2014-04-22/19:58:55.036964','2014-04-22/22:49:02.060295'])+[-1,1]*300
;    time_range = time_double(['2014-06-15/00:00:21.690292','2014-06-18/00:00:23.089233'])+[-1,1]*300
;    time_range = time_double(['2016-04-07/23:58:59.704216','2016-04-08/02:10:10.728927'])+[-1,1]*300
;    probe = 'b'
    


;---Derived quantities.
    prefix = 'rbsp'+probe+'_'
    common_time_step = 10.
    common_times = make_bins(time_range, common_time_step)
    xyz = constant('xyz')
    uvw = constant('uvw')
    the_time_range = mean(time_range)+[-1,1]*60


;---Load data.
    del_data, '*'
    evar_good = prefix+'e_mgse_good'
    rbsp_efw_read_e_mgse, time_range, probe=probe
    evar_new = prefix+'e_mgse'
    tplot_rename, evar_new, evar_good
    foreach var, tnames('*') do if var ne evar_good then del_data, var


    rbsp_efw_phasef_read_wobble_free_var, time_range, probe=probe
    timespan, time_range[0], total(time_range*[-1,1]), /seconds    
    rbsp_load_efw_waveform, probe=probe, datatype='esvy', type='raw', coord='uvw', /noclean, trange=time_range
    evar_old = prefix+'efw_esvy'
    get_data, evar_old, times, data
    data[*,2] = !values.f_nan
    store_data, evar_old, times, data 
    
    get_data, evar_new, times, data
    data[*,0] = !values.f_nan
    store_data, evar_new, times, data
    options, evar_old, 'colors', constant('rgb')
    
    tplot_options, 'labflag', -1
    
    sgopen, 0, xsize=8, ysize=5
    tplot, [evar_old,evar_new,evar_good], trange=time_range


end
