;+
; Return IDL style string corresponds to latex style input.
;
; input. A string of latex style, e.g., alpha, beta, etc. Case sensitive.
;-

function tex2str, input

    output = ''
    if n_elements(input) eq 0 then return, output

    case input of
    ;---Control letters.
        'enter': output = string(10b)+string(13b)
        'tab': output = string(5b)
    ;---Greek letters.
        'alpha': output = '!9'+string(97b)+'!X'
        'beta': output = '!9'+string(98b)+'!X'
        'gamma': output = '!9'+string(103b)+'!X'
        'delta': output = '!9'+string(100b)+'!X'
        'Delta': output = '!9'+string(68b)+'!X'
        'phi': output = '!9'+string(102b)+'!X'
        'varphi': output = '!9'+string(106b)+'!X'
        'mu': output = '!9'+string(109b)+'!X'
        'pi': output = '!9'+string(112b)+'!X'
        'theta': output = '!9'+string(113b)+'!X'
        'omega': output = '!9'+string(119b)+'!X'
        'Omega': output = '!9'+string(87b)+'!X'
        'Gamma': output = '!9'+string(71b)+'!X'
        'sigma': output = '!9'+string(115b)+'!X'
        'Sigma': output = '!9'+string(83b)+'!X'
        'tau': output = '!9'+string(116b)+'!X'
        'rho': output = '!9'+string(114b)+'!X'
    ;---Math symbols.
        'perp': output = '!9'+string(94b)+'!X'
        'parallel': output = '||'
        'deg': output = '!9'+string(176b)+'!X'
        'times': output = '!9'+string(180b)+'!X'
        'sim': output = '!9'+string(126b)+'!X'
        'int': output = '!9'+string(242b)+'!X'
        'pm': output = '!9'+string(177b)+'!X'
        else: message, 'Does not support '+input+' yet ...'
    endcase

    return, output

end
