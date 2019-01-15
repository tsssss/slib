;+
; Type: function.
; Purpose: Convert coord data to real data.
; Parameters: 
;   ifn, in, string, req. Input file contains coord data.
; Keywords: none.
; Return: struct. {x:x, y:y}.
; Notes: none.
; Dependence: none.
; History:
;   2014-01-28, Sheng Tian, create.
;-

pro s_readpspath, vars, xx, yy, mode = mode
    on_error, 2
    if n_elements(mode) eq 0 then mode = 'm'
    nrec = n_elements(vars) & yy = dblarr(nrec,2)
    yy[0,*] = strsplit(vars[0],',',/extract)
    for i = 1, nrec-1 do begin
        tmp = strsplit(vars[i],',',/extract)
        case mode of
            'm': yy[i,*] = yy[i-1,*]+tmp
            else: yy[i,*] = tmp
        endcase
    endfor
    xx = yy[*,0] & yy = yy[*,1]
end

function sps2data, ifn
    on_error, 0
    if file_test(ifn) ne 1 then message, 'cannot find file ...'
    tline = ''
    varnum = 1
    openr, lun, ifn, /get_lun
    vars = !null
    while ~eof(lun) do begin
        ; read lines for one var, stop until empty line or eof.
        buffer = !null
        while ~eof(lun) do begin
            readf, lun, tline
            if tline eq '' then break
            buffer = [buffer,tline]
        endwhile

        ; find var name.
        idx = where(stregex(buffer, '^varnam:',/boolean),cnt)
        if cnt eq 0 then vname = 'var'+string(varnum,format='(I0)') $
        else vname = (strsplit(buffer[idx],': ',/extract))[1]

        ; find coord data.
        idx = where(stregex(buffer, '^points:',/boolean),cnt)
        if cnt eq 0 then message, 'no data points ...'
        tmp = strsplit(buffer[idx],': ',/extract)
        s_readpspath, tmp[2:*], xx, yy, mode = tmp[1]
        
        ; find [xy]range for data box.
        idx = where(stregex(buffer, '^xcoord:',/boolean),cnt)
        if cnt eq 0 then begin
            xxrange = minmax(xx)
        endif else begin
            tmp = strsplit(buffer[idx],': ',/extract)
            s_readpspath, tmp[2:*], xxrange, dum, mode = tmp[1]
        endelse
        idx = where(stregex(buffer, '^ycoord:',/boolean),cnt)
        if cnt eq 0 then begin
            yyrange = minmax(yy)
        endif else begin
            tmp = strsplit(buffer[idx],': ',/extract)
            s_readpspath, tmp[2:*], dum, yyrange, mode = tmp[1]
        endelse
        
        ; find [xy]range, and [xy]log.
        idx = where(stregex(buffer, '^xrange:',/boolean),cnt)
        if cnt eq 0 then begin      ; no range.
            xrange = xxrange
            xlog = 0
        endif else begin
            xrange = dblarr(2)
            tmp = strsplit(strmid(buffer[idx],7),',',/extract)
            if n_elements(tmp) eq 2 then xlog = 0 $         ; no xlog.
            else xlog = strtrim(tmp[2],2) eq 'log'
            tmp = strtrim(tmp[0:1],2)
            if stregex(tmp[0],'[-/: ]') ne -1 then begin    ; epoch range.
                len = strlen(tmp[0])
                case len of
                    13: format = 'yyyy-mm-dd/hh'
                    16: format = 'yyyy-mm-dd/hh:mi'
                    19: format = 'yyyy-mm-dd/hh:mi:ss'
                    23: format = 'yyyy-mm-dd/hh:mi:ss.msc'
                endcase
                xrange[0] = sfmepoch(stoepoch(tmp[0],format),'unix')
                xrange[1] = sfmepoch(stoepoch(tmp[1],format),'unix')
            endif else xrange = double(tmp)                 ; normal range.
        endelse
        idx = where(stregex(buffer, '^yrange:',/boolean),cnt)
        if cnt eq 0 then begin      ; no range.
            yrange = yyrange
            ylog = 0
        endif else begin
            yrange = dblarr(2)
            tmp = strsplit(strmid(buffer[idx],7),',',/extract)
            if n_elements(tmp) eq 2 then ylog = 0 $         ; no ylog.
            else ylog = strtrim(tmp[2],2) eq 'log'
            tmp = strtrim(tmp[0:1],2)
            if stregex(tmp[0],'[/: ]') ne -1 then begin    ; epoch range.
                len = strlen(tmp[0])
                case len of
                    13: format = 'yyyy-mm-dd/hh'
                    16: format = 'yyyy-mm-dd/hh:mi'
                    19: format = 'yyyy-mm-dd/hh:mi:ss'
                    23: format = 'yyyy-mm-dd/hh:mi:ss.msc'
                endcase
                yrange[0] = sfmepoch(stoepoch(tmp[0],format),'unix')
                yrange[1] = sfmepoch(stoepoch(tmp[1],format),'unix')
            endif else yrange = double(tmp)                 ; normal range.
        endelse

        ; scale data.
        if xlog then begin
            tmp = (alog(xrange[1])-alog(xrange[0]))/(xxrange[1]-xxrange[0])
            x = exp(alog(xrange[0])+(xx-xrange[0])*tmp)
        endif else begin
            tmp = (xrange[1]-xrange[0])/(xxrange[1]-xxrange[0])
            x = xrange[0]+(xx-xxrange[0])*tmp
        endelse
        if ylog then begin
            tmp = (alog(yrange[1])-alog(yrange[0]))/(yyrange[1]-yyrange[0])
            y = exp(alog(yrange[0])+(yy-yrange[0])*tmp)
        endif else begin
            tmp = (yrange[1]-yrange[0])/(yyrange[1]-yyrange[0])
            y = yrange[0]+(yy-yyrange[0])*tmp
        endelse
        opt = {xrange:xrange, xlog:xlog, yrange:yrange, ylog:ylog}
        vars = create_struct(vars, vname, {x:x, y:y, opt:opt})
    endwhile
    free_lun, lun
    return, vars
end
