classdef singletonTest < matlab.unittest.TestCase
    
    methods(Test)
        
        function indexConstructorTest(t)
            function cantSingleton1, frames.Index([1 2],Singleton=true); end
            function cantSingleton2, frames.Index([NaN 1],Singleton=true); end
            function cantSingleton3, frames.Index([NaN NaN],Singleton=true); end
            
            t.verifyEqual(frames.Index(NaN,Singleton=true).value,NaN)
            t.verifyEqual(frames.Index({''},Singleton=true).value,{''})

            t.verifyEqual(frames.TimeIndex(NaT,Singleton=true),frames.TimeIndex(nan,Singleton=true))
        end
        
        function indexSetterTest(t)
            i1 = frames.Index([1 2]);
            t.verifyError(@badmissing1,"frames:validators:mustBeFullVector")
            function badmissing1, i1(2) = NaN; end
            t.verifyError(@badmissing2,"frames:validators:mustBeFullVector")
            function badmissing2, i1.value(2) = NaN; end
            i1.value = double.empty(1,0);
            t.verifyEqual(i1.value,double.empty(0,1))
            
            ti1 = frames.TimeIndex(NaN,Singleton=true);
            ti2 = frames.TimeIndex(NaT,Singleton=true,Format='dd-MMM-yyyy');
            ti3 = frames.TimeIndex(string(missing),Singleton=true);
            t.verifyEqual(ti1,ti2)
            t.verifyEqual(ti3,ti2)
            
            i2 = frames.Index(NaN,Singleton=true);
            i2.value = NaT;
            t.verifyEqual(i2.value,NaT)
            i2.value = string(missing);
            t.verifyEqual(i2.value,string(missing))
            t.verifyError(@badvalsingleton1,"frames:Index:valueChecker:singleton")
            function badvalsingleton1, i2.value(1) = 1; end
            t.verifyError(@badvalsingleton2,"frames:Index:asgnNotSortedsingleton")
            function badvalsingleton2, i2(1) = ""; end
        end

%             frames.DataFrame(1,nan,RowSeries=true)
%             frames.DataFrame(1,1,RowSeries=true)
%             s = frames.DataFrame(1,ColSeries=true)
%             s = frames.DataFrame(1,[],frames.Index("w"),ColSeries=true)
%             s = frames.DataFrame(1,[],frames.Index("w",Singleton=true),ColSeries=true)
%             s = frames.DataFrame(1,[],frames.Index(string(missing),Singleton=true),ColSeries=true)
% 
%             id = frames.Index([3 4])
%             id.value = []
%             id = frames.Index(NaN,Singleton=true)
%             id.value = NaT
%             id.value = 1
%             id.value = []
    end
end
