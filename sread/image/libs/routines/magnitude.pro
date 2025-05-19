FUNCTION Magnitude, x, y, z

;Check argument
IF N_Params() NE 3 THEN Message, "Please input a 3-dimension vector!"
IF ~((N_Elements(x) EQ N_Elements(y)) && (N_Elements(x) EQ N_Elements(y))) THEN $
	Message, "x, y, z should have same number of elements!"

Return, Sqrt(x * x + y * y + z * z)

END