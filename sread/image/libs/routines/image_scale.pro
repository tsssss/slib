FUNCTION IMAGE_Scale, image

;level 1: count less than 0
;exception
level1 = Where(image LT 0, n_pixels)
IF n_pixels GT 0 THEN image[level1] = 0

;level 2: count between 0 - 500
;background
level2 = Where(image GE 0 AND image LT 500, n_pixels)
IF n_pixels GT 0 THEN image[level2] = BytScl(image[level2], Top = 5)

;level 3: count between 500 - 2500
;faint aurora
level3 = Where(image GE 500 AND image LT 2500, n_pixels)
IF n_pixels GT 0 THEN image[level3] = BytScl(image[level3], Top = 180) + 5

;level 4: count between 2500 - 4000
;light aurora
level4 = Where(image GE 2500 AND image LT 4000, n_pixels)
IF n_pixels GT 0 THEN image[level4] = BytScl(image[level4], Top = 45) + 185


;level 5: count between 4000 - 10000
;extremely light aurora
level5 = Where(image GE 4000 AND image LT 10000, n_pixels)
IF n_pixels GT 0 THEN image[level5] = BytScl(image[level5], Top = 25) + 230

;level 6: count greater than 10000
;too large
level6 = Where(image GT 1000, n_pixels)
IF n_pixels GT 0 THEN image[level6] = 255

Return, image

END