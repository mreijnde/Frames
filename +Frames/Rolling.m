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
    
    methods(Access=protected)
        function frameOut = commonArgsAndNan(obj,fun)
            dataOut = fun(obj.df.data,[obj.window-1, 0],'omitnan');
            dataOut(isnan(obj.df.data)) = NaN;
            dataOut = nanifyStart(dataOut,obj.windowNaN);
            frameOut = obj.df;
            frameOut.data = dataOut;
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
