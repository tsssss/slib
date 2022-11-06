;+
; Plot a map for all sites on the MLat/MLon plane.
;-
pro themis_read_mag_gen_site_map, site0s, filename=file, $
    mlon_range=mlon_range, mlat_range=mlat_range, position=tpos, $
    xsize=xsize, ysize=ysize, symsize=symsize, charsize=charsize, colors=colors, ct=ct, _extra=ex

    if n_elements(mlon_range) ne 2 then mlon_range = [-1,1]*180
    if n_elements(mlat_range) ne 2 then mlat_range = [-1,1]*90
    ;if n_elements(file) eq 0 then file = sparentdir(srootdir())+'/support/themis_mag_site_map.pdf'
    if n_elements(xsize) eq 0 then xsize=8d
    if n_elements(ysize) eq 0 then ysize=(xsize/(mlon_range[1]-mlon_range[0])*(mlat_range[1]-mlat_range[0])*0.5)>2
    if n_elements(symsize) eq 0 then symsize=0.5
    if n_elements(charsize) eq 0 then charsize = 0.5
    
    sites = strlowcase(site0s)
    nsite = n_elements(sites)
    
    infos = themis_read_mag_metadata()
    ninfo = n_elements(infos)
    if nsite ne 0 then begin
        flags = bytarr(ninfo)
        for ii=0, ninfo-1 do begin
            index = where(sites eq infos[ii].id, count)
            if count ne 0 then flags[ii] = 1
        endfor
        index = where(flags eq 1, count)
        if count ne 0 then infos = infos[index]
    endif

    if keyword_set(file) then sgopen, file, xsize=xsize, ysize=ysize

    xchsz = double(!d.x_ch_size)/!d.x_size
    ychsz = double(!d.y_ch_size)/!d.y_size
    ticklen = -0.01
    if n_elements(tpos) ne 4 then tpos = sgcalcpos(1, lmargin=8, bmargin=4, tmargin=1, rmargin=2)

    plot, mlon_range, mlat_range, /nodata, position=tpos, $
        xstyle=1, xticks=4, xminor=9, xtitle='MLon (deg)', xticklen=ticklen, $
        ystyle=1, yticks=4, yminor=9, ytitle='MLat (deg)', yticklen=ticklen, $
        /noerase, _extra=ex
    
    index = sort(infos.mlon)
    infos = infos[index]
    
    ninfo = n_elements(infos)
    if n_elements(colors) ne ninfo then begin
        colors = smkarthm(0,250,ninfo,'n')
        for ii=0, ninfo-1 do colors[ii] = sgcolor(colors[ii], ct=ct)
    endif
    
    foreach tinfo, infos, ii do begin
        color = colors[ii]
        plots, tinfo.mlon, tinfo.mlat, /data, psym=1, symsize=symsize, color=color
        tmp = convert_coord(tinfo.mlon, tinfo.mlat, /data, /to_normal)
        tx = tmp[0]+xchsz*0.6*charsize
        ty = tmp[1]-ychsz*0.3*charsize
        xyouts, tx,ty,/normal, strupcase(tinfo.id), charsize=charsize, color=color
    endforeach
    if keyword_set(file) then sgclose
end
