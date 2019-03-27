
% IIF   Inline conditional if-statement
%
%     R = IIF(TEST, IFTRUE, IFFALSE) returns IFTRUE if TEST is logically true
%     and IFFALSE if TEST is logically false. IIF works with vectors and
%     matrices as well.
%
%     See also: IF.
function result = iif(test, iftrue, iffalse)
    if isscalar(test) 
        if test 
            result = iftrue;
        else
            result = iffalse;
        end
    else
        result = (test) .* iftrue + (~test) .* iffalse;
    end  
end
