
% redblue.m
%
% Usage: REDBLUE(pH)
%
% Returns a color matrix given a vector of pHs where red is acidic and blue is
% basic, just like in the textbooks. Specifically:
%
% pH = 2 is pure red, pH = 12 is pure blue
% pH < 2 is dark red, pH > 12 is dark blue
% pH < 0.4  is considered to be pH = 0.4 and
% pH > 13.6 is considered to be pH = 13.6
%
% Intended for use in plotting. If pH is a vector of length m, then REDBLUE(pH)
% returns an m-by-3 matrix.

function color = redblue(pH)
    res = 200;
    
    pal = flipud(jet(res));
    red = find(pal(:, 1) == 1, 1, 'first');
    blue = find(pal(:, 3) == 1, 1, 'last');
    
    color = zeros(numel(pH), 3);
    for x = 1:numel(pH)
        u = (pH(x) - 2) / (12 - 2);
        u = round((blue - red) * u + red);
        u = min(u, res);
        u = max(u, 1);
        color(x, :) = pal(u, :);
    end
end