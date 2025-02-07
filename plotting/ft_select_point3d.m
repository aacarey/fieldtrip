function [selected] = ft_select_point3d(bnd, varargin)

% FT_SELECT_POINT3D helper function for selecting one or multiple points on a 3D mesh
% using the mouse. It returns a list of the [x y z] coordinates of the selected
% points.
%
% Use as
%   [selected] = ft_select_point3d(bnd, ...)
%
% Optional input arguments should come in key-value pairs and can include
%   'multiple'   = true/false, make multiple selections, pressing "q" on the keyboard finalizes the selection (default = false)
%   'nearest'    = true/false (default = true)
%
% Example
%   [pnt, tri] = icosahedron162;
%   bnd.pnt = pnt;
%   bnd.tri = tri;
%   ft_plot_mesh(bnd)
%   camlight
%   ... do something here

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

% get optional input arguments
nearest  = ft_getopt(varargin, 'nearest',  true);
multiple = ft_getopt(varargin, 'multiple', false);

% ensure that it is boolean
nearest  = istrue(nearest);
multiple = istrue(multiple);

% get the object handles
h = get(gca, 'children');

% select the correct objects
iscorrect = false(size(h));
for i=1:length(h)
  try
    pnt = get(h(i),'vertices');
    tri = get(h(i),'faces');
    if ~isempty(bnd) && isequal(bnd.pnt, pnt) && isequal(bnd.tri, tri)
      % it is the same object that the user has plotted before
      iscorrect(i) = true;
    elseif isempty(bnd)
      % assume that it is the same object that the user has plotted before
      iscorrect(i) = true;
    end
  end
end
h = h(iscorrect);

if isempty(h) && ~isempty(bnd)
  figure
  ft_plot_mesh(bnd);
  camlight
  selected = ft_select_point3d(bnd, varargin{:});
  return
end

if length(h)>1
  warning('using the first patch object in the figure');
  h = h(1);
end

selected = zeros(0,3);

done = false;
while ~done
  k = waitforbuttonpress;
  [p v vi facev facei] = select3d(h);
  key = get(gcf,'CurrentCharacter'); % which key was pressed (if any)?
  
  if strcmp(key, 'q')
    % finished selecting points
    done = true;
  else
    % a new point was selected
    if nearest
      selected(end+1,:) = v;
    else
      selected(end+1,:) = p;
    end % if nearest
    fprintf('selected point at [%f %f %f]\n', selected(end,1), selected(end,2), selected(end,3));
  end
  
  if ~multiple
    done = true;
  end
end

