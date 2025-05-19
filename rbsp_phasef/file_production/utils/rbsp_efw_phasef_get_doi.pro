
function rbsp_efw_phasef_get_doi, probe=probe

    dois = dictionary( $
        'a', 'https://doi.org/10.48322/4k9n-gs06', $
        'b', 'https://doi.org/10.48322/p4ze-4247' )
    return, dois[probe]

end

probe = 'a'
print, rbsp_efw_phasef_get_doi(probe=probe)
end