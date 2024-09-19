function val = convert_units( val, in_units, out_units,  name, baro)

% If no change do nothing.... 
if strcmp(in_units, out_units)
	return;
end

[in_unit_scale, in_unit_base] = parse_units(in_units);
[out_unit_scale, out_unit_base] = parse_units(out_units);

warn_in_units = regexprep( ['"',in_units,'"'],'^"\s*"$','empty','emptymatch');
warn_out_units = regexprep( ['"',out_units,'"'],'^"\s*"$','empty','emptymatch');

% if isempty( baro)
% 	baro = struct('press', 98, 'unit_scale', 1e3, 'unit_base', 'Pa' );
% end

is_angular = any(regexpcmp({in_units, out_units},'(CAD)|(deg(?!\s*[CFK]))','ignorecase'));
is_fully_defined = is_angular && all(regexpcmp({in_units, out_units},'(CAD|deg)\s*(A(fter\s*)?TDC|B(efore\s*)?TDC|ADV(ance)?|RET(ard)?)','ignorecase'));

if is_angular && ~is_fully_defined
	fprintf(' ! Signal %s angular measurement has indeterminate or unrecognized sign, input units are %s and output units are %s, verify output or update template\n', name, warn_in_units, warn_out_units );
	in_unit_scale = abs(in_unit_scale);
	out_unit_scale = abs(out_unit_scale);
end

if strcmp(in_unit_base,out_unit_base)	
	val = val * in_unit_scale / out_unit_scale ;
	
elseif strcmp( in_unit_base, 'degC') && strcmp( out_unit_base, 'degF')
	val = (val * in_unit_scale * 9/5 + 32) / out_unit_scale;
		
elseif strcmp( in_unit_base, 'degF') && strcmp( out_unit_base, 'degC')	
	val = ( val* in_unit_scale - 32) * 5/9 / out_unit_scale;
	
elseif strcmp( in_unit_base, 'PaA') && strcmp( out_unit_base, 'PaG')	
	if isempty(baro) 
		baro = 98000;
		fprintf(' ! Barometric pressure not defined for conversion of %s using 98 kPa as default\n', name);
	end
	
	val = (val * in_unit_scale - baro) / out_unit_scale ;
	
elseif strcmp( in_unit_base, 'PaG') && strcmp( out_unit_base, 'PaA')	
	if isempty(baro) 
		baro = 98000;
		fprintf(' ! Barometric pressure not defined for conversion of %s using 98 kPa as default\n', name);
	end
	
	val = (val * in_unit_scale + baro) / out_unit_scale ;
	
elseif any(strcmp( in_unit_base, 'Pa' )) || any(strcmp( out_unit_base, {'PaA','PaG'} ))	
	val = nan(size(val));
	fprintf(' ! Signal %s has indeterminate input pressure units %s, specify gauge or absolute\n', name, warn_in_units);
	
elseif any(strcmp( in_unit_base, {'PaA','PaG'} )) || any(strcmp( out_unit_base, 'Pa'))	
	val = nan(size(val));
	fprintf(' ! Signal %s has indeterminate output pressure units %s, specify gauge or absolute\n', name, warn_out_units);
else
	val = nan(size(val));
	fprintf(' ! Signal %s has unknown or unconvertable units, input units are %s and desired output units are %s\n', name, warn_in_units, warn_out_units );
end



end

