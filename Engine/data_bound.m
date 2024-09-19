function [bound_in_idx] = data_bound(x,y,alpha)

[unique_pts, unique_in_idx] = unique( [x(:), y(:)],'rows');


shp = alphaShape(unique_pts);

crit_alpha = shp.criticalAlpha('one-region');
shp.Alpha = max( crit_alpha, alpha);

bound_idx  = shp.boundaryFacets();
bound_idx = bound_idx(:,1);
bound_idx(end+1) = bound_idx(1);

bound_in_idx = unique_in_idx(bound_idx);



	

