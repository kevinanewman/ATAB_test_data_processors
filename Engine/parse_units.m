function [unit_scale, unit_base] = parse_units(in)
%converts 'in' to a char array which can be used with convert.
%any units that should not be converted set 'out' to empty
%note that these assignments will not effect the string used for units in
%the final report

% No Units - Bail
if isempty(in) || all( in == '-') || any(strcmpi( strtrim(in), {'Count'  'Counts' 'Enent' 'Events','#'}))	
	unit_base = '';
	unit_scale = 1;
else
	
	
	[unit_parts, unit_join] = strsplit( in, {'*','/'});
	
	unit_base = '';
	unit_scale = 1;
	
	
	for u = 1:length(unit_parts)
		
		
		[unit_part_scale{u}, unit_part_base{u}] = parse_units_part( unit_parts{u});
		
		if isempty(unit_part_base{u})
			unit_scale = unit_scale * unit_part_scale{u};
		elseif u <= 1
			unit_base = [unit_base, unit_part_base{u}];
			unit_scale = unit_scale * unit_part_scale{u};
		elseif 	unit_join{u-1} == '*'
			unit_base = [unit_base, '*', unit_part_base{u}];
			unit_scale = unit_scale * unit_part_scale{u};
		else
			unit_base = [unit_base, '/', unit_part_base{u}];
			unit_scale = unit_scale / unit_part_scale{u};
		end
		
	end
end

end



function [unit_scale, unit_base] = parse_units_part( in_units)

unit_list       = struct('in_str',{{'C'  '°C' 'degC'}},					'search_type', 'basic', 'prefix',  false,	'out_base', 'degC',		'out_scale', 1);
unit_list(end+1)= struct('in_str',{{'F'  '°F' 'degF'}},					'search_type', 'basic', 'prefix',  false,	'out_base', 'degF',		'out_scale', 1);

% Complex (Common coupled Units )
unit_list(end+1)= struct('in_str','N(-)?m',								'search_type', 'regex',	'prefix',  true,	'out_base', 'N*m',		'out_scale', 1);
unit_list(end+1)= struct('in_str','ft(-)?lb(s)?',						'search_type', 'regex',	'prefix',  false,	'out_base', 'N*m',		'out_scale', 1.355818);

unit_list(end+1)= struct('in_str','W(-)?h(r)?' ,						'search_type', 'regex',	'prefix',  true,	'out_base', 'J',		'out_scale', 1/3600);
unit_list(end+1)= struct('in_str','W(-)?s(ec)?' ,						'search_type', 'regex',	'prefix',  true,	'out_base', 'J',		'out_scale', 1);
unit_list(end+1)= struct('in_str',{{'J','Joule'}},						'search_type', 'basic', 'prefix',  true,	'out_base', 'J',		'out_scale', 1);

% Base Units
unit_list(end+1)= struct('in_str',{{'radps' }},							'search_type', 'basic', 'prefix',  false,	'out_base', 'rad/sec',	'out_scale', 1);
unit_list(end+1)= struct('in_str',{{'rpm' }},							'search_type', 'basic', 'prefix',  false,	'out_base', 'rad/sec',	'out_scale', 2*pi/60);

unit_list(end+1)= struct('in_str',{{'rad', 'radians' }},				'search_type', 'basic', 'prefix',  false,	'out_base', 'rad',		'out_scale',1);
unit_list(end+1)= struct('in_str',{{'rev' }},							'search_type', 'basic', 'prefix',  false,	'out_base', 'rad',		'out_scale', 2*pi);

unit_list(end+1)= struct('in_str',{{'mps' }},							'search_type', 'basic', 'prefix',  true,	'out_base', 'm/sec',	'out_scale', 1);
unit_list(end+1)= struct('in_str',{{'kph' , 'kmh'}},					'search_type', 'basic', 'prefix',  false,	'out_base', 'm/sec',	'out_scale', 1000/3600);
unit_list(end+1)= struct('in_str',{{'mph' }},							'search_type', 'basic', 'prefix',  false,	'out_base', 'm/sec',	'out_scale', 1609.344 / 3600);

unit_list(end+1)= struct('in_str',{{'norm'}},							'search_type', 'basic', 'prefix',  false,	'out_base', '',			'out_scale', 1);
unit_list(end+1)= struct('in_str',{{'Pct', '%', 'pct'}},				'search_type', 'basic', 'prefix',  false,	'out_base', '',			'out_scale', 1e-2);
unit_list(end+1)= struct('in_str',{{'ppm'}},							'search_type', 'basic', 'prefix',  false,	'out_base', '',			'out_scale', 1e-6);

unit_list(end+1)= struct('in_str',{{'g'  'gram'}},						'search_type', 'basic', 'prefix',  true,	'out_base', 'g',		'out_scale', 1);
unit_list(end+1)= struct('in_str',{{'lbm'  'lb' 'pound'}},				'search_type', 'basic', 'prefix',  false,	'out_base', 'g',		'out_scale', 453.592);
unit_list(end+1)= struct('in_str',{{'ton' }},							'search_type', 'basic', 'prefix',  false,	'out_base', 'g',		'out_scale', 2000 * 453.592);

unit_list(end+1)= struct('in_str',{{'s'  'second' 'sec'}},				'search_type', 'basic', 'prefix',  true,	'out_base', 'sec',		'out_scale', 1);
unit_list(end+1)= struct('in_str',{{'min'  'minute'}},					'search_type', 'basic', 'prefix',  false,	'out_base', 'sec',		'out_scale', 60);
unit_list(end+1)= struct('in_str',{{'h'  'hour' 'hr'}},					'search_type', 'basic', 'prefix',  false,	'out_base', 'sec',		'out_scale', 3600);

unit_list(end+1)= struct('in_str',{{'m'  'meter' 'mtr'}},				'search_type', 'basic', 'prefix',  true,	'out_base', 'm',		'out_scale', 1);
unit_list(end+1)= struct('in_str',{{'in'  'inch'}},						'search_type', 'basic', 'prefix',  false,	'out_base', 'm',		'out_scale', 2.54e-02);
unit_list(end+1)= struct('in_str',{{'ft'  'foot'}},						'search_type', 'basic', 'prefix',  false,	'out_base', 'm',		'out_scale', 12 * 2.54e-02);
unit_list(end+1)= struct('in_str',{{'mi'  'mile'}},						'search_type', 'basic', 'prefix',  false,	'out_base', 'm',		'out_scale', 5280 * 12 * 2.54e-02);

unit_list(end+1)= struct('in_str',{{'N'  'Newton' }},					'search_type', 'basic', 'prefix',  true,	'out_base', 'N',		'out_scale', 1);
unit_list(end+1)= struct('in_str',{{'lbf' }},							'search_type', 'basic', 'prefix',  false,	'out_base', 'N',		'out_scale', 1 / 0.224808943);

unit_list(end+1)= struct('in_str',{{'Pa', 'Pascal'}},					'search_type', 'basic', 'prefix',  true,	'out_base', 'Pa',		'out_scale', 1);
unit_list(end+1)= struct('in_str',{{'PaA'}},							'search_type', 'basic', 'prefix',  true,	'out_base', 'PaA',		'out_scale', 1);
unit_list(end+1)= struct('in_str',{{'PaG'}},							'search_type', 'basic', 'prefix',  true,	'out_base', 'PaG',		'out_scale', 1);

unit_list(end+1)= struct('in_str',{{'bar',  'Bar'}},					'search_type', 'basic', 'prefix',  true,	'out_base', 'Pa',		'out_scale', 1e5);
unit_list(end+1)= struct('in_str',{{'barA', 'BarA'}},					'search_type', 'basic', 'prefix',  true,	'out_base', 'PaA',		'out_scale', 1e5);
unit_list(end+1)= struct('in_str',{{'barG', 'BarG'}},					'search_type', 'basic', 'prefix',  true,	'out_base', 'PaG',		'out_scale', 1e5);
unit_list(end+1)= struct('in_str',{{'psi'}},							'search_type', 'basic', 'prefix',  false,	'out_base', 'Pa',		'out_scale', 6894.757);

unit_list(end+1)= struct('in_str',{{'gal' 'gallon'}},					'search_type', 'basic', 'prefix',  false,	'out_base', 'l',		'out_scale', 3.78541178);
unit_list(end+1)= struct('in_str',{{'cc'}},								'search_type', 'basic', 'prefix',  false,	'out_base', 'l',		'out_scale', 1e-3);
unit_list(end+1)= struct('in_str',{{'l', 'lit' 'liter'}},				'search_type', 'basic', 'prefix',  true,	'out_base', 'l',		'out_scale', 1);

unit_list(end+1)= struct('in_str','(CAD|deg)\s*RET(ard)?',				'search_type', 'regex',	'prefix',  false,	'out_base', 'deg',		'out_scale', 1);
unit_list(end+1)= struct('in_str','(CAD|deg)\s*ADV(ance)?',				'search_type', 'regex',	'prefix',  false,	'out_base', 'deg',		'out_scale', 1);
unit_list(end+1)= struct('in_str','(CAD|deg)\s*B(efore\s*)?TDC',		'search_type', 'regex',	'prefix',  false,	'out_base', 'deg',		'out_scale', 1);
unit_list(end+1)= struct('in_str','(CAD|deg)\s*A(fter\s*)?TDC',			'search_type', 'regex',	'prefix',  false,	'out_base', 'deg',		'out_scale', 1);
unit_list(end+1)= struct('in_str','(CAD|deg)',							'search_type', 'regex',	'prefix',  false,	'out_base', 'deg',		'out_scale', 1);
unit_list(end+1)= struct('in_str','(CAD|deg)\s*RET(ard)?',				'search_type', 'regex',	'prefix',  false,	'out_base', 'deg',		'out_scale', 1);

l = 1;
prefix_scale = containers.Map({'k','M','c','m','n',''},[1e3,1e6,1e-2,1e-3,1e-6,1]);
while l <= length( unit_list)
	
	if strcmpi(unit_list(l).search_type,'regex')
		unit_regex = unit_list(l).in_str;
	else
		unit_regex = strjoin(regexptranslate('escape', unit_list(l).in_str),'|');
	end
	
	if unit_list(l).prefix
		prefix_regex = '[Mkcmn]?';
	else
		prefix_regex = '';
	end
	
	
	regex = sprintf('^(%s)(%s)$', prefix_regex, unit_regex);
	
	match = regexp( in_units, regex, 'tokens');
	
	if ~isempty(match)
		unit_prefix = match{1}{1};
		unit_found = match{1}{2};
		unit_base = unit_list(l).out_base;
		unit_scale = unit_list(l).out_scale * prefix_scale( unit_prefix);
		break;
	end
		
	l = l+1;
end

if l > length( unit_list)
	unit_base = in_units;
	unit_scale = 1;
	unit_prefix = '';
end


end

% function scale = unit_prefix_scale( prefix)
% 
% 	
% 	
% 	if strcmp(prefix , 'M')
% 		scale = 1e6;
% 	elseif strcmp(prefix , 'k')
% 		scale = 1e3;
% 	elseif strcmp(prefix , 'c' )
% 		scale = 1e-2;
% 	elseif strcmp(prefix , 'm' )
% 		scale = 1e-3;
% 	elseif strcmp(prefix,'n' )
% 		scale = 1e-6;
% 	else
% 		scale=1;
% 	end
% 
% end

% function [unit_scale, unit_base] = parse_units_part( in_units)
%
%
% 	unit_base = strtrim(in_units);
% 	unit_scale = 1;
%
% 	% Trim off leading scaling
% 	if unit_base(1) == 'M'
% 		unit_base = unit_base(2:end);
% 		unit_scale = 1e6 * unit_scale;
% 	elseif unit_base(1) == 'k'
% 		unit_base = unit_base(2:end);
% 		unit_scale = 1e3* unit_scale;
% 	elseif unit_base(1) == 'c' && ~strcmpi( unit_base, 'cc' )
% 		unit_base = unit_base(2:end);
% 		unit_scale = 1e-2* unit_scale;
% 	elseif unit_base(1) == 'm' && length(unit_base) > 1
% 		unit_base = unit_base(2:end);
% 		unit_scale = 1e-3* unit_scale;
% 	end
%
% 	if endsWith(unit_base,{'Count'  'Counts' 'events','#'})
% 		unit_mod = replace(unit_base,{'Count'  'Counts' 'events','#'},'');
% 		unit_base = '';
% 		unit_scale = unit_scale * 1;
% 	elseif endsWith(unit_base,{'C'  '°C' 'degC'})
% 		unit_mod = replace(unit_base,{'C'  '°C' 'degC'},'');
% 		unit_base = 'degC';
% 		unit_scale = unit_scale * 1;
% 	elseif  endsWith(unit_base,{'F'  '°F' 'degF'})
% 		unit_mod = replace(unit_base,{'F'  '°F' 'degF'},'');
% 		unit_base = 'degF';
% 		unit_scale = unit_scale * 1;
% 	elseif  endsWith(unit_base,{'PaA', 'PaG'})
% 		unit_mod = replace(unit_base,{'PaA', 'PaG'},'');
% 		unit_base = 'Pa';
% 	elseif  endsWith(unit_base,{'barA', 'barG', 'BarA', 'BarG'})
%
% 		unit_base = 'Pa';
% 		unit_scale = unit_scale * 1e5;
% 	elseif  endsWith(unit_base,{'psi'})
%
% 		unit_base = 'Pa';
% 		unit_scale = unit_scale * 6894.757;
% 	elseif  any(strcmpi(unit_base,{'norm'}))
%
% 		unit_base = '';
% 		unit_scale = unit_scale * 1;
% 	elseif  any(strcmpi(unit_base,{'Pct', '%'}))
%
% 		unit_base = '';
% 		unit_scale = unit_scale * 1e-2;
% 	elseif  any(strcmpi(unit_base,{'mtr'}))
%
% 		unit_base = 'm';
% 	elseif  any(strcmpi(unit_base,{'in'}))
%
% 		unit_base = 'm';
% 		unit_scale = unit_scale * 2.54e-02;
% 	elseif  any(strcmpi(unit_base,{'ft'}))
% 		unit_base = 'm';
% 		unit_scale = unit_scale * 12 * 2.54e-02;
% 	elseif  any(strcmpi(unit_base,{'mi'}))
% 		unit_base = 'm';
% 		unit_scale = unit_scale * 1609.344;
% 	elseif  any(strcmp(unit_base,{'sec', 's'}))
% 		unit_base = 'sec';
% 	elseif  any(strcmp(unit_base,{'min', 'minute'}))
% 		unit_base = 'sec';
% 		unit_scale = unit_scale * 60;
% 	elseif  any(strcmp(unit_base,{'hr', 'h', 'hour'}))
% 		unit_base = 'sec';
% 		unit_scale = unit_scale * 3600;
% 	elseif  any(strcmp(unit_base,{'lbf'}))
% 		unit_base = 'N';
% 		unit_scale = unit_scale * 1 / 0.224808943;
% 	elseif  any(strcmp(unit_base,{'lb','lbs','lbm'}))
% 		unit_base = 'g';
% 		unit_scale = unit_scale * 453.592;
% 	elseif  any(strcmp(unit_base,{'ton'}))
% 		unit_base = 'g';
% 		unit_scale = unit_scale * 2000 * 453.592;
% 	elseif  any(strcmp(unit_base,{'Nm'}))
% 		unit_base = 'N*m';
% 	elseif  any(strcmp(unit_base,{'ftlb','ftlbs'}))
% 		unit_base = 'N*m';
% 		unit_scale = unit_scale * 1.355818;
% 	elseif  any(strcmp(unit_base,{'hp'}))
% 		unit_base = 'W';
% 		unit_scale = unit_scale * 745.71;
% 	elseif  any(strcmp(unit_base,{'mph'}))
%
% 		unit_base = 'm/s';
% 		unit_scale = unit_scale * 1609.344 / 3600;
% 	elseif  any(strcmp(unit_base,{'mps'}))
% 		unit_base = 'm/s';
% 	elseif  any(strcmp(unit_base,{'lit','liter'}))
% 		unit_base = 'l';
% 	elseif  any(strcmp(unit_base,{'gal'}))
% 		unit_base = 'l';
% 		unit_scale = unit_scale * 3.78541178;
% 	elseif  any(strcmp(unit_base,{'cc'}))
% 		unit_base = 'l';
% 		unit_scale = unit_scale * 1e-3;
% 	elseif  regexpcmp(unit_base,'(CAD|deg)\s*RET(ard)?','ignorecase')
% 		unit_base = 'deg';
% 		unit_scale = unit_scale * -1;
% 	elseif  regexpcmp(unit_base,'(CAD|deg)\s*ADV(ance)?','ignorecase')
% 		unit_base = 'deg';
% 		unit_scale = unit_scale * 1;
% 	elseif  regexpcmp(unit_base,'(CAD|deg)\s*B(efore\s*)?TDC','ignorecase')
% 		unit_base = 'deg';
% 		unit_scale = unit_scale * -1;
% 	elseif  regexpcmp(unit_base,'(CAD|deg)\s*A(fter\s*)?TDC','ignorecase')
% 		unit_base = 'deg';
% 		unit_scale = unit_scale * 1;
% 	elseif  regexpcmp(unit_base,'(CAD|deg)','ignorecase')
% 		unit_base = 'deg';
% 		unit_scale = unit_scale * 1;
% 	end
% end
%
%
% [hit, unit_base, unit_scale]


