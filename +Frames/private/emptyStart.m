function data = emptyStart(data,window)
startCols = findColumnStart(data);
[~,endNanify] = getElementIDShift(startCols,size(data,1),size(data,2),window-1);
el2nan = [];
for ii = 1:length(startCols)
    el2nan = [el2nan, startCols(ii):endNanify(ii)]; %#ok<AGROW>
end
data(el2nan) = missingData(class(data));
end