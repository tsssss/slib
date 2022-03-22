;+
; Load supermag indices.
;-


time_range = time_double(['2014-08-28/09:50','2014-08-28/11:10'])
;time_range = time_double(['2016-10-13/12:00','2016-10-13/13:30'])
;time_range = time_double(['2013-06-07/02:30','2013-06-07/07:00'])
;time_range = time_double(['2013-06-07/04:25','2013-06-07/05:45'])
dmlt = 12
;
;time_range = time_double(['2013-08-27','2013-08-29'])   ; long eg.
;time_range = time_double(['2014-08-28','2014-08-29'])   ; long eg.
;time_range = time_double(['2008-03-20','2008-03-21'])   ; reverse eg.
time_range = time_double(['2015-11-04','2015-11-05'])   ; reverse eg.
;time_range = time_double(['2016-02-17','2016-02-18'])   ; reverse eg.
;time_range = time_double(['2017-09-08','2017-09-09'])   ; reverse eg.
;time_range = time_double(['2016-08-09','2016-08-10'])   ; Merkin+2019.
;dmlt = 7

supermag_api

userid = 'test'

duration = total(time_range*[-1,1])
time_str = time_string(time_range[0],tformat='YYYYMMDDhhmmss')
yr = strmid(time_str,0,4)
mo = strmid(time_str,4,2)
dy = strmid(time_str,6,2)
hr = strmid(time_str,8,2)
mi = strmid(time_str,10,2)
sc = strmid(time_str,12,2)

omni_read_index, time_range

sme2d_var = 'supermag_mse2d'
s = supermaggetindicesarray(userid, $
    yr, mo, dy, hr, mi, sc, $
    duration, times, regionalsme=sme2d, $
    regionalmlat=mlat, regionalmlt=mlt, stid=stid )
mlts = findgen(24)
; Make midnight to be the center.
mlts -= dmlt-0.5
sme2d = shift(sme2d,0,dmlt)

store_data, sme2d_var, $
    times, sme2d, mlts, $
    limits={ytitle:'MLT (h)', spec:1, no_interp:1, $
    yrange:minmax(mlts), ystyle:1, $
    xticklen:-0.02, yticklen:-0.02, $
    ztitle:'SME (nT)', color_table:49 }


sme_var = 'supermag_mse'
s = supermaggetindicesarray(userid, $
    yr, mo, dy, hr, mi, sc, $
    duration, times, sme=sme )

store_data, sme_var, times, sme, $
    limits={ytitle:'(nT)', $
    xticklen:-0.02, yticklen:-0.02 }

ae = get_var_data('ae', at=times)
store_data, sme_var, times, [[sme],[ae]], $
    limits={ytitle:'(nT)', $
    labels:['SME','AE'], colors:sgcolor(['red','black']), $
    xticklen:-0.02, yticklen:-0.02, labflag:-1 }


;sgopen, 0, xsize=5, ysize=2.5
;tpos = sgcalcpos(1, margins=[10,4,9,2])
;tplot, sme2d_var, position=tpos
;plot, time_range, minmax(mlts), xstyle=5, $
;    ystyle=5, nodata=1, noerase=1, position=tpos
;xs = time_double(['2014-08-28/10:08','2014-08-28/10:50'])
;ys = 0+(xs-xs[0])*(2.1/60/15)
;oplot, xs, ys, linestyle=2, color=sgcolor('black')
;ys = 0+(xs-xs[0])*(-3.0/60/15)
;oplot, xs, ys, linestyle=2, color=sgcolor('black')
;stop
;
;sgopen, 0, xsize=5, ysize=2.5
;tpos = sgcalcpos(1, margins=[10,4,9,2])
;tplot, sme2d_var, position=tpos
;plot, time_range, minmax(mlts), xstyle=5, $
;    ystyle=5, nodata=1, noerase=1, position=tpos
;xs = time_double(['2016-10-13/12:20','2016-10-13/12:40'])
;ys = 1+(xs-xs[0])*(4.6/60/15)
;oplot, xs, ys, linestyle=2, color=sgcolor('black')


;sgopen, 0, xsize=5, ysize=2.5
;tpos = sgcalcpos(1, margins=[10,4,9,2])
;zlim, sme2d_var, 400, 1400
;ylim, sme2d_var, -8,8
;tplot, sme2d_var, position=tpos
;get_data, sme2d_var, limit=lim
;plot, time_range, lim.yrange, xstyle=5, $
;    ystyle=5, nodata=1, noerase=1, position=tpos
;xs = time_double(['2013-06-07/04:40','2013-06-07/05:10'])
;ys = 0+(xs-xs[0])*(-2.0/60/15)
;oplot, xs, ys, linestyle=2, color=sgcolor('black')
;xs = time_double(['2013-06-07/04:40','2013-06-07/05:10'])
;ys = 0+(xs-xs[0])*(2.0/60/15)
;oplot, xs, ys, linestyle=2, color=sgcolor('black')

end
