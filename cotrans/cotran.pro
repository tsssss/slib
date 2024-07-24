

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
    native_function0 = [$
    ;---mission specific
        ; THEMIS.
        'themis_smc2themis_spg', 'themis_spg2themis_smc', $
        'themis_spg2themis_ssl', 'themis_ssl2themis_spg', $
        'themis_ssl2themis_dsl', 'themis_dsl2themis_ssl', $
        ; RBSP.
        'rbsp_uvw2gse', 'rbsp_gse2uvw', $
        'rbsp_mgse2gse', 'rbsp_gse2mgse', $
        'rbsp_uvw2mgse', 'rbsp_mgse2uvw', $
    ;---General
        'gei2geo','geo2gei', $
        'gei2gse','gse2gei', $
        'geo2aacgm', 'aacgm2geo', $
        'geo2mag','mag2geo', $
        'gse2gsm','gsm2gse', $
        'gsm2sm','sm2gsm', $
        'mgse2gse','gse2mgse', $    ; These are rbsp specific, needs to be updated.
        'uvw2gse','gse2uvw']
    native_functions = 'ct_'+native_function0
        
    supported_coord = strsplit(native_function0,'2',/extract)
    supported_coord = supported_coord.toarray()
    supported_coord = supported_coord[*]
    supported_coord = suniq(supported_coord)
    if keyword_set(print_coord) then return, supported_coord
    
    
    if n_elements(msg) eq 0 then begin
        errmsg = handle_error('No input message ...')
        return, retval
    endif
    
    routine = 'ct_'+msg
    index = where(native_functions eq routine, count)
    if count ne 0 then begin
        pos = strpos(msg, 'mgse')
        pos2 = strpos(msg, 'uvw')
        if pos[0] eq -1 and pos2[0] eq -1 then begin
            return, call_function(routine, vec0, time)
        endif else begin
            return, call_function(routine, vec0, time, _extra=ex)
        endelse
    endif

    ; Use existing functions to coerce.
    coords = strsplit(msg,'2',/extract)
    case coords[0] of
        'sm': vec1 = ct_gsm2gse(ct_sm2gsm(vec0,time),time)
        'gsm': vec1 = ct_gsm2gse(vec0,time)
        'gei': vec1 = ct_gei2gse(vec0,time)
        'geo': vec1 = ct_gei2gse(ct_geo2gei(vec0,time),time)
        'mag': vec1 = ct_gei2gse(ct_geo2gei(ct_mag2geo(vec0,time),time),time)
        'mgse': vec1 = mgse2gse(vec0,time,_extra=ex)
        'uvw': vec1 = uvw2gse(vec0,time,_extra=ex)
        'gse': vec1 = vec0
        else: begin
            errmsg = handle_error('Unknown input coord: '+coords[0]+' ...')
            return, retval
            end
    endcase

    case coords[1] of
        'sm': return, ct_gsm2sm(ct_gse2gsm(vec1,time),time)
        'gsm': return, ct_gse2gsm(vec1,time)
        'gei': return, ct_gse2gei(vec1,time)
        'geo': return, ct_gei2geo(ct_gse2gei(vec1,time),time)
        'mag': return, ct_geo2mag(ct_gei2geo(ct_gse2gei(vec1,time),time),time)
        'mgse': return, gse2mgse(vec1,time,_extra=ex)
        'uvw': return, gse2uvw(vec1,time,_extra=ex)
        'gse': return, vec1
        else: begin
            errmsg = handle_error('Unknown output coord: '+coords[1]+' ...')
            return, retval
            end
    endcase
end
