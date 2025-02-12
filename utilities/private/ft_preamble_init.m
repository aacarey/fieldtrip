% FT_PREAMBLE_INIT is a helper script that is used at the start of all FieldTrip main
% functions. It checks whether the user specified at lease one input arguments (i.e.
% the cfg) or shows the help of the calling function. It checks whether the output file
% already exists and whether it is OK to overwrite it. It tracks the function call.
%
% Use as
%   ft_preamble init
%
% See also FT_TRACKUSAGE

% Copyright (C) 2011-2012, Robert Oostenveld, DCCN
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

% disabled for now, see further down
global ft_default

% this script requires some options that can be user-specified, but otherwise are obtained from ft_default
cfg = mergeconfig(cfg, keepfields(ft_default, {'outpuitfile', 'outputfilepresent'}));

if nargin==0
  stack = dbstack('-completenames');
  % stack(1) is this script
  % stack(2) is the calling ft_postamble function
  % stack(3) is the main FieldTrip function that we are interested in
  stack = stack(3);
  help(stack.name);
  % throw the error as if it happened in the original function
  msg.message     = 'This function requires one or multiple input arguments, please refer to the documentation above';
  msg.identifier  = '';
  msg.stack       = stack;
  error(msg);
end % if nargin

% determine whether function execution should be aborted or continued
if isfield(cfg, 'outputfile') && ~isempty(cfg.outputfile)
  assert(any(strcmp(fieldnames(cfg), 'outputfilepresent')), 'cfg.outputfilepresent is a required option, please see FT_DEFAULTS');
  % check whether the output file already exists
  [p, f, x] = fileparts(cfg.outputfile);
  if isempty(p)
    % the relative path was speciield
    outputfile = fullfile(pwd, cfg.outputfile);
  else
    % the absolute path was specified
    outputfile = cfg.outputfile;
  end
  if ~exist(outputfile, 'file')
    abort = false;
  else
    % the output file exists, determine how to deal with it
    switch cfg.outputfilepresent
      case 'keep'
        if nargout>0
          % continue executing the parent function
          warning('output file %s is already present, but you also requested an output argument: continuing function execution', cfg.outputfile);
          abort = false;
        else
          % stop executing the parent function
          warning('output file %s is already present: aborting function execution', cfg.outputfile);
          abort = true;
        end
      case 'overwrite'
        warning('output file %s is already present: it will be overwritten', cfg.outputfile);
        abort = false;
      case 'error'
        error('output file %s is already present', cfg.outputfile);
      otherwise
        error('invalid option for cfg.outputfilepresent');
    end % case
  end
else
  % there is no reason to abort execution
  abort = false;
end % if outputfile

if false
  % this is currently generating too much data and therefore disabled
  if isfield(ft_default, 'trackusage') && ~(isequal(ft_default.trackusage, false) || isequal(ft_default.trackusage, 'no') || isequal(ft_default.trackusage, 'off'))
    % track the usage of the calling function
    stack = dbstack('-completenames');
    % stack(1) is this script
    % stack(2) is the calling ft_postamble function
    % stack(3) is the main FieldTrip function that we are interested in
    ft_trackusage('function call', 'function', stack(3).name);
  end % if trackusage
end
