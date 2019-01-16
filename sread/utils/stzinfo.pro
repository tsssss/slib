;+
; return time zone offset in hour.
;-
function stzinfo, ut0, string = string

    ep0 = stoepoch(ut0,'unix')
    if !version.os_family eq 'Windows' then begin
        utstr = sfmepoch(ep0,'YYYY-MM-DD hh:mm:ss GMT')
        spawn, 'powershell $a = Get-Date -Date \"'+$
            utstr+'\" -UFormat \"%Z\";$a', tmp
        return, double(tmp[0])
    endif else if !version.os eq 'linux' then begin
        utstr = sfmepoch(ep0,'YYYY-MM-DD hh:mm:ss GMT')
        spawn, 'date --date="'+utstr+'" +"%z"', tmp
        tmp = double(tmp[0])
        return, fix(tmp/100)+(tmp mod 100)/60d
    endif else begin
        fmt = '%a %b %e %H:%M:%S %Y UTC'
        cdf_epoch, ep0, yr, mo, dy, hr, /breakdown_epoch
        spawn, 'zdump -v /etc/localtime | grep '+string(yr,format='(I4)'), tmp
        idx = [1,3] ; idx = where(stregex(tmp,'isdst=1') ne -1)
        utstrs = tmp[idx]
        uts = dblarr(2)
        lts = dblarr(2)
        for i = 0,1 do begin
            tut = utstrs[i]
            tut = strtrim(strmid(tut,strpos(tut,' ')),2)
            uts[i] = sfmdate(strmid(tut,0,28),fmt)
            tut = strtrim(strmid(tut,strpos(tut,'=')+1),2)
            lts[i] = sfmdate(strmid(tut,0,28),fmt)
        endfor
        dts = lts-uts
        dt = (ut0 ge uts[0] and ut0 lt uts[1])? dts[0]: dts[1]
        if ~keyword_set(string) then return, dt/3600d
        dtstr = (dt ge 0)? '+':'-'
        dt = ceil(abs(dt))
        dtstr+= string(dt/3600,format='(I02)')+$
            string((dt mod 3600)/60,format='(I02)')
        return, dtstr
    endelse
end

print, stzinfo(sfmdate('2015-11-01 07:00:00','%Y-%m-%d %H:%M:%S'),/string)
end