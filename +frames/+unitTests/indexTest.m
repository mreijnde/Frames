classdef indexTest < matlab.unittest.TestCase
    
    methods(Test)
        function constructorTest(t)
            t.verifyWarning(@duplicate,'frames:Index:notUnique')
            function duplicate(), frames.Index([2 2]); end
            
            t.verifyError(@badsorted,'frames:Index:requireSortedFail')
            function badsorted(), frames.Index([3 2],UniqueSorted=true); end
            
            t.verifyError(@duplicateError,'frames:Index:requireUniqueFail')
            function duplicateError(), frames.Index([2 2],Unique=true); end
            
            timeindex = frames.TimeIndex("24*06*2021",Format="dd*MM*yyyy");
            t.verifyEqual(timeindex.getValue_(),738331)
            t.verifyEqual(timeindex.name,"Time")

            a = frames.TimeFrame(1,["22.05.2021","20.06.2021"]);
            b = frames.TimeFrame(1,["22-May-2021","20-Jun-2021"]);
            c = frames.TimeFrame(1,["5/22/2021","6/20/2021"]);
            t.verifyEqual(a,b)
            t.verifyEqual(a,c)
            
        end
        
        function indexGetterTest(t)
            timeindex = frames.TimeIndex("24*06*2021",Format="dd*MM*yyyy");
            t.verifyEqual(timeindex.value,datetime("24*06*2021",Format="dd*MM*yyyy"))
        end
        
        function positionOfTest(t)
            warning('off','frames:Index:notUnique')
            index = frames.Index([30 10 20 30]);
            uniqueindex = frames.Index([30 10 20],Unique=true);
            
            t.verifyEqual(index.positionOf([30,20]),[1 4 3]')
            t.verifyEqual(uniqueindex.positionOf([20,30]),[3 1]')
            warning('off','frames:Index:notUnique')
        end
        
        function positionInTest(t)
            warning('off','frames:Index:notUnique')
            index = frames.Index([30 10 20 30]);
            uniqueindex = frames.Index([30 10 20],Unique=true);
            sortedindex = frames.Index([10 20 30],UniqueSorted=true);
            
            t.verifyError(@indexNotWhole,'frames:assertFoundIn')
            function indexNotWhole(), index.positionIn([40,30,20]); end
            
            t.verifyEqual(index.positionIn([40,50,30,20,10]),[3 5 4 3]')
            t.verifyEqual(uniqueindex.positionIn([40,50,30,20,10]),[3 5 4]')
            t.verifyEqual(sortedindex.positionIn([10,20,30,40,50]),[true true true false false]')
            t.verifyEqual(sortedindex.positionIn([10,20,30,40,50]),[true true true false false]')
            warning('on','frames:Index:notUnique')
        end
        
        function unionTest(t)
            index = frames.Index([30 10 20]);
            uniqueindex = frames.Index([30 10 20],Unique=true);
            sortedindex = frames.Index([10 20 30],UniqueSorted=true);
            timeindex = frames.TimeIndex([10 20 30]);
            
            t.verifyWarning(@duplicate,'frames:Index:notUnique')
            function duplicate(), index.union([2 2 30]); end
            warning('off','frames:Index:notUnique')
            t.verifyEqual(index.union([2 2 30]).value,[30 10 20 2 2 30]')
            warning('on','frames:Index:notUnique')
            t.verifyEqual(uniqueindex.union([2 2 30]).value,[30 10 20 2]')
            t.verifyEqual(sortedindex.union([2 2 30]).value,[2 10 20 30]')
            t.verifyEqual(timeindex.union([2 2 30]).getValue_(),[2 10 20 30]')
  
        end
        
        function assignmentTest(t)
            index = frames.Index([30 10 20]);
            uniqueindex = frames.Index([30 10 20],Unique=true);
            sortedindex = frames.Index([10 20 30],UniqueSorted=true);
            timeindex = frames.TimeIndex([10 20 30]);
            
            t.verifyWarning(@renderDupl,'frames:Index:notUnique')
            function renderDupl, index(end+1:end+2) = [11 20]; end
            t.verifyEqual(index.value, [30 10 20 11 20]')
            
            t.verifyError(@notUnique,'frames:Index:asgnNotUnique')
            function notUnique, uniqueindex(1) = 10; end
            uniqueindex(1:2) = [10 11]';
            t.verifyEqual(uniqueindex.value, [10 11 20]')

            t.verifyError(@notSorted,'frames:Index:asgnNotSorted')
            function notSorted, sortedindex(2) = 100; end
            sortedindex(end:end+1) = [40 50];
            t.verifyEqual(sortedindex.value, [10 20 40 50]')
        end
    end
end