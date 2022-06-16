function [v,ind, ind_rev] = mergeSort(v1,v2, sorted)
% MERGESORT merges two sorted array together as a single sorted array
%             
% INPUT:
%    v1,v2:  arrays to merge and sort
%    sorted: boolean, defines if input arrays are sorted, default false
%            (~2-5 times faster when already sorted)
%            no check performed if input array v1 and v2 are indeed sorted
% OUTPUT:
%   v:       sorted concatenated array
%   ind:     position indexes from original concatenated array [v1,v2] to sorted array
%   ind_rev  position indexes from sorted array to concatenated array [v1,v2]
%
% Copyright 2022 Merijn Reijnders

if nargin<3, sorted=false; end
output_ind_rev = (nargout>2);

% get output length
L1 = length(v1);
L2 = length(v2);
L = L1+L2;

% output orientation same as input
rowvec = isrow(v1);
if rowvec
    vsize = [1,L];
else
    vsize = [L,1];
end

if ~sorted || ~isnumeric(v1) % builtin sort faster for strings
    % use builtin sort method        
    if rowvec        
        v_combined = [v1,v2];
    else
        v_combined = [v1;v2];
    end
    [v,ind] = sort(v_combined);
    if output_ind_rev
        % create reverse index
        L = length(v);        
        ind_rev = zeros(vsize);    
        ind_rev(ind) = 1:L;
    end
    return
end

% init new arrays
v = repmat(v1(1),vsize(1), vsize(2)); % keep original datatype
ind = nan(vsize);
if output_ind_rev
    ind_rev = nan(vsize);
end

% step through both arrays together and fill new sorted arrays step by step
i = 1;
ind1 = 1;
ind2 = 1;
while i<L+1   
   if ind1<=L1 && (ind2>L2 || v1(ind1)<=v2(ind2) )
       v(i)=v1(ind1);
       ind(i) = ind1;
       if output_ind_rev, ind_rev(ind1) = i; end
       ind1 = ind1+1;                     
   else
       v(i)=v2(ind2);
       ind(i) = ind2+L1;
       if output_ind_rev, ind_rev(ind2+L1) = i; end
       ind2 = ind2+1;       
   end
   i=i+1;
end 
end