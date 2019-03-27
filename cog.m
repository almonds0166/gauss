
% cog.m, mlandry@mit.edu for help
%
% COG   Structure intended for fostering your creation of amazing functions.
%
%     O = COG(DEFAULT, ARGS, FIELDS, FLAGS) parses the cell array ARGS and,
%     assuming ARGS is acceptable input, returns the structure O with the
%     fieldnames contained in cell arrays FIELDS and FLAGS. "Flags" are simply
%     fields that take a boolean value.
%
%     If ARGS does not contain a flag, it's value in the returned structure is
%     logical 0. IF ARGS and DEFAULT do not contain a field in FIELDS, the
%     structure will not bear the field name at all.
%
%     All four arguments are necessary. COG reads ARGS in a case-insensitive
%     manner.
%
%     Examples:
%
%      >> COG(struct, {'Color', 'red', 'Jump'}, {'Color'}, {'Jump', 'Write'})
%         ans = 
%           struct with fields:
%
%              Jump: 1
%             Write: 0
%             Color: 'red'
%
%      >> COG(struct, {'Write', 'Color'}, {'Color'}, {'Jump', 'Write'})
%         Error using COG (line 56)
%         The property 'Color' was given no associated value. 
%
%      >> COG(struct, {'color', 'red', 'hello'}, {'Color'}, {'Jump', 'Write'})
%         Error using COG (line 68)
%         Expected no 'hello' property here. 
%
%     See also: VARARGIN, NARGINCHK, NARGIN, STRUCT.
function o = cog(default, args, fields, flags)
    o = default;
    assert(nargin == 4, ...
        ['Expected 4 arguments, encountered ' num2str(nargin) '.'])
    for i = 1:numel(flags)
        assert(~any(strcmpi(fields, flags{i})), ['The property ''' ...
            flags{i} ''' cannot be both a field and a flag.'])
    end
    
    for f = 1:numel(flags)
        if ~isfield(o, flags{f})
            o.(flags{f}) = false;
        end
    end
    
    i = 1;
    while i <= numel(args)
        j = find(strcmpi(fields, args{i}), 1, 'first');
        if ~isempty(j)
            assert(i + 1 <= numel(args), ['The property ''' fields{j} '''' ...
                ' was given no associated value.'])
            o.(fields{j}) = args{i + 1};
            i = i + 2;
            continue
        end
        j = find(strcmpi(flags, args{i}), 1, 'first');
        if ~isempty(j)
            o.(flags{j}) = true;
            i = i + 1;
            continue
        end
        error(['Expected no ''' args{i} ''' property here.'])
    end
end
