;+
; Filter data for a given range.
; 
; data. An array of data.
; range. One or two numbers.
; relation. A string, e.g., [] to select data in [min,max].
;   Similarly, it can be [],[),(],(),[,(,),].
;-

function lazy_where, data, relation, range, count=count, _extra=ex

    if n_params() eq 2 then begin
        rel = 'in'
        val = relation
    endif else begin
        rel = relation
        val = range
    endelse

    case rel of
        'in': return, where(data ge val[0] and data le val[1], count, _extra=ex)
        'within': return, where(data gt val[0] and data lt val[1], count, _extra=ex)
        'ge': return, where(data ge val[0], count, _extra=ex)
        'gt': return, where(data gt val[0], count, _extra=ex)
        'le': return, where(data le val[0], count, _extra=ex)
        'lt': return, where(data lt val[0], count, _extra=ex)
        '[)': return, where(data ge val[0] and data lt val[1], count, _extra=ex)
        '[]': return, where(data ge val[0] and data le val[1], count, _extra=ex)
        '()': return, where(data gt val[0] and data lt val[1], count, _extra=ex)
        '][': return, where(data le val[0] or data ge val[1], count, _extra=ex)
        '](': return, where(data le val[0] or data gt val[1], count, _extra=ex)
        ')(': return, where(data lt val[0] or data gt val[1], count, _extra=ex)
        ')[': return, where(data lt val[0] or data ge val[1], count, _extra=ex)
        '[': return, where(data ge val[0], count, _extra=ex)
        '(': return, where(data gt val[0], count, _extra=ex)
        ']': return, where(data le val[0], count, _extra=ex)
        ')': return, where(data lt val[0], count, _extra=ex)
    endcase

end


data = [1,2,3,4,5,6]
print, lazy_where(data, 'in', [1,5])
print, lazy_where(data, 'within', [1,5])
print, lazy_where(data, 'gt', 1)
print, lazy_where(data, 'ge', 1)
print, lazy_where(data, 'lt', 1, count=count), count
print, lazy_where(data, 'le', 1)
print, lazy_where(data, '[]', [2,4], count=count)
end