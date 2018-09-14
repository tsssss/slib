;+
; Convert time in given format to ut.
;
; times. A time or an array of times in given format.
; format. A string specifies the format. Case sensitive for string format code.
;   Case-insensitive for other formats. See available format in convert_time.
;
; return. A time or an array of times in ut.
;-

function stotime, times, format

    ntime = n_elements(times)
    if ntime eq 0 then message, 'No input time ...'

    ; string format is case sensitive, treat it first.
    idx = strpos(format, '%')
    istring = idx[0] ne -1

    if istring then begin
        t_ut = dblarr(ntime)
        for i=0, ntime-1 do t_ut[i] = sfmdate(times[i], format)
        return, t_ut
    endif

    ; dispatch according to format.
    fmt = strlowcase(format)

    ; do nothing for unix time.
    idx = where(['ut','utc','unix'] eq fmt, cnt)
    if cnt ne 0 then return, times

    ; some constants.
    secofday = 86400d
    secofday1 = 1d/secofday
    t0_jd = 2440587.5d      ; in day, 0 of Julian day.
    t0_mjd = 40587d         ; in day, 0 of modified Julian day.
    t0_sdt = 50716800d      ; in sec, 0 of times in SDT.
    t0_epoch = 62167219200d ; in sec. offset for epoch and epoch16.


    case fmt of
        'epoch': return, 0.001D*times - t0_epoch
        'epoch16': return, real_part(times) + imaginary(times)*1d-12 - t0_epoch
        'jd': return, secofday*(times-t0_jd)
        'mjd': return, secofday*(times-t0_mjd)
        'sdt': return, times - t0_sdt
        'tt2000': begin
            cdf_tt2000, times[0], yr, mo, dy, hr, mi, sc, milli, micro, nano, /breakdown_epoch
            cdf_epoch, t_epoch, yr, mo, dy, hr, mi, sc, milli, /compute_epoch
            cdf_tt2000, t_tt2000, yr, mo, dy, hr, mi, sc, milli, /compute_epoch
            t_ut = stotime(t_epoch, 'epoch')
            return, t_ut + (times-t_tt2000)*1d-9
            end
        'numbers': begin
            ndim = size(times,/n_dimension)
            if ndim eq 2 then ntime = (size(times,/dimensions))[0]
            if ndim eq 1 then begin
                ntime = 1
                times = transpose(times)
            endif
    
            t_epoch = dblarr(ntime)
            nnumber = (size(times,/dimensions))[1]
            for i=0, ntime-1 do begin
                yr = times[i,0]
                mo = (nnumber ge 2)? times[i,1]: 1
                dy = (nnumber ge 3)? times[i,2]: 1
                hr = (nnumber ge 4)? times[i,3]: 0
                mi = (nnumber ge 5)? times[i,4]: 0
                sc = (nnumber ge 6)? times[i,5]: 0
                msc= (nnumber ge 7)? times[i,6]: 0
                cdf_epoch, tmp, yr, mo, dy, hr, mi, sc, msc, /compute_epoch
                t_epoch[i] = tmp
            endfor
            return, stotime(t_epoch, 'epoch')
            end
        else: message, 'Do not support format: '+format+' yet ...'
    endcase
end
