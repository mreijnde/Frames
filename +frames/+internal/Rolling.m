classdef Rolling
    % Provide rolling window calculations
    %
    % Rolling methods:
    %   mean    - rolling moving mean
    %   std     - rolling standard deviation
    %   var     - rolling variance
    %   sum     - rolling sum
    %   median  - rolling median
    %   max     - rolling max
    %   min     - rolling min
    %   cov     - rolling univariate covariance with a series
    %   corr    - rolling univariate correlation with a series
    %   betaXY  - rolling univariate beta of/with a series
    %
    % Constructor:
    % Rolling(df,window[,windowNaN])
    %   window:    (integer, or the string "expanding")
    %       Window on which to compute the rolling method
    %   windowNaN: (integer), default ceil(window/3)
    %       Minimum number of observations at the start required to have a value (otherwise result is NaN).
    %
    % Copyright 2021 Benjamin Gaudin
    %
    properties(SetAccess=protected)
        df
        window
        windowNaN
    end
    methods
        function obj = Rolling(df,window,windowNaN)
            % Rolling(df,window[,windowNaN])
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
            % rolling mean
            df = obj.commonArgsAndNan(@movmean);
        end
        function df = std(obj)
            % rolling std
            df = obj.commonArgsAndNan(@movstd);
        end
        function df = var(obj)
            % rolling var
            df = obj.commonArgsAndNan(@movar);
        end
        function df = sum(obj)
            % rolling sum
            df = obj.commonArgsAndNan(@movsum);
        end
        function df = median(obj)
            % rolling median
            df = obj.commonArgsAndNan(@movmedian);
        end
        function df = max(obj)
            % rolling max
            df = obj.commonArgsAndNan(@movmax);
        end
        function df = min(obj)
            % rolling min
            df = obj.commonArgsAndNan(@movmin);
        end
        
        function df = cov(obj,series)
            % rolling univariate covariance with a series
            assert(frames.internal.areAligned(obj.df,series),'frames are not aligned')
            df = obj.df;
            df.data = obj.covarianceM(series.data,obj.df.data);
        end
        function df = corr(obj,series)
            % rolling univariate correlation with a series
            assert(frames.internal.areAligned(obj.df,series),'frames are not aligned')
            df = obj.df;
            df.data = obj.correlationM(series.data,obj.df.data);
        end
        function df = betaXY(obj,dfOrSeries)
            % univariate beta of dfOrSeries being Y (the dependant variable) on obj.df being X (the independent variable)
            assert(frames.internal.areAligned(obj.df,dfOrSeries),'frames are not aligned')
            if size(obj.df,2) == 1
                df = dfOrSeries;
            elseif size(dfOrSeries,2) == 1
                df = obj.df;
            else
                error('One of the frames must be a series.')
            end
            df.data = obj.betaXY_M(obj.df.data,dfOrSeries.data);
        end
    end
    
    methods(Access=protected)
        function frameOut = commonArgsAndNan(obj,fun)
            dataOut = fun(obj.df.data,[obj.window-1,0],'omitnan');
            dataOut(isnan(obj.df.data)) = NaN;
            dataOut = nanifyStart(dataOut,obj.windowNaN);
            frameOut = obj.df;
            frameOut.data = dataOut;
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

        function dataOut = correlationM(obj,x,y)
            [covariance,foundNaN] = obj.covarianceM(x,y);
            x = repmat(x,1,size(y,2));
            x(foundNaN) = NaN;
            y(foundNaN) = NaN;
            std1 = movstd(x,[obj.window-1,0],'omitnan');
            std2 = movstd(y,[obj.window-1,0],'omitnan');
            dataOut = covariance ./ std1 ./ std2;
        end

        function dataOut = betaXY_M(obj,x,y)
            if size(x,2) == 1
                [covariance,foundNaN] = obj.covarianceM(x,y);
                x = repmat(x,1,size(y,2));
            else
                [covariance,foundNaN] = obj.covarianceM(y,x);
            end
            x(foundNaN) = NaN;
            varX = movvar(x,[obj.window-1,0],'omitnan');
            dataOut = covariance ./ varX;
        end
    end
end

function data = nanifyStart(data,windowNaN)
ixs = frames.internal.findIxStartLastMissing(frames.internal.shift(data));
ixc = ixs + windowNaN - 1;
[t,n] = size(data);
ixc = min(ixc',t:t:n*t);
idToNaN = [];
for ii = 1:n
    idToNaN = [idToNaN,ixs(ii):ixc(ii)]; %#ok<AGROW>
end
data(idToNaN) = NaN;
end
