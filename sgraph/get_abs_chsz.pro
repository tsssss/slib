;+
; Return [abs_xchsz,abs_ychsz] in inch.
;-

function get_abs_chsz

    file = join_path([srootdir(),'abs_chsz.dat'])
    if file_test(file) eq 0 then begin
        sgopen, 0, size=[1,1], xchsz=abs_xchsz, ychsz=abs_ychsz
        save, abs_xchsz, abs_ychsz, filename=file
    endif
    restore, filename=file
    return, [abs_xchsz,abs_ychsz]

end