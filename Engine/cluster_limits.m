function [outX, outY] = cluster_limits(inX,inY,option)
%option = 0: return upper limits
%option = 1: return lower limits
%tmazer did this.

%sort
[inX, i]=sort(inX);
inY = inY(i);

%Find where x values jump to another cluster
diffX = diff(inX);
jump_loc = diffX > 15;

%store indecies of jumps
jump_loc = [0; find(jump_loc); length(inX)];

%initialize output
outX = zeros(length(jump_loc)-1,1);
outY = outX;


for i = 1:length(jump_loc)-1
    
    %get data of cluster
    clusterX = inX(jump_loc(i)+1:jump_loc(i+1));
    clusterY = inY(jump_loc(i)+1:jump_loc(i+1));
    
    %get y limit of this cluster
    if option == 0
        outY(i) = max(clusterY);
    else
        outY(i) = min(clusterY);
    end
    
    %get x value of this cluster
    outX(i) = mean(clusterX);
end


    
%lower limit shouldn't change much. delete any outliers
if option == 1
    i = [true;diff(diff(outY)) > -15;true]; % points of peaks
    outY = outY(i);
    outX = outX(i);
end

%plot(outX,outY);
%hold on;
%scatter(inX,inY,'.');

end

