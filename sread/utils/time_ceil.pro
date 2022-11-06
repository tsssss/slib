;+
; To ceil a given time for a given cadence.
;
; time. A number or array. Input time in unix time.
; cadence. In sec or a string 'year','month','day','hour','min','sec'.
;-
function time_ceil, time, cadence

    if n_elements(cadence) ne 1 then return, time
    if size(cadence,type=1) ne 7 then return, time-(time mod cadence)+cadence

    cad = strlowcase(cadence)
    if cad eq 'day' then return, time_ceil(time, 86400d)
    if cad eq 'hour' then return, time_ceil(time, 3600d)
    if cad eq 'hr' then return, time_ceil(time, 3600d)
    if cad eq 'h' then return, time_ceil(time, 3600d)
    if cad eq 'minute' then return, time_ceil(time, 60d)
    if cad eq 'min' then return, time_ceil(time, 60d)
    if cad eq 'm' then return, time_ceil(time, 60d)
    if cad eq 'second' then return, time_ceil(time, 1d)
    if cad eq 'sec' then return, time_ceil(time, 1d)
    if cad eq 's' then return, time_ceil(time, 1d)

    et = convert_time(time,from='unix',to='epoch')
    if cad eq 'year' then cad = 'yr'
    if cad eq 'y' then cad = 'yr'
    if cad eq 'yr' then return, convert_time(sepochceil(et,cad),from='epoch',to='unix')

    if cad eq 'month' then cad = 'mo'
    if cad eq 'mon' then cad = 'mo'
    if cad eq 'mo' then return, convert_time(sepochceil(et,cad),from='epoch',to='unix')


end

print, time_string(time_ceil(time_double('2012-02'),'year'))
end