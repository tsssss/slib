;+
; Plot sc position on xy plane.
;-

function plot_sc_xy_plane, input_time_range, $
    mission_probes=mission_probes, coord=coord, $
    xrange=xrange, $
    yrange=yrange, $
    position=tpos, $
    errmsg=errmsg, $
    colors=colors, $
    sun_to_right=sun_to_right, $
    _extra=ex

    errmsg = errmsg
    retval = ''
    

    nmission_probe = n_elements(mission_probes)
    if nmission_probe eq 0 then begin
        errmsg = 'No input mission_probes ...'
        return, retval
    endif

    time_range = time_double(input_time_range)
    if n_elements(coord) eq 0 then coord = 'sm'
    if n_elements(colors) ne nmission_probe then colors = get_color(nmission_probe)
    
    var_info = dictionary()
    foreach mission_probe, mission_probes, probe_id do begin
        probe_info = resolve_probe(mission_probe)
        routine_name = probe_info['routine_name']+'_read_orbit'
        probe = probe_info['probe']
        r_var = call_function(routine_name, time_range, probe=probe, coord=coord, errmsg=errmsg)
        if errmsg ne '' then stop
        probe_info['r_var'] = r_var
        probe_info['color'] = colors[probe_id]
        var_info[mission_probe] = probe_info
    endforeach
    
    if n_elements(xstep) eq 0 then xstep = 5
    if n_elements(xrange) eq 0 then begin
        xrange = [-1,1]
        foreach probe_info, var_info do begin
            r_var = probe_info['r_var']
            r_coord = get_var_data(r_var)
            xrange = [xrange,minmax(r_coord[*,0])]
        endforeach
        xrange = minmax(make_bins(xrange,xstep))
    endif

    if n_elements(xtickv) eq 0 then xtickv = make_bins(xrange,xstep)
    xticks = n_elements(xtickv)-1
    xminor = xstep
    xtitle = strupcase(coord)+' X (Re)'

    if n_elements(ystep) eq 0 then ystep = 5
    if n_elements(yrange) eq 0 then begin
        yrange = [-1,1]
        foreach probe_info, var_info do begin
            r_var = probe_info['r_var']
            r_coord = get_var_data(r_var)
            yrange = [yrange,minmax(r_coord[*,1])]
        endforeach
        yrange = minmax(make_bins(yrange,ystep))
    endif

    if n_elements(ytickv) eq 0 then ytickv = make_bins(yrange,ystep)
    yticks = n_elements(ytickv)-1
    yminor = ystep
    ytitle = strupcase(coord)+' Y (Re)'
    

    if keyword_set(sun_to_right) then begin
        the_xrange = minmax(xrange)
        the_yrange = minmax(yrange)
    endif else begin
        the_xrange = reverse(minmax(xrange))
        the_yrange = reverse(minmax(yrange))
    endelse

    if n_elements(tpos) ne 4 then tpos = sgcalcpos(1)
    plot, xrange, yrange, $
        xstyle=5, ystyle=5, xrange=the_xrange, yrange=the_yrange, $
        position=tpos, nodata=1, noerase=1, iso=1

    tmp = get_charsize()
    xchsz = tmp[0]
    ychsz = tmp[1]
    label_tx = tpos[0]+xchsz*0.5
    label_ty = tpos[3]-ychsz*1
    label_size = 0.8
    probe_id = 0
    the_times = make_bins(time_range, 3600, inner=1)
    foreach probe_info, var_info do begin
        r_var = probe_info['r_var']
        r_coord = get_var_data(r_var, times=times)
        xx = r_coord[*,0]
        yy = r_coord[*,1]
        color = probe_info['color']
        oplot, xx, yy, color=color
        
        ; Add short name.
        msg = strupcase(probe_info['short_name'])
        xyouts, label_tx+probe_id*5*xchsz, label_ty, msg, normal=1, color=color
        probe_id += 1
        
        ; Add time ticks.
        if n_elements(the_times) gt 0 then begin
            the_xx = interpol(xx,times, the_times)
            the_yy = interpol(yy,times, the_times)
            plots, the_xx, the_yy, psym=1, color=color, symsize=label_size
            foreach time, the_times, time_id do begin
                msg = time_string(time,tformat='hh')
                tmp = convert_coord(the_xx[time_id], the_yy[time_id], data=1, to_normal=1)
                tx = tmp[0]
                ty = tmp[1]+ychsz*0.2
                xyouts, tx, ty, alignment=0.5, msg, normal=1, color=color, charsize=label_size
            endforeach
        endif
    endforeach
    

    
    tmp = get_ticklen(tpos)
    xticklen = tmp[0]
    yticklen = tmp[1]

    plot, xrange, yrange, $
        xstyle=1, xrange=the_xrange, xtickv=xtickv, xticks=xticks, xminor=xminor, xtitle=xtitle, $
        ystyle=1, yrange=the_yrange, ytickv=ytickv, yticks=yticks, yminor=yminor, ytitle=ytitle, $
        position=tpos, nodata=1, noerase=1, $
        xticklen=xticklen, yticklen=yticklen, iso=1

    ; add earth and circles and lines.
    tmp = smkarthm(0,2*!dpi,40,'n')
    xxs = cos(tmp)
    yys = sin(tmp)    
    
    rrs = make_bins([1,max(abs([xrange,yrange]))], xstep, inner=1)
    foreach rr, rrs do oplot, xxs*rr, yys*rr, linestyle=1;, color=sgcolor('silver')
    plots, [0,0], yrange, linestyle=1
    plots, xrange, [0,0], linestyle=1
    
    ; Earth.
    polyfill, xxs>0, yys, color=sgcolor('white')
    polyfill, xxs<0, yys, color=sgcolor('silver')
    oplot, xxs, yys
    
    
    return, var_info
    
end


;margins = [8,4,2,2]
;tpos = panel_pos(0, pansize=[5,3], margins=margins, fig_size=fig_size)
;sgopen, 0, size=fig_size, magn=2
;time_range = ['2015-04-15/13:00','2015-04-15/20:00']
;mission_probes = ['tha','rbspa','rbspb','g13','g15','mms1']
;;mission_probes = ['g15']
;res = plot_sc_xy_plane(time_range, mission_probes=mission_probes, position=tpos)

sgopen, 1, size=[4,4], magn=1
margins = [8,2,1,1]
tpos = sgcalcpos(1, margins=margins)
time_range = ['2017-03-27/09:30','2017-03-27/10:00']
mission_probes = ['thd','the','tha','rbspa','rbspb','g15','g13','mms1','arase','c1']

time_range = ['2015-03-17/00:00','2015-03-20/00:00']
mission_probes = ['thd','the','tha','rbspa','rbspb','mms1','c1','g15']

time_range = ['2008-03-28/06:20','2008-03-28/06:40']
time_range = ['2008-03-28/06:00','2008-03-28/07:00']
mission_probes = ['thd','the','tha','g12','g13']


res = plot_sc_xy_plane(time_range, mission_probes=mission_probes)

end