function [spd, data_out] = gen_avg_curve( spd_in, data_in, step, win)

spd = (100:step:(max(spd_in)+step))';


data_in = data_in(:,vartype('numeric'));

data_out = data_in([],:);
% data_out = data_out([],:);
data_out{1:length(spd),:} = nan;

empty_row = true(size(spd));
	
for i = 1:length(spd)	
	
	pts = abs(spd_in - spd(i)) < win ;
	
	if any( pts)
		empty_row(i) = false;
		data_out{i,:}	= mean( data_in{pts,:}, 1);
	end
end

data_out( empty_row,:) = [];
spd(empty_row) = [];

end

