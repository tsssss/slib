;%W% %G%
;
PRO greg_to_jdaynum,y,m,d,jd

    ; Converts a Gregorian calendar date (month, day, year)
    ; to Julian day number (number of days since 1 Jan 4713 B.C.

    ; INPUT:  
    ; y   year
    ; m   month (1-12)
    ; d   day of month (1-31)

    ; OUTPUT: 
    ; jd  Julian day number

    ; REF:  Explanatory Supplement to the Astronomical Almanac
    ;       ISBN 0-935702-68-7
    ;       University Science Books
    ;       1992
    ;       p. 604

    t1 = (1461.*(y+4800+(m-14)/12.))/4.
    t2 = (367.*(m-2-12.*((m-14)/12.)))/12.
    t3 = -(3.*((y+4900+(m-14)/12.)/100.))/4.

    jd = t1+t2+t3 + d - 32075

END
