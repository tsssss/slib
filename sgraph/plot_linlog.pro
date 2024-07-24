;+
; Plot scalar or vector in linear-log yscale.
;
; linear_yrange=. [v2,v3]. The yrange for linear part.
; log_yrange=. [v1,v4]. The yrange for positive and negative log parts.
;   For negative part, yrange is [v1,v2], positive log is [v3,v4].
; yranges=. [v1,v2,v3,v4]. This overwrites [linear,log]_yrange.
; negative_yrange=. [v1,v2]. This overwrites [linear,log]_yrange and yranges.
; positive_yrange=. [v3,v4]. 
; linear_tick_setting=. dictionary for tickv,ticks,tickn,etc.
; positive_tick_setting=.
; negative_tick_setting=.
; abs_ticklen=.  In ychsz.
; abs_xticklen=.
; abs_yticklen=.
;-

function plot_linlog, var, ypans=ypans, time_range=time_range, $
    positive_yrange=positive_yrange, negative_yrange=negative_yrange, $
    linear_yrange=linear_yrange, log_yrange=log_yrange, $
    yranges=yranges, $
    linear_tick_setting=linear_tick_setting, log_tick_setting=log_tick_setting, $
    negative_tick_setting=negative_tick_setting, positive_tick_setting=positive_tick_setting, $
    abs_ticklen=abs_ticklen, abs_xticklen=abs_xticklen, abs_yticklen=abs_yticklen, $
    panel_label_pos=panel_label_pos, panel_label_msg=panel_label_msg, $
    position=my_pos, noerase=noerase, novtitle=novtitle, xtickformat=xtickformat, $
    var_labels=var_labels, vlab_margin=vlab_margin, $
    errmsg=errmsg, _extra=ex


    retval = !null


;---Figure out yrange.
    yrange_vs = fltarr(4)

    if n_elements(linear_yrange) eq 2 then yrange_vs[[1,2]] = linear_yrange
    if n_elements(log_yrange) eq 2 then yrange_vs[[0,3]] = log_yrange

    nyrange = n_elements(yranges)
    if nyrange eq 4 then begin
        ; [v1,v2,v3,v4]
        yrange_vs = yranges
    endif else if nyrange eq 3 then begin
        index = where(yranges ge 0, count)
        if count eq 2 then begin
            ; [v2,v3,v4]
            yrange_vs = yranges[[0,0,1,2]]
        endif else if count eq 1 then begin
            ; [v1,v2,v3]
            yrange_vs = yranges[[0,1,2,2]]
        endif
    endif else if nyrange eq 2 then begin
        ; [v2,v3]
        yrange_vs = yranges[[0,0,1,1]]
    endif

    if n_elements(positive_yrange) eq 2 then yrange_vs[[2,3]] = positive_yrange
    if n_elements(positive_yrange) eq 1 then yrange_vs[[2,3]] = positive_yrange[0]
    if n_elements(negative_yrange) eq 2 then yrange_vs[[0,1]] = negative_yrange
    if n_elements(negative_yrange) eq 1 then yrange_vs[[0,1]] = negative_yrange[0]

    if n_elements(yrange_vs) ne 4 then begin
        errmsg = 'Invalid yrange ...'
        return, retval
    endif

    negative_yrange = yrange_vs[0:1]
    linear_yrange = yrange_vs[1:2]
    positive_yrange = yrange_vs[2:3]


;---Figure out positions.
    has_negative_panel = yrange_vs[0] ne yrange_vs[1]
    has_positive_panel = yrange_vs[2] ne yrange_vs[3]
    if n_elements(ypans) eq 0 then ypans = [0.5,1,0.5]
    if ~has_negative_panel then ypans[0] = 0
    if ~has_positive_panel then ypans[2] = 0

    if n_elements(my_pos) ne 4 then begin
        my_pos = sgcalcpos(1)
    endif
    pan_index = where(ypans ne 0, nypan)
    if nypan lt 1 then begin
        errmsg = 'Invalid ypans ...'
        return, retval
    endif
    poss = sgcalcpos(nypan, position=my_pos, ypans=ypans[pan_index], ypad=0)

    negative_pos = !null
    positive_pos = !null
    if nypan eq 1 then begin
        linear_pos = poss[*,0]
    endif else if nypan eq 3 then begin
        positive_pos = poss[*,0]
        linear_pos = poss[*,1]
        negative_pos = poss[*,2]
    endif else if nypan eq 2 then begin
        if has_negative_panel then begin
            linear_pos = poss[*,0]
            negative_pos = poss[*,1]
        endif else begin
            positive_pos = poss[*,0]
            linear_pos = poss[*,1]
        endelse
    endif

;---Figure out ticklen and panel_label
    chsz = get_charsize()
    xchsz = chsz[0]
    ychsz = chsz[1]
    fig_size = double([!d.x_size,!d.y_size])
    if n_elements(abs_ticklen) eq 0 then abs_ticklen = -0.3*ychsz*fig_size[1]
    if n_elements(abs_xticklen) eq 0 then abs_xticklen = abs_ticklen
    if n_elements(abs_yticklen) eq 0 then abs_yticklen = abs_ticklen
    if n_elements(panel_label_msg) eq 0 then panel_label_msg = ' '
    if n_elements(panel_label_pos) eq 0 then panel_label_pos = [my_pos[0]-xchsz*9,my_pos[3]-ychsz*0.7]

;---More settings.
    orig_labels = get_var_setting(var, 'labels')
    orig_ytitle = get_var_setting(var, 'ytitle')
    if n_elements(noerase) eq 0 then noerase = 0
    if n_elements(xtickformat) eq 0 then xtickformat = ''
    if n_elements(novtitle) eq 0 then novtitle = 0
    if n_elements(var_labels) eq 0 then var_labels = ''
    if n_elements(vlab_margin) eq 0 then vlab_margin = 10


;---Linear part.
    my_var = var+'_tmp'
    copy_data, var, my_var

    yrange = linear_yrange
    tpos = linear_pos
    xticklen = abs_xticklen/(tpos[3]-tpos[1])/fig_size[1]
    yticklen = abs_yticklen/(tpos[2]-tpos[0])/fig_size[0]
    xstyle = 1
    ytitle = orig_ytitle
    if has_negative_panel then begin
        my_xtickformat = '(A1)'
        my_novtitle = 1
        my_var_labels = ''
    endif else begin
        my_xtickformat = xtickformat
        my_novtitle = novtitle
        my_var_labels = var_labels
    endelse
    my_noerase = noerase
    my_labels = orig_labels
    options, my_var, yrange=yrange, ystyle=1, ytitle=ytitle, $
        xstyle=xstyle, xtickformat=my_xtickformat, labels=my_labels, ylog=0, $
        xticklen=xticklen, yticklen=yticklen
    if n_elements(linear_tick_setting) ne 0 then begin
        foreach key, linear_tick_setting.keys() do options, my_var, key, linear_tick_setting[key]
    endif
    tplot, my_var, position=tpos, noerase=my_noerase, novtitle=my_novtitle, trange=time_range, $
        var_label=my_var_labels, vlab_margin=vlab_margin
    del_data, my_var
    

    if n_elements(log_tick_setting) eq 0 then log_tick_setting = !null
    if n_elements(positive_tick_setting) eq 0 then positive_tick_setting = log_tick_setting
    if n_elements(negative_tick_setting) eq 0 then negative_tick_setting = log_tick_setting
    

;---Positive part.
    if has_positive_panel then begin
        my_var = var+'_tmp_positive'
        copy_data, var, my_var
    
        yrange = positive_yrange
        tpos = positive_pos
        xticklen = abs_xticklen/(tpos[3]-tpos[1])/fig_size[1]
        yticklen = abs_yticklen/(tpos[2]-tpos[0])/fig_size[0]
        xstyle = 1
        ytitle = ''
        my_xtickformat = '(A1)'
        my_novtitle = 1
        my_noerase = 1
        my_labels = orig_labels & my_labels[*] = ' '
        options, my_var, yrange=yrange, ystyle=1, ytitle=ytitle, $
            xstyle=xstyle, xtickformat=my_xtickformat, labels=my_labels, ylog=1, $
            xticklen=xticklen, yticklen=yticklen
        if n_elements(positive_tick_setting) ne 0 then begin
            foreach key, positive_tick_setting.keys() do options, my_var, key, positive_tick_setting[key]
        endif
        tplot, my_var, position=tpos, noerase=my_noerase, novtitle=my_novtitle, trange=time_range
        del_data, my_var
    endif


;---Negative part.
    if has_negative_panel then begin
        my_var = var+'_tmp_negative'
        copy_data, var, my_var
        yys = get_var_data(var, times=times, limits=lim)
        store_data, my_var, times, -yys, limits=lim
        yrange = reverse(minmax(abs(negative_yrange)))
        tpos = negative_pos
        xticklen = abs_xticklen/(tpos[3]-tpos[1])/fig_size[1]
        yticklen = abs_yticklen/(tpos[2]-tpos[0])/fig_size[0]
        xstyle = 1
        ytitle = ''
        my_xtickformat = xtickformat
        my_novtitle = novtitle
        my_noerase = 1
        my_labels = orig_labels & my_labels[*] = ' '
        my_var_labels = var_labels
        options, my_var, yrange=yrange, ystyle=1, ytitle=ytitle, $
            xstyle=xstyle, xtickformat=my_xtickformat, labels=my_labels, ylog=1, $
            xticklen=xticklen, yticklen=yticklen
        if n_elements(negative_tick_setting) ne 0 then begin
            foreach key, negative_tick_setting.keys() do options, my_var, key, negative_tick_setting[key]
        endif
        tplot, my_var, position=tpos, noerase=my_noerase, novtitle=my_novtitle, trange=time_range, $
            var_label=my_var_labels, vlab_margin=vlab_margin
        del_data, my_var
    endif


;---Labels.
    tx = panel_label_pos[0]
    ty = panel_label_pos[1]
    msg = panel_label_msg
    xyouts, tx,ty,normal=1, msg

    return, poss


end


var = 'mms1_e_gsm'
print, plot_linlog(var, linear_yrange=[-1,1]*5, log_yrange=[-1,1]*1000)
print, ''
print, plot_linlog(var, negative_yrange=[-1,-1], positive_yrange=[1,1])
end