;+
; Abstract properties that depends on wavelet/parameter choices.
; 
; wavlet. A string of wavelet name. 'morlet', 'paul', 'dog'.
; param. 6 for morlet, 4 for paul, 2 or 6 for dog.
; 
; c_coi. 
; dof0. Degree of freedom of the mother wavelet.
; dj0.
; gamma0.
; cdelta.
; psi0.
; s2t. A constant converts scales to periods.
; t2s. A constant converts periods to scales.
;-

function wavelet_info, wavelet, param

    if n_elements(wavelet) eq 0 then wavelet = 'morlet'
    case strlowcase(wavelet) of
        'morlet': begin
            param = 6d
            c_coi = 1d/sqrt(2d)
            dof0 = 2d
            
            dj0 = 0.6d
            gamma0 = 2.32d
            cdelta = 0.776d
            psi0 = !dpi^(-0.25)
            s2t = 4*!dpi/(param+sqrt(2+param^2))
            t2s = 1d/s2t
        end
        'paul': begin
            param = 4d
            c_coi = sqrt(2d)
            dof0 = 2d
            
            dj0 = 1.5d
            gamma0 = 1.17d
            cdelta = 1.132d
            psi0 = 1.079
            s2t = 4*!dpi/(2*param+1)
            t2s = 1d/s2t
        end
        'dog': begin
            c_coi = 1d/sqrt(2d)
            dof0 = 1d
            
            if n_elements(param) eq 0 then param = 2
            case param of
                2: begin
                    dj0 = 1.4d
                    gamma0 = 1.43d
                    cdelta = 3.541d
                    psi0 = 0.867d
                end
                4: begin
                    dj0 = 0.97d
                    gamma0 = 1.37d
                    cdelta = 1.966d
                    psi0 = 0.884d
                end
            endcase
            s2t = 2*!dpi/sqrt(param+0.5)
            t2s = 1d/s2t
        end
    endcase
        
    return, [c_coi, dof0, dj0, gamma0, cdelta, psi0, s2t, t2s]

end