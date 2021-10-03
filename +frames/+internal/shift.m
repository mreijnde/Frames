function s = shift(x,lag,dim) 
    if nargin < 2
        lag = 1;
    end
    if nargin < 3
        dim = 1;
    end
    if dim == 2
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
    if dim == 2
        s = s';
    end
end
