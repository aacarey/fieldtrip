function ft_plot_matrix(varargin)

% FT_PLOT_MATRIX visualizes a matrix as an image, similar to IMAGESC.
% The position, width and height can be controlled to allow multiple
% matrices (i.e. channels) to be plotted in a topographic arrangement.
%
% Use as
%   ft_plot_matrix(C, ...)
% where C is a 2 dimensional MxN matrix, or
%   ft_plot_matrix(X, Y, C, ...)
% where X and Y describe the 1xN horizontal and 1xM vertical axes
% respectively.
%
% Optional arguments should come in key-value pairs and can include
%   'clim'            = maximum and minimum color limit
%   'box'             = draw a box around the local axes, can be 'yes' or 'no'
%   'highlight'       = a logical matrix of size C, where 0 means that the corresponding values in C are highlighted according to the highlightstyle
%   'highlightstyle'  = can be 'saturation' or 'opacity'
%   'tag'             = string, the name this vector gets. All tags with the same name can be deleted in a figure, without deleting other parts of the figure.
%
% It is possible to plot the object in a local pseudo-axis (c.f. subplot), which is specfied as follows
%   'hpos'            = horizontal position of the center of the local axes
%   'vpos'            = vertical position of the center of the local axes
%   'width'           = width of the local axes
%   'height'          = height of the local axes
%   'hlim'            = horizontal scaling limits within the local axes
%   'vlim'            = vertical scaling limits within the local axes
%
% Example
%   ft_plot_matrix(randn(30,50), 'width', 1, 'height', 1, 'hpos', 0, 'vpos', 0)
%
% See also T_PLOT_VECTOR

% Copyrights (C) 2009-2011, Robert Oostenveld
%
% This file is part of FieldTrip, see http://www.ru.nl/neuroimaging/fieldtrip
% for the documentation and details.
%
%    FieldTrip is free software: you can redistribute it and/or modify
%    it under the terms of the GNU General Public License as published by
%    the Free Software Foundation, either version 3 of the License, or
%    (at your option) any later version.
%
%    FieldTrip is distributed in the hope that it will be useful,
%    but WITHOUT ANY WARRANTY; without even the implied warranty of
%    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%    GNU General Public License for more details.
%
%    You should have received a copy of the GNU General Public License
%    along with FieldTrip. If not, see <http://www.gnu.org/licenses/>.
%
% $Id$

ws = warning('on', 'MATLAB:divideByZero');

if nargin>2 && all(cellfun(@isnumeric, varargin(1:3)))
  % the function was called like imagesc(x, y, c, ...)
  hdat = varargin{1};
  vdat = varargin{2};
  cdat = varargin{3};
  varargin = varargin(4:end);
else
  % the function was called like plot(c, ...)
  cdat = varargin{1};
  vdat = 1:size(cdat,1);
  hdat = 1:size(cdat,2);
  varargin = varargin(2:end);
end

% get the optional input arguments
hpos           = ft_getopt(varargin, 'hpos');
vpos           = ft_getopt(varargin, 'vpos');
width          = ft_getopt(varargin, 'width');
height         = ft_getopt(varargin, 'height');
hlim           = ft_getopt(varargin, 'hlim');
vlim           = ft_getopt(varargin, 'vlim');
clim           = ft_getopt(varargin, 'clim');
highlight      = ft_getopt(varargin, 'highlight');
highlightstyle = ft_getopt(varargin, 'highlightstyle', 'opacity');
box            = ft_getopt(varargin, 'box',            false);
tag            = ft_getopt(varargin, 'tag',            '');
ncolors        = ft_getopt(varargin, 'ncolors',        64); % in the caller function, a colormap can be used with an aribtrary resolution, this is only relevant for the saturation based coloring

if ~isempty(highlight) && ~isequal(size(highlight), size(cdat))
  error('the dimensions of the highlight should be identical to the dimensions of the data');
end

% axis   = ft_getopt(varargin, 'axis', false);
% label  = ft_getopt(varargin, 'label'); % FIXME
% style  = ft_getopt(varargin, 'style'); % FIXME

% convert the yes/no strings into boolean values
box  = istrue(box);

if isempty(hlim)
  hlim = 'maxmin';
end

if isempty(vlim)
  vlim = 'maxmin';
end

if isempty(clim)
  clim = 'maxmin';
end

if ischar(hlim)
  switch hlim
    case 'maxmin'
      hlim = [min(hdat) max(hdat)];
    case 'maxabs'
      hlim = max(abs(hdat));
      hlim = [-hlim hlim];
    otherwise
      error('unsupported option for hlim')
  end % switch
end % if ischar

if ischar(vlim)
  switch vlim
    case 'maxmin'
      vlim = [min(vdat) max(vdat)];
    case 'maxabs'
      vlim = max(abs(vdat));
      vlim = [-vlim vlim];
    otherwise
      error('unsupported option for vlim')
  end % switch
end % if ischar

if ischar(clim)
  switch clim
    case 'maxmin'
      clim = [min(cdat(:)) max(cdat(:))];
    case 'maxabs'
      clim = max(abs(cdat(:)));
      clim = [-clim clim];
    otherwise
      error('unsupported option for clim')
  end % switch
end % if ischar

% these must be floating point values and not integers, otherwise the scaling fails
hdat = double(hdat);
vdat = double(vdat);
cdat = double(cdat);
hlim = double(hlim);
vlim = double(vlim);
clim = double(clim);

if isempty(hpos);
  hpos = (hlim(1)+hlim(2))/2;
end

if isempty(vpos);
  vpos = (vlim(1)+vlim(2))/2;
end

if isempty(width),
  width = hlim(2)-hlim(1);
  width = width * length(hdat)/(length(hdat)-1);
  autowidth = true;
else
  autowidth = false;
end

if isempty(height),
  height = vlim(2)-vlim(1);
  height = height * length(vdat)/(length(vdat)-1);
  autoheight = true;
else
  autoheight = false;
end

% hlim
% vlim

% first shift the horizontal axis to zero
hdat = hdat - (hlim(1)+hlim(2))/2;
% then scale to length 1
hdat = hdat ./ (hlim(2)-hlim(1));
% then scale to compensate for the patch size
hdat = hdat * (length(hdat)-1)/length(hdat);
% then scale to the new width
hdat = hdat .* width;
% then shift to the new horizontal position
hdat = hdat + hpos;

% first shift the vertical axis to zero
vdat = vdat - (vlim(1)+vlim(2))/2;
% then scale to length 1
vdat = vdat ./ (vlim(2)-vlim(1));
% then scale to compensate for the patch size
vdat = vdat * (length(vdat)-1)/length(vdat);
% then scale to the new width
vdat = vdat .* height;
% then shift to the new vertical position
vdat = vdat + vpos;

% the uimagesc-call needs to be here to avoid calling it several times in switch-highlight
if isempty(highlight)
  h = uimagesc(hdat, vdat, cdat, clim);
  set(h,'tag',tag);
end

% the uimagesc-call needs to be inside switch-statement, otherwise 'saturation' will cause it to be called twice
if ~isempty(highlight)
  switch highlightstyle
    case 'opacity'
      % get the same scaling for 'highlight' then what we will get for cdata
      h = uimagesc(hdat, vdat, highlight);
      highlight = get(h, 'CData');
      delete(h); % this is needed because "hold on" might have been called previously, e.g. in ft_multiplotTFR
      h = uimagesc(hdat, vdat, cdat, clim);
      set(h,'tag',tag);
      set(h,'AlphaData',highlight);
      set(h, 'AlphaDataMapping', 'scaled');
      alim([0 1]);
    
    case 'saturation'
      satmask = highlight;
      tmpcdat = cdat;
      % Transform cdat-values to have a 0-64 range, dependent on clim
      % (think of it as the data having an exact range of min=clim(1) to max=(clim2), convert this range to 0-64)
      tmpcdat = (tmpcdat + -clim(1)) * (ncolors / (-clim(1) + clim(2)));
      %tmpcdat = (tmpcdat + -min(min(tmpcdat))) * (64 / max(max((tmpcdat + -min(min(tmpcdat))))))
      % Make sure NaNs are plotted as white pixels, even when using non-integer mask values
      satmask(isnan(tmpcdat)) = 0;
      tmpcdat(isnan(tmpcdat)) = round(ncolors./2);
      % ind->rgb->hsv ||change saturation values||  hsv->rgb ->  plot
      rgbcdat = ind2rgb(uint8(floor(tmpcdat)), colormap);
      hsvcdat = rgb2hsv(rgbcdat);
      hsvcdat(:,:,2) = hsvcdat(:,:,2) .* satmask;
      rgbcdatsat = hsv2rgb(hsvcdat);
      h = imagesc(hdat, vdat, rgbcdatsat,clim);
      set(h,'tag',tag);

    case 'outline'
      % the significant voxels could be outlined with a black contour
      % plot outline
      h = uimagesc(hdat, vdat, cdat, clim);
      set(h,'tag',tag);
      [x,y] = meshgrid(hdat, vdat);
      x = interp2(x, 2); % change to 4 for round corners
      y = interp2(y, 2); % change to 4 for round corners
      contourlines = highlight==1;
      contourlines = interp2(contourlines, 2, 'nearest');  % change to 4 and remove 'nearest' for round corners
      dx = mean(diff(x(1, :))); % remove for round corners
      dy = mean(diff(y(:, 1))); % remove for round corners
      holdflag = ishold;
      hold on
      contour(x+dx/2,y+dy/2,contourlines,1,'EdgeColor',[0 0 0],'LineWidth',2);
      if ~holdflag
        hold off % revert to the previous hold state
      end
      
    otherwise
      error('unsupported highlightstyle')
  end % switch highlightstyle
end

if box
  boxposition = zeros(1,4);
  % this plots a box around the original hpos/vpos with appropriate width/height
  boxposition(1) = hpos - width/2;
  boxposition(2) = hpos + width/2;
  boxposition(3) = vpos - height/2;
  boxposition(4) = vpos + height/2;
  ft_plot_box(boxposition);
end

warning(ws); %revert to original state
