;+
; Return the absolute path of home directory for current user.
; trailing_slash=. A boolean. Set it to add a trailing slash.
;-
function homedir, trailing_slash=trailing_slash

    case !version.os_family of
        'unix'      : homedir = getenv('HOME')
        'Windows'   : homedir = getenv('UserProfile')
        else        : message, 'unknown OS ...'
    endcase

    if !version.os_family eq 'Windows' then $
        homedir = strjoin(strsplit(homedir,'\',/extract),'/')

    if keyword_set(trailing_slash) then homedir+= '/'
    return, homedir

end


print, homedir()
end
