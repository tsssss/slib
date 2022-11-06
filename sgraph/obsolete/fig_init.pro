;+
; Init a fig.
; This is something like sgopen, but do not do the opening.
;
; id0. File name or window id.
;-
function fig_init, id0, background=bgc, color=fgc, _extra=ex


    ; Color.
    if n_elements(bgc) then bgc = sgcolor('white')
    if n_elements(fgc) then fgc = sgcolor('black')


    ; ID and device
    if n_elements(id0) eq 0 then id0 = 0    ; w-mode, window 0.
    id = id0[0]

    devw = (!version.os_family eq 'unix')? 'x': 'win'
    devp = 'ps'
    devz = 'z'
    if size(id,/type) eq 7 then begin   ; id is a string.
        path = file_dirname(id)
        base = file_basename(id)
        if file_test(path,/directory) eq 0 then file_mkdir, path
        ext = strlowcase(fgetext(base))
        case ext of
            'pdf': dev0 = devp
            'ps':  dev0 = devp
            'eps': dev0 = devp
            'png': dev0 = devz
            'jpg': dev0 = devz
            'jpeg':dev0 = devz
            else: message, 'does not support the extension '+ext+'...'
        endcase
    endif else begin        ; id is a window.
        dev0 = devw
    endelse

    ; Unit. We work in inch internally.
    unit = 'inch'
    cm2px = 40d
    inch2cm = 2.54d
    inch2px = 101.6d


    ; Basic charsize.
    ; char size, in inch.
    charsz = [9d,15]/inch2px


    ; Patch info and return.
    fig = dictionary($
        'id', id, $
        'device', dev0, $
        'unit', unit, $
        'inch2cm', inch2cm, $
        'inch2px', inch2px, $
        'xchsz', charsz[0], $   ; in inch.
        'ychsz', charsz[1], $   ; in inch.
        'regions', list(), $
        'region_geometry', ptr_new(/allocate_heap), $
        'color', fgc, $
        'background', bgc )

    fig_add_region, fig, region_init(fig, _extra=ex), _extra=ex

    return, fig

end

fig = fig_init(id0, xsize=4, ysize=3)
end
