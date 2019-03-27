% Low values are brightest
% High values are darkest
function color = cop(pH, low, high)
    if nargin == 1; low = min(pH); high = max(pH); end
    
    res = 200;
    
    pal = flipud(copper(res));
    
    color = zeros(numel(pH), 3);
    for x = 1:numel(pH)
        u = (pH(x) - low) / (high - low);
        u = round((res - 1) * u + 1);
        u = min(u, res);
        u = max(u, 1);
        color(x, :) = pal(u, :);
    end
end