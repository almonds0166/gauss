
% gif.m, mlandry@mit.edu for help
%
% GIF   Appends a frame to a .gif file using the current figure handle.
%
%     GIF(FILE) Appends the current figure window to the .gif file FILE as a
%     frame. If FILE does not exist, then it is created. If there is no current
%     figure handle open, an error occurs.
%
%     GIF(..., 'frame', H) uses the handle H instead of the default of current
%     figure handle gcf.
%
%     GIF(..., 'delay', T) specifies how long your new frame will display before
%     moving on to the next frame, in milliseconds. Default is 200.
%
%     GIF(..., 'loops', N) specifies the loop-count the .gif has when viewed.
%     Default is inf. This only works when adding the first frame, ie, the file
%     does not yet exist.
%
%     GIF(..., 'nodither') maps each color in the original image to the closest
%     color in the new map with no dithering performed. Dithering potentially
%     achieves better color resolution at the expense of spatial resolution.
%
%     See also: IMWRITE, RGB2IND.
function gif(FILE, varargin)
    narginchk(1, inf)
    if ~strcmpi(FILE((end - 4 + 1):end), '.gif'); FILE = [FILE '.gif']; end
    o = struct('delay', 200, 'loops', inf);
    o = cog(o, varargin, {'delay', 'loops', 'frame'}, {'debug', 'nodither'});
    if ~isfield(o, 'frame'); o.frame = gcf; end
    
    f = getframe(o.frame);
    if o.nodither; d = 'nodither'; else; d = 'dither'; end
    [i, C] = rgb2ind(f.cdata, 256, d);
    if ~(exist(FILE, 'file') == 2)
        debugout('File seems not to exist.')
        debugout('Creating file ''', FILE, ''' ... ');
        imwrite(i, C, FILE, 'gif', ...
            'LoopCount', o.loops, 'DelayTime', o.delay / 1000);
        debugout('\bdone')
    else
        debugout('File exists.')
        debugout('Appending frame to file ''', FILE, ''' ... ')
        imwrite(i, C, FILE, 'gif', ...
            'WriteMode', 'append', 'DelayTime', o.delay / 1000);
        debugout('\bdone')
    end
    
    function debugout(varargin)
        if o.debug
            fprintf([varargin{:} '\n']);
        end
    end
end