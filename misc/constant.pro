;+
; Return commonly used constants/shortcuts/etc.
;
; name. A string for the name of the constant/shortcut.
;-

function constant, name

    retval = !null
    if n_elements(name) ne 1 then return, retval
    case name of
        'secofday': retval = 86400d
        'secofhour': retval = 3600d
        'deg': retval = 180d/!dpi
        'rad': retval = !dpi/180d
        'pi': retval = !dpi
        're': retval = 6378d
        're1': retval = 1d/6378d
        'rgb': retval = sgcolor(['red','green','blue'])
        'xyz': retval = ['x','y','z']
        'uvw': retval = ['u','v','w']
        'lineskip': retval = 0.25
        'label_size': retval = 0.7
        'full_ychsz': retval = 0.7
        'half_ychsz': retval = 0.35
        '4space': retval = '    '
        else: ; do nothing.
    endcase
    return, retval
end