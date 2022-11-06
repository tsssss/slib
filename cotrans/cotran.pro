

;+
; Uniform interface for converting among standard coordinates:
; 'GSE','SM','GSM','GEI','GEO','MAG'.
;
; vec0. An array in [3] or [n,3]. In GEI, in any unit.
; times. An array of UT sec, in [n].
; msg. A string in the format of 'gsm2gse', where 2 separates the
;   input and output coordinates.
; print_coord=. A boolean to return all supported coords.
;-
function cotran, vec0, time, msg, errmsg=errmsg, print_coord=print_coord, _extra=ex
    compile_opt idl2 & on_error, 2

    errmsg = ''
    retval = !null

    ; Call existing functions.
    native_functions = [$
        'gei2geo','geo2gei', $
        'gei2gse','gse2gei', $
        'geo2mag','mag2geo', $
        'gse2gsm','gsm2gse', $
        'gsm2sm','sm2gsm', $
        'mgse2gse','gse2mgse', $
        'uvw2gse','gse2uvw']
        
    supported_coord = strsplit(native_functions,'2',/extract)
    supported_coord = supported_coord.toarray()
    supported_coord = supported_coord[*]
    supported_coord = suniq(supported_coord)
    if keyword_set(print_coord) then return, supported_coord
    
    
    if n_elements(msg) eq 0 then begin
        errmsg = handle_error('No input message ...')
        return, retval
    endif
    
    index = where(native_functions eq msg, count)
    if count ne 0 then begin
        pos = strpos(msg, 'mgse')
        pos2 = strpos(msg, 'uvw')
        if pos[0] eq -1 and pos2[0] eq -1 then begin
            return, call_function(msg, vec0, time)
        endif else begin
            return, call_function(msg, vec0, time, _extra=ex)
        endelse
    endif

    ; Use existing functions to coerce.
    coords = strsplit(msg,'2',/extract)
    case coords[0] of
        'sm': vec1 = gsm2gse(sm2gsm(vec0,time),time)
        'gsm': vec1 = gsm2gse(vec0,time)
        'gei': vec1 = gei2gse(vec0,time)
        'geo': vec1 = gei2gse(geo2gei(vec0,time),time)
        'mag': vec1 = gei2gse(geo2gei(mag2geo(vec0,time),time),time)
        'mgse': vec1 = mgse2gse(vec0,time,_extra=ex)
        'uvw': vec1 = uvw2gse(vec0,time,_extra=ex)
        'gse': vec1 = vec0
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
        'mgse': return, gse2mgse(vec1,time,_extra=ex)
        'uvw': return, gse2uvw(vec1,time,_extra=ex)
        'gse': return, vec1
        else: begin
            errmsg = handle_error('Unknown output coord: '+coords[1]+' ...')
            return, retval
            end
    endcase
end
