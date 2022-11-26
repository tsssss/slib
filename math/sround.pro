;+
; Type: function.
; Purpose: Round a number to shorter form, within certain error.
; Parameters: num0, in, number, req. The number to be treated.
; Keywords: error, in, double, opt. Default 10% error.
; Return: double. The shorter number.
; Notes: none.
; Dependence: none.
; History:
;   2015-11-09, Sheng Tian, create.
;-

function sround, num0, error = maxerr

    compile_opt idl2
    
    if num0 eq 0 then return, num0
    
    num = double(abs(num0))
    sign = num0/num
    numexp = floor(alog10(num))
    
    num1 = num*10d^(-numexp)
    
    if n_elements(maxerr) eq 0 then maxerr = 1e-2
    imax = ceil(alog10(1/maxerr))

    for i = imax,-1,-1 do begin
        tmp = 10d^i
        tnum = num1*tmp
        num2 = round(tnum*sign)*sign
        if num2 eq 0 then break
        if abs(tnum-num2)/num2 gt maxerr then break
        num1 = num2/tmp     ; update num1.
    endfor

    return, num1*sign*10d^numexp
end

print, sround(15)
print, sround(-0.5944444)
print, sround(0.99)
print, sround(0.9)
print, sround(0.8)
end
