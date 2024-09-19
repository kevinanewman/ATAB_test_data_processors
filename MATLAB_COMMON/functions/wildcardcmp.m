function match = wildcardcmp( str, expression, varargin)
%WILDCARDCMP 
% Compare string via wildcard expression. Similar to strcmp except the comparison utilizes wildcard characters (* and ?).

expression = regexptranslate('wildcard', expression );

if ischar( str ) && ischar( expression)
	match = ~isempty(regexp(str, expression,'once',varargin{:}));
else
	
	if ~iscell( str)
		str = {str};
	end
	
	if ~iscell( expression)
		expression = {expression};
	end
	
	if numel(str) == 1 && numel( expression) > 1
		str = repmat(str,size(expression));
	end
		
	if numel(expression) == 1 && numel( str) > 1
		expression = repmat(expression,size(str));
	end
			
	match = ~cellfun(@isempty, regexp(str, expression,'once',varargin{:})) ;

end

end
