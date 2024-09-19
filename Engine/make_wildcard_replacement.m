function RepStr = make_wildcard_replacement( Instr )

    match_cnt = 1;
    RepStr = Instr;
    temp = '';
    
    while ~all(strcmp( RepStr, temp))
        temp = 	RepStr;
        RepStr = regexprep( RepStr, '\*',sprintf('$%d',match_cnt),'once');
        match_cnt = match_cnt+1;
    end
    
end