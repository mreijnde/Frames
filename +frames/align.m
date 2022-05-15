function varargout = align(varargin)
%ALIGN align frames to each others and ouputs each of them aligned
%
% wrapper for DataFrame.align(), see there for more information
varargout= cell(1,nargout);
[varargout{:}] = align(varargin{:}); % call DataFrame align method

