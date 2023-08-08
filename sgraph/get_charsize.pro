;+
; Get the default charsize in normalized coord.
;-

function get_charsize

    xchsz = double(!d.x_ch_size)/double(!d.x_size)
    ychsz = double(!d.y_ch_size)/double(!d.y_size)
    return, [xchsz,ychsz]

end