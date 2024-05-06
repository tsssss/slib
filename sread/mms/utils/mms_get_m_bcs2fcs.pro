function mms_get_m_bcs2fcs

    
    ; c.f. mms_feeps_pitch_angles.pro.
    ; transpose b/c in idl array row coloumn are tranposed.
    return, transpose([$
        [1./sqrt(2.),-1./sqrt(2.), 0], $
        [1./sqrt(2.), 1./sqrt(2.), 0], $
        [0, 0, 1]])
    ; Tbot = [$
    ;    [-1./sqrt(2.),-1./sqrt(2.), 0], $
    ;    [-1./sqrt(2.), 1./sqrt(2.), 0],
    ;    [0, 0, -1]]

end