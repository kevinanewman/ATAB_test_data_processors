function [ LEGH ] = add_legend( legend_string, varargin )
% function [ LEGH ] = add_legend( legend_string )
%   adds legend_string to the current legend, if a legend does not exist
%   it is created.  Returns legend handle LEGH.
%   Supports normal legend varargs

LEGH = legend;

warning('off','MATLAB:legend:IgnoringExtraEntries')
if isempty(LEGH) || isempty(LEGH.String) || isequal(LEGH.String{1},'')
    LEGH = legend(legend_string, varargin{:} );  % first legend string
else
    LEGH = legend(unique({LEGH.String{:},legend_string},'stable'), varargin{:} ); % subsequent strings
end
warning('on','MATLAB:legend:IgnoringExtraEntries')

set(LEGH,'Interpreter','none');

end
