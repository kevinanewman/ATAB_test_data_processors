function [lineseries] = plothg(varargin)

lineseries = superplot(varargin{:});

hold on

grid on

% Autolabeling
if length(lineseries) == 1 && isnumeric(varargin{1}) && isnumeric(varargin{2})
	% Single line x vs y
	
	xlabel(inputname(1),'Interpreter','none');
	ylabel(inputname(2),'Interpreter','none');
	
elseif length(lineseries) == 1 && isnumeric(varargin{1})
	% Single line y vs ticks
	
	ylabel(inputname(1),'Interpreter','none');
	xlabel('ticks')
	
else
	% Multiline
	
	if isnumeric(varargin{1}) && isnumeric(varargin{2})
		x_name = inputname(1);
	else
		x_name = 'ticks';
	end
	
	l = 1;	
	legend_str = {};
	while l < length(varargin)
	
		if isnumeric(varargin{l}) &&  isnumeric(varargin{l+1})
			legend_str{end+1} = inputname(l+1);
			if ~strcmp( x_name, inputname(l) )
				x_name = '';
			end
			l = l+2;
		elseif 	isnumeric(varargin{l})
			legend_str{end+1} = inputname(l);
			if ~strcmp( x_name, 'ticks' )
				x_name = '';
			end
			l = l+1;
		else
			l = l+1;
		end
		
	end
	
	legend(legend_str,'Interpreter','none');
	xlabel(x_name,'Interpreter','none');
	
end