function out = REVS_fullfact(opts)
%REVS_fullfact full-factorial matrix generator
%   OUT = REVS_fullfact(OPTS) creates a design matrix OUT containing the
%   settings for a full factorial. The input vector opts specifies the 
%   number of options for each level in the design.
%


if ~isvector( opts ) || any( (round(opts)~= opts) | (opts < 1) )
    error('Input must be a vector of positive integers')
end

out = (1:opts(1))';

for idx = 2:length(opts)
       
    o = opts(idx);    
    
    l = repmat(out, o, 1);
    s = size( out,1);
    r = ceil( (1:(s*o))' ./ s );
    out = [l, r];
        
end


