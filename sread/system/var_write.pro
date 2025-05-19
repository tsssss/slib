;+
; Write var to a file.
;
; vars. These vars will depend on the same time_var.
; filename=.
; time_var=. Give the time_var a name.
; istp=. Set to follow ISTP convention.
;-

function var_write, vars, filename=file, time_var=time_var, istp=istp

    stplot2cdf, vars, time_var=time_var, istp=istp, filename=file

end