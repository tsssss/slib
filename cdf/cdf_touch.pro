;+
; Create an empty cdf file.
;-

pro cdf_touch, cdf0, _extra=ex

    cdfid = cdf_create(cdf0, _extra=ex)
    cdf_close, cdfid

end
