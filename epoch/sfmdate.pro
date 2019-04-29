;+
; convert string to unix time in utc.
; set utc or include gmt in the date, otherwise local time is assumed.
;-

;%a: abbrev weekday name. Sun. ??
;%A: full weekday name. Sunday. ??
;%b: abbrev month name. Jan.
;%B: full month name. January.
;%c: local's date and time (eg %a %b %d %H:%M:%S %Y).
;%C: century. first 2 digit of YYYY and +1 (eg 21).
;%d: day of month (eg 01).
;%D: date. %m/%d/%y.
;%e: day of month, space padded. %_d.
;%F: full date. %Y-%m-%d
;%g: last 2 digits of year of ISO week number. ??
;%G: year of ISO week number. ??
;%h: same as %b.
;%H: hour. 00-23.
;%I: hour. 01-12.
;%j: day of year. 001-366.
;%k: hour. _0-23.
;%l: hour. _1-12.
;%m: month. 01-12.
;%M: minute. 00-59.
;%n: a newline. ??
;%N: nano sec. 0x9-9x9.
;%p: locale's equivalent of AM/PM.
;%P: lowercase am/pm.
;%r: locale's 12hr time (eg 11:11:04 PM).
;%R: %H:%M.
;%s: unix time. sec from 1970-01-01 00:00:00 UTC.
;%S: seconde. 00-60.
;%t: a tab. ??
;%T: %H:%M:%S.
;%u: day of week. 1-7. 1 is Mon.
;%U: week number of year. Sun 1st day of week. 00-53.
;%V: ISO week number, Mon 1st day of week. 01-53.
;%w: day of week. 0 is Sun.
;%W: week number of year, Mon 1st day of week. 00-53.
;%x: locale's date representation (eg 12/31/99).
;%X: locale's time representation (eg 23:13:48).
;%y: last 2 digits of year. 00-99.
;%Y: year (eg 1998).
;%z: +hhmm numeric timezone (eg -0400).
;%Z: alphabetic time zone abbrev (eg EDT).

function sfmdate, d0, f10
    
    if n_elements(f10) eq 0 then message, 'no format ...'
    f1 = f10[0]         ; format.
    d1 = string(d0[0])  ; time string.
    
    if strlen(d1) eq 0 then return, 0d
    
    var = 62167219200d  ; const for epeoch/unix time conversion.
    per = '%'
    if strpos(f1,per) eq -1 then message, 'no valid format code ...'

    ; vars.
    abs = ['jan','feb','mar','apr','may','jun', $
        'jul','aug','sep','oct','nov','dec']
    fbs = ['january','feburary','march','april','may','june', $
        'july','august','september','october','november','december']
    tzinfo = {gmt:0000, utc:0000, uct:0000, ut:0000, wet:0000, z:0000, $
        cst:-0600,cdt:-0500}
    tzs = strlowcase(tag_names(tzinfo))

    ; expand short-hand format code.
    fc1 = per+['c','D','F', $
        'h','r','R','T', $
        'x','X']
    fc2 = ['%a %b %d %H:%M:%S %Y','%m/%d/%y','%Y-%m-%d', $
        '%b','%I:%M:%S %p','%H:%M','%H:%M:%S',$
        '%m/%d/%y','%H:%M:%S']
    nfc = n_elements(fc1)
    for i = 0, nfc-1 do begin
        idx = strpos(f1,fc1[i])
        while idx ne -1 do begin
            f1 = strmid(f1,0,idx)+fc2[i]+strmid(f1,idx+2)
            idx = strpos(f1,fc1[i])
        endwhile
    endfor

    ; ignored.
    fc1 = per+['a','A','g','G','u','U','V','w','W','t','n']

    ; deal with prefix.
    if strmid(f1,0,1) ne per then begin
        idx = strpos(f1,per)
        pre = strmid(f1,0,idx)
        f1 = strmid(f1,idx)
        idx = strpos(d1,pre)
        if idx[0] eq -1 then message, 'mismatch between format and date ...'
        d1 = strmid(d1,idx+strlen(pre))
    endif


    ; split format code.
    fcs = strsplit(f1,per,/extract)
    nfc = n_elements(fcs)

    ; get current time to fill the default values.
    ut0 = systime(1)
    ep0 = 1000d*(ut0+var)
    ep0 = ep0-(ep0 mod 86400000d)   ; start of the day.
    cdf_epoch, ep0, yr, /breakdown_epoch
    mo = 1.
    dy = 1.
    hr = 0.
    mi = 0.
    sc = 0.
    msc = 0.

    for i = 0, nfc-1 do begin
        tfc = fcs[i]
        suf = strmid(tfc,1)
        if suf ne '' then tfc = strmid(tfc,0,1)
        case tfc of
            'b': begin  ; abbrev month name, eg Jan.
                idx = 3 ; length of the wanted string in d1.
                mo = where(abs eq strlowcase(strmid(d1,0,idx)))+1 & end
            'B': begin  ; full month name, eg January.
                idx = stregex(d1,'[^a-zA-Z]')-1
                mo = where(abs eq strlowcase(strmid(d1,0,idx)))+1 & end
            'C': begin  ; century et 21 for 20xx.
                idx = 2
                yr = (yr mod 100)+100*fix(strmid(d1,0,idx)) & end
            'd': begin  ; day of month (eg 01).
                idx = 2
                dy = fix(strmid(d1,0,idx)) & end
            'e': begin  ; day of month, space padded. % d.
                idx = 2
                dy = fix(strmid(d1,0,idx)) & end
            'H': begin  ; hour. 00-23.
                idx = 2
                hr = fix(strmid(d1,0,idx)) & end
            'I': begin  ; hour. 01-12.
                idx = 2
                hr = fix(strmid(d1,0,idx)) & end
            'j': begin  ; day of year. 001-366.
                idx = 3
                doy = fix(strmid(d1,0,idx)) & end
            'k': begin  ; hour. _0-23.
                idx = 2
                hr = fix(strmid(d1,0,idx)) & end
            'l': begin  ; hour. _1-12.
                idx = 2
                hr = fix(strmid(d1,0,idx)) & end
            'm': begin  ; month. 01-12.
                idx = 2
                mo = fix(strmid(d1,0,idx)) & end
            'M': begin  ; minute. 00-59.
                idx = 2
                mi = fix(strmid(d1,0,idx)) & end
            'N': begin  ; nano sec. 0x9-9x9.
                idx = 9
                fsc = 1d-9*fix(strmid(d1,0,idx)) & end
            'p': begin  ; locale's equivalent of AM/PM.
                idx = 2
                if strmid(d1,0,idx) eq 'PM' then hr+=12 & end
            'P': begin  ; locale's equivalent of am/pm.
                idx = 2
                if strmid(d1,0,idx) eq 'pm' then hr+=12 & end
            's': begin  ; unix time. sec from 1970-01-01 00:00:00 UTC.
                idx = (suf eq '')? strlen(d1): strpos(d1,suf)
                ut0 = double(strmid(d1,0,idx))
                ep0 = 1000d*(ut0+62167219200d)
                cdf_epoch, ep0, yr, mo, dy, hr, mi, sc, msc, /breakdown_epoch
                fsc = msc*1d-3 & end
            'S': begin  ; seconde. 00-60.
                idx = 2
                sc = double(strmid(d1,0,idx)) & end
            'y': begin  ; YY.
                idx = 2
                yr = yr-(yr mod 100)+fix(strmid(d1,0,idx)) & end
            'Y': begin  ; YYYY.
                idx = 4
                yr = fix(strmid(d1,0,idx)) & end
            'z': begin  ; numeric timezone, eg +hhmm.
                idx = 5
                if strmid(d1,0,1) ne '+' then idx = 4   ; hhmm.
                dt = fix(strmid(d1,0,idx)) & end
            'Z': begin  ; alphabetic time zone abbrev, eg EDT.
                idx = stregex(d1,'[^a-zA-Z]')
                if idx eq -1 then idx = strlen(d1)
                tmp = strlowcase(strmid(d1,0,idx))
                dt = tzinfo.(where(tzs eq tmp)) & end
            else: ; do nothing.
        endcase
        if suf ne '' then idx = strpos(d1,suf,idx)+strlen(suf)
        d1 = strmid(d1,idx)
    endfor
    if n_elements(doy) ne 0 then begin
        tmp = sfmdoy(yr,doy)
        mo = tmp[0] & dy = tmp[1]
    endif
    if n_elements(fsc) eq 0 then fsc = 0d
    cdf_epoch, ep0, yr, mo, dy, hr, mi, sc, fsc*1d3, /compute_epoch
    ut0 = 0.001D*ep0-var

    ; deal with time zone. lt = utc+dt.
    if n_elements(dt) eq 0 then dt = 0  ; assume UTC.
    ut0-= ((dt mod 100)+fix(dt/100)*60d)*60d
    
    return, ut0
end

d0 = 'Date: Thu, 02 May 2013 01:24:35 GMT'
f1 = 'Date: %a, %d %b %Y %H:%M:%S GMT'
d0 = '2015-11-01 01:00:00 CST'
d0 = '2015-11-01 01:00:00 CDT'
f1 = '%Y-%m-%d %H:%M:%S %Z'
d0 = 'Sun Mar  8 03:00:00 2015 CDT'
f1 = '%a %b %e %H:%M:%S %Y UTC'
d0 = '201409'
f1 = '%Y%m'
;f1 = '%T %D'
d1 = sfmdate(d0, f1)
print, time_string(d1)
print, time_string(sfmdate(d1, '%s'))
end
