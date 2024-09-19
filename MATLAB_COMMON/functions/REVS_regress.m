function [b] = REVS_regress(y,X)
%REVS_regress Multiple linear regression using least squares, simular to
%the core of the MATLAB regress function.

% Check that matrix (X) and left hand side (y) have compatible dimensions
[n_rows,n_cols] = size(X);
if ~isvector(y) || numel(y) ~= n_rows
    error('Number of rows in X and y must match');
end

% Remove nan values
find_nan = (isnan(y) | any(isnan(X),2));
y(find_nan) = [];
X(find_nan,:) = [];
n_rows = length(y);

% compute QR decomposition of X
[Q,R,e] = qr(X,0);


% find dependent columns
if isempty(R)
    good_cols = 0;
elseif isvector(R)
    good_cols = double(abs(R(1))>0);
else
    good_cols = sum(abs(diag(R)) > max(n_rows,n_cols)*eps(R(1)));
end

if good_cols < n_cols
    warning('Input matrix is rank deficient');
    R = R(1:good_cols,1:good_cols);
    Q = Q(:,1:good_cols);
    e = e(1:good_cols);
end

% Preallocate with 0 for dependent columns & compute coefficients with
% backslash
b = zeros(n_cols,1);
b(e) = R \ (Q'*y);
