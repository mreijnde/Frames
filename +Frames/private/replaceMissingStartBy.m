function mat = replaceMissingStartBy(mat,val)
ix = findIxStartLastMissing(mat);
% do not replace if ix is the last element of a columns
[xi,xc] = size(mat);
eoi = xi:xi:xi*xc;
ix = ix(~ismember(ix,eoi));
mat(ix) = val;
end