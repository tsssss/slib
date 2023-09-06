;+
; Filter data for a given range.
; 
; data. An array of data.
; range. One or two numbers.
; relation. A string, e.g., [] to select data in [min,max].
;   Similarly, it can be [],[),(],(),[,(,),].
;-

function where_pro, data, relation, range, count=count, _extra=ex

    if n_params() eq 2 then begin
        rel = 'in'
        val = relation
    endif else begin
        rel = relation
        val = range
    endelse

    case rel of
        'in': res = where(data ge val[0] and data le val[1], count, _extra=ex)
        'within': res = where(data gt val[0] and data lt val[1], count, _extra=ex)
        'ge': res = where(data ge val[0], count, _extra=ex)
        'gt': res = where(data gt val[0], count, _extra=ex)
        'le': res = where(data le val[0], count, _extra=ex)
        'lt': res = where(data lt val[0], count, _extra=ex)
        '[)': res = where(data ge val[0] and data lt val[1], count, _extra=ex)
        '(]': res = where(data gt val[0] and data le val[1], count, _extra=ex)
        '[]': res = where(data ge val[0] and data le val[1], count, _extra=ex)
        '()': res = where(data gt val[0] and data lt val[1], count, _extra=ex)
        '][': res = where(data le val[0] or data ge val[1], count, _extra=ex)
        '](': res = where(data le val[0] or data gt val[1], count, _extra=ex)
        ')(': res = where(data lt val[0] or data gt val[1], count, _extra=ex)
        ')[': res = where(data lt val[0] or data ge val[1], count, _extra=ex)
        '[': res = where(data ge val[0], count, _extra=ex)
        '(': res = where(data gt val[0], count, _extra=ex)
        ']': res = where(data le val[0], count, _extra=ex)
        ')': res = where(data lt val[0], count, _extra=ex)
    endcase
    
    if count eq 0 then res = !null
    return, res

end


data = [1,2,3,4,5,6]
print, where_pro(data, 'in', [1,5])
print, where_pro(data, 'within', [1,5])
print, where_pro(data, 'gt', 1)
print, where_pro(data, 'ge', 1)
print, where_pro(data, 'lt', 1, count=count), count
print, where_pro(data, 'le', 1)
print, where_pro(data, '[]', [2,4], count=count)
end