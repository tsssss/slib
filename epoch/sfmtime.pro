;+
; Convert ut to time in given format.
;
; times. A time or an array of times in ut. 
; format. A string specifies the format. Case sensitive for string format code.
;   Case-insensitive for other formats. See available format in convert_time.
;
; return. A time or an array of times in given format.
;-

function sfmtime, times, format

    ntime = n_elements(times)
    if ntime eq 0 then message, 'No input time ...'

    ; string format is case sensitive, treat it first.
    idx = strpos(format, '%')
    istring = idx[0] ne -1

    if istring then begin
        t_ut = strarr(ntime)
        for i=0, ntime-1 do t_ut[i] = stodate(times[i], format)
        return, t_ut
    endif

    ; dispatch according to format.
    fmt = strlowcase(format)

    ; do nothing for unix time.
    idx = where(['ut','utc','unix'] eq fmt, cnt)
    if cnt ne 0 then return, times

    ; some constants.
    secofday = 86400d
    secofday1 = 1/secofday
    t0_jd = 2440587.5d      ; in day, 0 of Julian day.
    t0_mjd = 40587d         ; in day, 0 of modified Julian day.
    t0_sdt = 50716800d      ; in sec, 0 of times in SDT.
    t0_epoch = 62167219200d ; in sec. offset for epoch and epoch16.


    case fmt of
        'epoch': return, 1e3*(times+t0_epoch)
        'epoch16': begin
            t_out = sfmtime(times, 'epoch')*1d-3
            t_ut = t_out mod 1
            return, complex(t_out-t_ut, t_ut*1d12, /double)
            end
        'jd': return, secofday1*times + t0_jd
        'mjd': return, secofday1*times + t0_mjd
        'sdt': return, times + t0_sdt
        'tt2000': begin
            t_epoch = sfmtime(times[0], 'epoch')
            cdf_epoch, t_epoch, yr, mo, dy, hr, mi, sc, milli, /breakdown_epoch
            cdf_tt2000, t0_tt2000, yr, mo, dy, hr, mi, sc, milli, /compute_epoch
            return, long64(t0_tt2000+(times-times[0])*1d9)
            end
        'numbers': begin
            t_numbers = fltarr(ntime,7)
            t_epoch = sfmtime(times, 'epoch')
            for i=0, ntime-1 do begin
                cdf_epoch, t_epoch[i], yr, mo, dy, hr, mi, sc, msc, /breakdown_epoch
                t_numbers[i,*] = [yr,mo,dy,hr,mi,sc,msc]
            endfor
            return, t_numbers
            end
        else: message, 'Do not support format: '+format+' yet ...'
    endcase
end

