function varargout = align(varargin)
%ALIGN align frames to each others and ouputs each of them aligned
%
% wrapper for DataFrame.alignDFs(), see there for more information
varargout= cell(1,nargout);
[varargout{:}] = alignDFs(varargin{:});

