;+
; Uniform interface for converting among standard coordinates:
; 'GSE','SM','GSM','GEI','GEO','MAG'.
;
; vec0. An array in [3] or [n,3]. In GEI, in any unit.
; times. An array of UT sec, in [n].
; msg. A string in the format of 'gsm2gse', where 2 separates the
;   input and output coordinates.
;-
function cotran, vec0, time, msg, errmsg=errmsg
    compile_opt idl2 & on_error, 2

    errmsg = ''
    retval = !null
    if n_elements(msg) eq 0 then begin
        errmsg = handle_error('No input message ...')
        return, retval
    endif

    ; Call existing functions.
    native_functions = [$
        'gei2geo','geo2gei', $
        'gei2gse','gse2gei', $
        'geo2mag','mag2geo', $
        'gse2gsm','gsm2gse', $
        'gsm2sm','sm2gsm']
    index = where(native_functions eq msg, count)
    if count ne 0 then return, call_function(msg, vec0, time)

    ; Use existing functions to coerce.
    coords = strsplit(msg,'2',/extract)
    case coords[0] of
        'sm': vec1 = gsm2gse(sm2gsm(vec0,time),time)
        'gsm': vec1 = gsm2gse(vec0,time)
        'gei': vec1 = gei2gse(vec0,time)
        'geo': vec1 = gei2gse(geo2gei(vec0,time),time)
        'mag': vec1 = gei2gse(geo2gei(mag2geo(vec0,time),time),time)
        else: begin
            errmsg = handle_error('Unknown input coord: '+coords[0]+' ...')
            return, retval
            end
    endcase

    case coords[1] of
        'sm': return, gsm2sm(gse2gsm(vec1,time),time)
        'gsm': return, gse2gsm(vec1,time)
        'gei': return, gse2gei(vec1,time)
        'geo': return, gei2geo(gse2gei(vec1,time),time)
        'mag': return, geo2mag(gei2geo(gse2gei(vec1,time),time),time)
        else: begin
            errmsg = handle_error('Unknown output coord: '+coords[1]+' ...')
            return, retval
            end
    endcase
end
