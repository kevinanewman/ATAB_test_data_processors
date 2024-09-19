function  out = template_parser( parse , in, sheet)
%TEMPLATE_PARSER Summary of this function goes here
%   Detailed explanation goes here

headers = in(1,:);

out = struct('idx', num2cell( (1:(size(in,1)-1))'));


for p = 1:numel(parse)

	idx = strcmpi( parse(p).header, headers);
	out_var = parse(p).out_var;
	
	if ~any( idx) && parse(p).required
		error('Template %s input is missing "%s" column', sheet, parse(p).header);
	elseif ~any( idx) && strcmpi(parse(p).type,'text')
		warning('Template %s input is missing "%s" column, defaulting to blank', sheet, parse(p).header);
		[out.(out_var)] = deal('');
	elseif ~any( idx) && strcmpi(parse(p).type,'numeric')
		warning('Template %s input is missing "%s" column, defaulting to blank', sheet, parse(p).header);
		[out.(out_var)] = deal(nan);
	elseif ~any( idx) && strcmpi(parse(p).type,'bool')
		warning('Template %s input is missing "%s" column, defaulting to blank', sheet, parse(p).header);
		[out.(out_var)] = deal(false);	
	elseif strcmpi(parse(p).type,'numeric')
		col = in( 2:end, idx);
		is_txt = cellfun('isclass',col,'char');
		col(is_txt) = {nan};
		[out.(out_var)] = col{:};
	elseif strcmpi(parse(p).type,'bool')
		col = in( 2:end, idx);
		out_col = cell(size(col));
		out_col(:) = {false};
		is_num = find(cellfun(@isnumeric,col)); 
		is_nan = cellfun( @isnan, col(is_num));
		is_num = is_num( ~is_nan);
		out_col(is_num) = cellfun( @logical, col(is_num) );	
		is_txt = find(cellfun('isclass',col,'char'));
		out_col(is_txt) = num2cell(regexpcmp(col(is_txt),'(Y(es)?)|(T(rue)?)|(VAL)|(X)','ignorecase')) ;
		[out.(out_var)] = out_col{:};
	else % text
		col = in( 2:end, idx);
		out_col = cell(size(col));
		out_col(:) = {''};
		is_txt = cellfun('isclass',col,'char');
		out_col(is_txt) = col(is_txt);
		is_num = find(cellfun(@isnumeric,col)); 
		is_nan = cellfun( @isnan, col(is_num));
		is_num = is_num( ~is_nan);
		out_col(is_num) = cellfun( @num2str, col(is_num), 'UniformOutput', false );		
		[out.(out_var)] = out_col{:};
	end
	
end

end