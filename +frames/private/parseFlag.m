function [flagFound, args] = parseFlag(flag, args)
% PARSEFLAG checks whether the flag is present in the arguments passed to a
% function
%
% Input:
%   - flag (char, string)
%   - args (cell)
%
% Output
%   - flagFound (logical): true if the flag is present
%   - args (cell): The input without the flag

flagFind = find(strcmp(args, flag), 1);
flagFound = ~isempty(flagFind);
if nargout >=2, args(flagFind) = []; end
end