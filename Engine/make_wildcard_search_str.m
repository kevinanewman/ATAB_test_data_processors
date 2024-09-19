function rexexpstr = make_wildcard_search_str( instr )

rexexpstr = strcat( '^',strrep(regexptranslate('wildcard',instr),'.*','(.+)'),'$');