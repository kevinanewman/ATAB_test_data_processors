function [ answer ] = was_provided( var )
% function [ answer ] = was_provided( var )
%   used in data classes to see if property was ever provided
%   returns true if var is not empty and has non-NaN values
%    var = var(:);

    answer = ~isempty(var) && ~all(isnan(var));
    
end

