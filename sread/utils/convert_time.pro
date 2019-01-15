;+
; Convert a time in certain format to the specified format.
; 
; time. A time or an array of time.
; from. The input format of the time.
; to. The output format of the time.
; 
; return. The time in the output format.
; 
; Valid formats are:
;   * 'unix','ut','utc'.
;   * 'epoch'.
;   * 'epoch16'.
;   * 'tt2000'.
;   * 'jd'.
;   * 'mjd'.
;   * 'sdt'.
;   * 'numbers'.
;   * format code for string. See sfmdate/stodate for valid format code.
;-
function convert_time, times, from=from, to=to
    return, sfmtime(stotime(times, from), to)
end


t_unix = 1370580600.0d
t_epoch = 63537799800000d
t_epoch16 = complex(63537799800d,/double)
t_tt2000 = 423852667184000000ll
t_mjd = 56450.2013888889d
t_jd = 2456450.7013888889d
t_sdt = 1421297400d

print, convert_time([2013,6,7,4,50,0],from='numbers',to='unix')-t_unix
print, convert_time('2013-06-07/04:50',from='%Y-%m-%d/%H:%M',to='unix')-t_unix
print, convert_time(t_epoch,from='epoch',to='unix')-t_unix
print, convert_time(t_epoch16,from='epoch16',to='unix')-t_unix
print, convert_time(t_tt2000,from='tt2000',to='unix')-t_unix
print, convert_time(t_mjd,from='mjd',to='unix')-t_unix
print, convert_time(t_jd,from='jd',to='unix')-t_unix
print, convert_time(t_sdt,from='sdt',to='unix')-t_unix

print, convert_time(t_unix, from='unix', to='numbers')
print, convert_time(t_unix, from='unix', to='%Y-%m-%d/%H:%M')
print, convert_time(t_unix, from='unix', to='epoch')-t_epoch
print, convert_time(t_unix, from='unix', to='epoch16')-t_epoch16
print, convert_time(t_unix, from='unix', to='tt2000')-t_tt2000
print, convert_time(t_unix, from='unix', to='mjd')-t_mjd
print, convert_time(t_unix, from='unix', to='jd')-t_jd
print, convert_time(t_unix, from='unix', to='sdt')-t_sdt

end