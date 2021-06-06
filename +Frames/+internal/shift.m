function s = shift(x,lag) 
    if nargin == 1
        lag = 1;
    end
    xIsRow = false;
    if isrow(x)
        xIsRow = true;
        x = x';
    end

    s = repmat(frames.internal.missingData(class(x)),size(x,1),size(x,2));
    if lag > 0
            s(lag+1:end,:) = x(1:end-lag,:);
    elseif lag < 0
            s(1:end+lag,:) = x(-lag+1:end,:);
    else
        s = x;
    end
    if xIsRow
        s = s';
    end
end