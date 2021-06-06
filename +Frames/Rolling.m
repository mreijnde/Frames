classdef Rolling
    properties(SetAccess=protected)
        df
        window
        windowNaN
    end
    methods
        function obj = Rolling(df,window,windowNaN)
            if nargin<3, windowNaN=ceil(window/3); end
            if ~isa(window,'double')
                assert(strcmp(window,"expanding"), 'window must be a double or the string "expanding"')
                window = size(df,1);
            end
            obj.df = df;
            obj.window = window;
            obj.windowNaN = windowNaN;
        end
        function df = mean(obj)
            df = obj.commonArgsAndNan(@movmean);
        end
        function df = std(obj)
            df = obj.commonArgsAndNan(@movstd);
        end
        function df = var(obj)
            df = obj.commonArgsAndNan(@movar);
        end
        function df = sum(obj)
            df = obj.commonArgsAndNan(@movsum);
        end
        function df = median(obj)
            df = obj.commonArgsAndNan(@movmedian);
        end
        function df = max(obj)
            df = obj.commonArgsAndNan(@movmax);
        end
        function df = min(obj)
            df = obj.commonArgsAndNan(@movmin);
        end
    end
    
    methods(Access=public)
        function frameOut = commonArgsAndNan(obj,fun)
            dataOut = fun(obj.df.data,[obj.window-1,0],'omitnan');
            dataOut(isnan(obj.df.data)) = NaN;
            dataOut = nanifyStart(dataOut,obj.windowNaN);
            frameOut = obj.df;
            frameOut.data = dataOut;
        end
        
        %possible to do it matrix style
        function [dataOut,foundNaN] = covariance(obj,data)
            foundNaN = any(isnan(data),2);
            data(foundNaN,:) = NaN;
            x = data(:,1);
            y = data(:,2);
            xy = conj(x) .* y;
            xyRolling = movsum(xy,[obj.window-1,0],'omitnan');
            xm = movmean(x,[obj.window-1,0],'omitnan');
            ym = movmean(y,[obj.window-1,0],'omitnan');
            windowNotNaN = movsum(~foundNaN,[obj.window-1,0],'omitnan');
            dataOut = (xyRolling - windowNotNaN .* xm .* ym) ./ (windowNotNaN-1);
            dataOut = nanifyStart(dataOut,obj.windowNaN);
            dataOut(foundNaN,:) = NaN;
        end
        function [dataOut,foundNaN] = covarianceM(obj,x,y)
            foundNaN = isnan(x) | isnan(y);
            x = repmat(x,1,size(y,2));
            x(foundNaN) = NaN;
            y(foundNaN) = NaN;
            xy = conj(x) .* y;
            xyRolling = movsum(xy,[obj.window-1,0],'omitnan');
            xm = movmean(x,[obj.window-1,0],'omitnan');
            ym = movmean(y,[obj.window-1,0],'omitnan');
            windowNotNaN = movsum(~foundNaN,[obj.window-1,0],'omitnan');
            dataOut = (xyRolling - windowNotNaN .* xm .* ym) ./ (windowNotNaN-1);
            dataOut = nanifyStart(dataOut,obj.windowNaN);
            dataOut(foundNaN) = NaN;
        end
        function dataOut = correlation(obj,data)
            [covariance,foundNaN] = obj.covariance(data);
            data(foundNaN,:) = NaN;
            std1 = movstd(data(:,1),[obj.window-1,0],'omitnan');
            std2 = movstd(data(:,2),[obj.window-1,0],'omitnan');
            dataOut = covariance ./ std1 ./ std2;
            dataOut = nanifyStart(dataOut,obj.windowNaN);
            dataOut(foundNaN,:) = NaN;
        end
        function dataOut = correlationM(obj,x,y)
            [covariance,foundNaN] = obj.covarianceM(x,y);
            x = repmat(x,1,size(y,2));
            x(foundNaN) = NaN;
            y(foundNaN) = NaN;
            std1 = movstd(x,[obj.window-1,0],'omitnan');
            std2 = movstd(y,[obj.window-1,0],'omitnan');
            dataOut = covariance ./ std1 ./ std2;
            dataOut = nanifyStart(dataOut,obj.windowNaN);
            dataOut(foundNaN) = NaN;
        end
        function dataOut = betaXY_(obj,data)
            [covariance,foundNaN] = obj.covariance(data);
            stdX = movvar(data(:,1),[obj.window-1,0],'omitnan');
            dataOut = covariance ./ stdX;
            dataOut = nanifyStart(dataOut,obj.windowNaN);
            dataOut(foundNaN,:) = NaN;
        end
        function dataOut = betaXY_M(obj,x,y)
            [covariance,foundNaN] = obj.covarianceM(x,y);
            x(foundNaN,:) = NaN;
            stdX = movvar(x,[obj.window-1,0],'omitnan');
            dataOut = covariance ./ stdX;
            dataOut = nanifyStart(dataOut,obj.windowNaN);
            dataOut(foundNaN,:) = NaN;
        end
    end
end

function data = nanifyStart(data,windowNaN)
ixs = findIxStartLastMissing(shift(data));
ixc = ixs + windowNaN - 1;
[t,n] = size(data);
ixc = min(ixc',1:t:n*t);
idToNaN = [];
for ii = 1:n
    idToNaN = [idToNaN,ixs(ii):ixc(ii)]; %#ok<AGROW>
end
data(idToNaN) = NaN;
end
