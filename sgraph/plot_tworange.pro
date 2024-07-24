;+
; Plot the data in a small and large range.
;
; var. tplot_var
; ypans=. [3].
; position=. position in normalized coord.
; yranges=. [n+1].
;-


function plot_tworange, var, ypans=ypans, position=my_pos, $
    yranges=yranges, noerase=noerase

    retval = !null

    nypan = n_elements(yranges)-1
    if nypan le 0 then return, retval
    if n_elements(ypans) ne nypan then ypans = fltarr(nypan)+1
    poss = sgcalcpos(position=my_pos,nypan,ypans=ypans,ypad=0)

    my_var = var+'_tmp'
    copy_data, var, my_var
    orig_labels = get_var_setting(my_var, 'labels')
    orig_ytitle = get_var_setting(my_var, 'ytitle')
    if n_elements(noerase) eq 0 then noerase = 0
    for pid=0,nypan-1 do begin
        tpos = poss[*,nypan-1-pid]
        yrange = yranges[pid:pid+1]
        if pid eq 0 then begin
            xtickformat = ''
            novtitle = 0
            my_noerase = noerase
        endif else begin
            xtickformat = '(A1)'
            novtitle = 1
            my_noerase = 1
        endelse
        xstyle = 1
        if pid eq 1 then begin
            labels = orig_labels
            ytitle = orig_ytitle
        endif else begin
            norig_label = n_elements(orig_labels)
            if norig_label eq 0 then labels = !null else labels = strarr(norig_label)+''
            ytitle = ' '
        endelse
        options, my_var, yrange=yrange, ystyle=1, ytitle=ytitle, $
            xstyle=xstyle, xtickformat=xtickformat, labels=labels
        tplot, my_var, position=tpos, noerase=my_noerase, novtitle=novtitle
    endfor

    return, retval

end