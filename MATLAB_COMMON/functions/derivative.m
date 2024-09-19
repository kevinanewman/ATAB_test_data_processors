function [answer] = derivative(vector, mode)
%function [answer] = derivative(vector, mode)
% if mode == 1
%     answer = [answer(1) answer];
% elseif mode == 2
%     answer = [0 answer];
% end

answer = diff(vector);

if (mode ~= 2) mode = 1;
end

if size(vector,1) == 1
    if mode == 1
        answer = [answer(1) answer];
    elseif mode == 2
        answer = [0 answer];
    end
else
    if mode == 1
        answer = [answer(1); answer];
    elseif mode == 2
        answer = [0; answer];
    end
end
