classdef indexTest < AbstractFramesTests
    
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
            
            a = frames.TimeIndex(seconds(1):seconds(1):minutes(1));
            t.verifyEqual(length(a),60)
            t.verifyEqual(a.format,"duration")
            t.verifyError(@() frames.TimeIndex([seconds(1),seconds(1),minutes(1)]), ...
                'frames:Index:requireUniqueFail')
            
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
            
            a = frames.TimeIndex(seconds(1):seconds(2):minutes(1));
            t.verifyEqual(a.positionOf(seconds([3 5])),[2 3]')
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
            
            a = frames.TimeIndex(seconds(1):seconds(2):seconds(4));
            t.verifyEqual(a.positionIn(seconds([5 1 3]),false),[false true true]')
            
            a = frames.TimeIndex(seconds(1):seconds(2):seconds(4),Unique=false);
            t.verifyEqual(a.positionIn(seconds([5 1 3])),[2 3]')
        end

        function ismemberTest(t)
            index = frames.TimeIndex([30000 100000 200000]);
            date = 100000;
            dateM = datetime(date,"ConvertFrom",'datenum');
            index2 = frames.TimeIndex(date);
            t.verifyTrue(index.ismember(date))
            t.verifyTrue(index.ismember(dateM))
            t.verifyTrue(index.ismember(index2))
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
  
            durationindex = frames.TimeIndex(minutes([10 20 30]));
            t.verifyEqual(durationindex.union(minutes([2 2 30])).getValue_(),minutes([2 10 20 30]'))
        end
        
        function assignmentTest(t)
            index = frames.Index([30 10 20]);
            uniqueindex = frames.Index([30 10 20],Unique=true);
            sortedindex = frames.Index([10 20 30],UniqueSorted=true);
            timeindex = frames.TimeIndex([10 20 30]);
            durationindex = frames.TimeIndex(minutes([10 20 30]));
            
            t.verifyWarning(@renderDupl,'frames:Index:subsagnNotUnique')
            function renderDupl, index.value(end+1:end+2) = [11 20]; end
            t.verifyEqual(index.value, [30 10 20 11 20]')
            
            t.verifyError(@notUnique,'frames:Index:requireUniqueFail')
            function notUnique, uniqueindex.value(1) = 10; end
            uniqueindex.value(1:2) = [10 11]';
            t.verifyEqual(uniqueindex.value, [10 11 20]')
            uniqueindex.value(end+1) = 33;
            t.verifyEqual(uniqueindex.value, [10 11 20 33]')
            t.verifyError(@notUnique2,'frames:Index:requireUniqueFail')
            function notUnique2, uniqueindex.value(1) = 33; end
            
            t.verifyError(@notSorted,'frames:Index:requireSortedFail')
            function notSorted, sortedindex.value(2) = 100; end
            sortedindex.value(end:end+1) = [40 50];
            t.verifyEqual(sortedindex.value, [10 20 40 50]')
            sortedindex.value([1 3]) = [1 22];
            t.verifyEqual(sortedindex.value, [1 20 22 50]')
            t.verifyError(@notSorted2,'frames:Index:requireUniqueFail')
            function notSorted2, sortedindex.value(1) = 50; end
            t.verifyError(@notSorted3,'frames:Index:requireSortedFail')
            function notSorted3, sortedindex.value(1) = 33; end
            
            timeindex.value([2 3]) = ["16-Aug-2021" "17-Aug-2021"];
            timeindex2 = timeindex;
            timeindex2.value(end) = 738385;
            t.verifyEqual(timeindex.value, timeindex2.value)
            
            t.verifyError(@tiNotSorted,'frames:Index:requireSortedFail')
            function tiNotSorted, timeindex.value([3 2]) = ["16-Aug-2021" "17-Aug-2021"]; end
            
            t.verifyError(@tidNotSorted,'frames:Index:requireSortedFail')
            function tidNotSorted, durationindex.value([3 2]) = hours([2 3]); end
        end
        
        function cellForTimeForbidden(t)
            t.verifyError(@() frames.TimeIndex({'02.11.2021'}),'TimeIndex:cellstrnotsupported')
            t.verifyError(@() frames.TimeFrame(1,{"02.11.2021"}),'frames:TimeFrame:rowsObjNotTime') %#ok<STRSCALR> 
            %       ^^-- 'cellstr not supported check' not working in combination with MultiIndex {} syntax. 
            %       In this case a MultiIndex is created with given string, and fails TimeIndex class check 
            tf = frames.TimeFrame(1);
            t.verifyError(@() asgnCell,'TimeIndex:cellstrnotsupported')
            function asgnCell, tf.rows = {'02.11.2021'}; end
            df = frames.DataFrame(1);
            t.verifyWarningFree(@() asgnCellDF)
            function asgnCellDF, df.rows = {'02.11.2021'}; end
        end
    end
end
