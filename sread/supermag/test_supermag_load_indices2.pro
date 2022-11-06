;+
; Load supermag indices.
;-

compile_opt idl2

;time_range = time_double(['2014-08-28/09:50','2014-08-28/11:10'])
;time_range = time_double(['2016-10-13/12:00','2016-10-13/13:30'])
;time_range = time_double(['2013-06-07/02:30','2013-06-07/07:00'])
;time_range = time_double(['2013-06-07/04:25','2013-06-07/05:45'])
time_range = time_double(['2013-05-31/14:00','2013-06-01/14:00'])
dmlt = 12
;
;time_range = time_double(['2013-08-27','2013-08-29'])   ; long eg.
;time_range = time_double(['2014-08-28','2014-08-29'])   ; long eg.
;time_range = time_double(['2008-03-20','2008-03-21'])   ; reverse eg.
;time_range = time_double(['2015-11-04','2015-11-05'])   ; reverse eg.
;time_range = time_double(['2016-02-17','2016-02-18'])   ; reverse eg.
;time_range = time_double(['2017-09-08','2017-09-09'])   ; reverse eg.
;time_range = time_double(['2016-08-09','2016-08-10'])   ; Merkin+2019.
;dmlt = 7

supermag_api

omni_read_index, time_range

; sme = smu-sml
sme_var = 'supermag_mse'
s = supermaggetindicesarray(time_range, $
    times, sme=sme, sml=sml, smu=smu, sunsme=sunmse, darksme=darksme )

store_data, sme_var, times, sme, $
    limits={ytitle:'(nT)', $
    xticklen:-0.02, yticklen:-0.02 }

ae = get_var_data('ae', at=times)
store_data, sme_var, times, [[sme],[ae]], $
    limits={ytitle:'(nT)', $
    labels:['SME','AE'], colors:sgcolor(['red','black']), $
    xticklen:-0.02, yticklen:-0.02, labflag:-1 }

sme2d_var = 'supermag_mse2d'
s = supermaggetindicesarray(time_range, $
    times, regionalsme=sme2d, $
    regionalmlat=mlat2d, regionalmlt=mlt2d, stid=stid )

;rad = constant('rad')
;deg = constant('deg')
;tmp = mlt2d*15*rad
;cosx = total(cos(tmp),2)*0.5
;sinx = total(sin(tmp),2)*0.5
;mlt0 = atan(sinx,cosx)*deg/15
mlt0 = total(mlt2d,2)*0.5
mlt1 = [[mlt0[*,12:23]-24],[mlt0],[mlt0[*,0:11]+24]]
sme1 = [[sme2d[*,12:23]],[sme2d],[sme2d[*,0:11]]]

mlts = findgen(24)
sme2 = sme2d
foreach time, times, time_id do begin
    tmlt = mlt1[time_id,*]
    index = sort(tmlt)
    sme2[time_id,*] = interpol(sme1[time_id,index],tmlt[index], mlts)
endforeach


; Make midnight to be the center.
mlts -= dmlt-0.5
sme2 = shift(sme2,0,dmlt)

store_data, sme2d_var, $
    times, sme2, mlts, $
    limits={ytitle:'MLT (h)', spec:1, no_interp:1, $
    yrange:minmax(mlts), ystyle:1, $
    xticklen:-0.02, yticklen:-0.02, $
    ztitle:'SME (nT)', color_table:49 }
tplot, [sme_var,sme2d_var], trange=time_range

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
