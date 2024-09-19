function [stable_bool, var_filt] = stable_check( var, time, thresh )

WinBckLen =     ceil(0.22*length(time)/time(end));    %0.22 seconds
WinFwdLen =     ceil(0.03*length(time)/time(end));    %0.03 seconds
% Slow = movmean(Var, [WinLen, 0]);
var_filt = movmean(var, [WinBckLen, WinFwdLen]);
Deriv = [diff(var_filt) ./ repmat(diff(time), 1, size(var_filt,2))];
Deriv(end+1,:) = 0;

% Stable = (abs(Var - Slow) < DeltaLimit) & (abs(Deriv) <  SlopeLimit);

stable_bool = abs(Deriv) < thresh;

for j = 1:(WinBckLen*.75)
	stable_bool(1:end-1) =  stable_bool(2:end) | stable_bool(1:end-1);
end

stable_bool = stable_bool & abs(var - var_filt ) <  2.5 * thresh;


end


