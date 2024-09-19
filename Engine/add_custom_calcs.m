function data = add_custom_calcs( data, calcs )

for idx = 1:numel(calcs)
	 
	out_signal = calcs(idx).output_signal;
	expression = calcs(idx).expression;
	
    if isempty(out_signal) && isempty(expression)
        % Blank Line - Skip
        continue;
    end
    
	possible_vars = regexp(expression, '[A-Za-z]\w*','match');
	match = istablevar( data, possible_vars );
	
	vars = possible_vars(match);
	expression = replace( expression, vars, strcat('data.',vars));
	
	
	try
		temp = eval( expression  );
	catch ex
		fprintf(' ! Error evaluating custom calculation %d for %s - %s\n', idx, out_signal, ex.message);
		continue;
	end
		
	
	if ~isvector(temp)
		fprintf(' ! Error evaluating custom calculation %d for %s - Result was not a vector\n', idx, out_signal);
		continue;
	end
	
	
	try
		data.(out_signal) = temp;
	catch ex
		fprintf(' ! Error evaluating custom calculation %d for %s - %s\n', idx, out_signal, ex.message);
		continue;
	end
	
	
	
end


end