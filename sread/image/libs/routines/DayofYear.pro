FUNCTION DayofYear, year, month, day

;Check Arguments
IF N_Elements(year) EQ 0 THEN Return, -1
IF N_Elements(month) EQ 0 THEN Return, -1
IF N_Elements(day) EQ 0 THEN Return, -1
IF year LT 0 THEN Message, "Year should greater than 0!"
IF (month LE 0 || month GT 12) THEN Message, "Month should between 1 and 12!"

;Set day of each month
day_of_month = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

;Check for leap year and change the day of Feb.
is_leap_year = ((year MOD 4) EQ 0) && ((year MOD 100) NE 0) || ((year MOD 400) EQ 0)
day_of_month[1] = day_of_month[1] + is_leap_year

;Check if day is valid
IF (day LE 0 || day GT day_of_month[month - 1]) THEN $
	Message, "Day should between 1 and " + String(day_of_month[month - 1], FORMAT = "(I2)") + "!"

;Calculate day of year
day_of_year = 0
FOR i = 0, month - 2 DO BEGIN
	day_of_year = day_of_year + day_of_month[i]
ENDFOR
day_of_year = day_of_year + day

Return, day_of_year

END