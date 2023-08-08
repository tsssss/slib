;+
; Type: function.
; Purpose: convert unix time in utc to string.
; Parameters: <+++>.
;   <+varname+>, <+in/out+>, <+datatype+>, <+req/opt+>. <+++>.
; Keywords: <+++>.
;   <+varname+>, <+in/out+>, <+datatype+>, <+req/opt+>. <+++>.
; Return: <+++>.
; Notes: The format code used in Unix date is adopted partially, the
;   format codes related to number of week in year and day of week are not
;   implemented. Here is a list of implemented format codes.
;       %b: abbrev month name, eg Jan.
;       %B: full month name, eg January.
;       %c: local's date and time. %a %b %d %H:%M:%S %Y.
;       %C: century. first 2 digit of YYYY then +1, eg 21 for 2015.
;       %d: day of month, eg 01.
;       %D: date. %m/%d/%y.
;       %e: day of month, space padded , eg _1,12 (_ visualize the space).
;       %F: full date. %Y-%m-%d.
;       %h: same as %b.
;       %H: hour. 00-23.
;       %I: hour. 01-12.
;       %j: day of year. 001-366.
;       %k: hour. _0-23.
;       %l: hour. _1-12.
;       %m: month. 01-12.
;       %M: minute. 00-59.
;       %n: a newline.
;       %N: nano sec. 000000000-999999999.
;       %p: locale's equivalent of AM/PM.
;       %P: lowercase am/pm.
;       %r: locale's 12hr time, eg 11:11:04 PM. %I:%M:%S %p.
;       %R: %H:%M.
;       %s: unix time. sec from 1970-01-01 00:00:00 UTC.
;       %S: seconde. 00-60.
;       %t: a tab.
;       %T: %H:%M:%S.
;       %x: locale's date representation, eg 12/31/99. %m/%d/%y.
;       %X: locale's time representation, eg 23:13:48. %H:%M:%S.
;       %y: last 2 digits of year. 00-99.
;       %Y: year, eg 1998.
;       %z: +hhmm numeric timezone, eg -0400.
;       %Z: alphabetic time zone abbrev, eg EDT.
;   %Z is very unreliable, because it leads to ambiguous results.
; Dependence: slib.
; History:
;   2015-05-01, Sheng Tian, create.
;-
function stodate, ut0, f10
    
    if n_elements(f10) eq 0 then message, 'no format ...'
    f1 = f10[0]         ; format.
    d1 = ''             ; time string.
    
    var = 62167219200d  ; const for epeoch/unix time conversion.
    per = '%'
    if strpos(f1,per) eq -1 then begin
        message, 'No valid format code ...', /continue
        return, f10
    endif

    ; vars.
    abs = ['Jan','Feb','Mar','Apr','May','Jun', $
        'Jul','Aug','Sep','Oct','Nov','Dec']
    fbs = ['January','Feburary','March','April','May','June', $
        'July','August','September','October','November','December']
    tzinfos = [$    ; http://www.timeanddate.com/time/zones/.
        {abbr:'GMT',dtstr:'+0000',dt:0 ,name:'Greenwich Mean Time'},$
        {abbr:'UTC',dtstr:'+0000',dt:0 ,name:'Coordinated Universal Time'},$
        {abbr:'UT' ,dtstr:'+0000',dt:0 ,name:'Universal Time'},$
        {abbr:'Z'  ,dtstr:'+0000',dt:0 ,name:'Zulu Time Zone'},$
        {abbr:'CDT',dtstr:'-0500',dt:-5,name:'Central Daylight Time'},$
        {abbr:'CST',dtstr:'-0600',dt:-6,name:'Central Standard Time'}]
    dts = tzinfos.dtstr

    ; expand short-hand format code.
    fc1 = per+['c','D','F', $
        'h','r','R','T', $
        'x','X','n','t']
    fc2 = ['%a %b %d %H:%M:%S %Y','%m/%d/%y','%Y-%m-%d', $
        '%b','%H:%M:%S %p','%H:%M','%H:%M:%S',$
        '%m/%d/%y','%H:%M:%S',string(10b),string(9b)]
    nfc = n_elements(fc1)
    for i = 0, nfc-1 do begin
        idx = strpos(f1,fc1[i])
        while idx ne -1 do begin
            f1 = strmid(f1,0,idx)+fc2[i]+strmid(f1,idx+2)
            idx = strpos(f1,fc1[i])
        endwhile
    endfor

    ; ignored.
    fc1 = per+['a','A','g','G','u','U','V','w','W']

    ; deal with prefix.
    if strmid(f1,0,1) ne per then begin
        idx = strpos(f1,per)
        pre = strmid(f1,0,idx)
        f1 = strmid(f1,idx)
        d1+= pre
    endif

    ; split format code.
    fcs = strsplit(f1,per,/extract)
    nfc = n_elements(fcs)

    ; get the date time components.
    ep0 = 1000d*(ut0+var)
    cdf_epoch, ep0, yr, mo, dy, hr, mi, sc, msc, /breakdown_epoch
    dt = stzinfo(ut0)

    for i = 0, nfc-1 do begin
        tfc = fcs[i]
        suf = strmid(tfc,1)
        if suf ne '' then tfc = strmid(tfc,0,1)
        case tfc of
            'b': d1+= abs[mo-1]
            'B': d1+= fbs[mo-1]
            'C': d1+= string(fix(yr/100),format='(I02)')
            'd': d1+= string(dy,format='(I02)')
            'e': d1+= string(dy,format='(I2)')
            'H': d1+= string(fix(hr),format='(I02)')
            'I': d1+= string(fix(hr mod 12),format='(I02)')
            'j': d1+= string(stodoy(yr,mo,dy),format='(I03)')
            'k': d1+= string(fix(hr),format='(I2)')
            'l': d1+= string(fix(hr mod 12),format='(I2)')
            'm': d1+= string(mo,format='(I02)')
            'M': d1+= string(mi,format='(I02)')
            'N': d1+= string(long(msc*1d6),format='(I09)')
            'p': d1+= (hr le 12)? 'AM': 'PM'
            'P': d1+= (hr le 12)? 'am': 'pm'
            's': d1+= strtrim(string(long(ut0),format='(I)'))
            'S': d1+= string(sc,format='(I02)')
            'y': d1+= string((yr mod 100),format='(I02)')
            'Y': d1+= string(yr,format='(I04)')
            'z': d1+= stzinfo(ut0,/string)
            'Z': d1+= ((tzinfos.abbr)[where(tzinfos.dt eq stzinfo(ut0))])[0]
            else: d1+= per+tfc  ; put code back if do not know its meaning.
        endcase
        d1+= suf
    endfor
    return, d1
end

d0 = 'Date: Thu, 02 May 2013 01:24:35 GMT'
f1 = 'Date: %a, %d %b %Y %H:%M:%S GMT'
d0 = '2015-11-01 01:00:00 CST'
d0 = '2015-11-01 01:00:00 CDT'
f1 = '%Y-%m-%d %H:%M:%S %Z'
d0 = 'Mar  8 03:00:00 2015 CDT'
f1 = '%b %e %H:%M:%S %Y %Z'
print, stodate(sfmdate(d0,f1),f1)
end
