classdef dataframeMultiIndexTest < AbstractFramesTests
    
    properties
        dfNoMissing;
        df2NoMissing;
        df3NoMissing;
        dfMissing1;        
        df2Missing1;
        df3Missing1;
        tfMissing1;
        dataPath = string(fileparts(mfilename('fullpath')))
        tol = 1e-10;
    end
    
    methods
        function obj = dataframeMultiIndexTest()
            frames.DataFrame.restoreDefaultSettings();
            % create dataframe properties in constructor to turn off warning            
            obj.dfNoMissing  = frames.DataFrame([1 2 3; 2 5 3;5 1 1]', {[6 2 1]}, [4 1 3]);
            obj.df2NoMissing = frames.DataFrame([1 2 3; 2 5 3;5 1 1]', {[6 2 1], ['a','c','a']}, [4 1 3]);
            obj.df3NoMissing = frames.DataFrame([1 2 3; 2 5 3;5 1 1]', {[6 2 1], ['a','c','a'], [11 22 11]}, [4 1 3]);
            obj.dfMissing1  = frames.DataFrame([1 2 3 3 2 1; 2 5 NaN 1 3 2;5 0 1 1 3 2]',{1:6});        
            obj.df2Missing1 = frames.DataFrame([1 2 3 3 2 1; 2 5 NaN 1 3 2;5 0 1 1 3 2]',{1:6,["a","b","a","a","b","a"]});
            obj.df3Missing1 = frames.DataFrame([1 2 3 3 2 1; 2 5 NaN 1 3 2;5 0 1 1 3 2]',{1:6,["a","b","a","a","b","a"],[11 11 11 22 11 11]});
            obj.tfMissing1 = frames.TimeFrame([1 2 3 3 2 1; 2 5 NaN 1 3 2;5 0 1 1 3 2]',[],{["a","b","c"]});            
        end
        
    end
    
    methods(Test)
        
        function constructorTest(t)
                        
            % 1D CHECKS
            
            % empty, check type
            emptyDF = frames.DataFrame([], {datetime.empty(0,1)});
            t.verifyTrue(isdatetime(emptyDF.rows(:,"dim1")))  % need to specify dimension name
            t.verifyTrue(isdatetime(emptyDF.rows(:,1)))       % or dimension index to access array data
            t.verifyTrue(isa(emptyDF.getRowsObj(),'frames.MultiIndex'))            
            
            % from unique data
            t.verifyEqual(frames.DataFrame(1,{[1 2]}).data,[1;1])
            
            % from empty data
            t.verifyEqual(frames.DataFrame([],{[1 2]},1).data,[NaN;NaN])
            t.verifyEqual(frames.DataFrame([],{[1 2]}).data,double.empty(2,0))
            
            % from empty rows
            t.verifyEqual(frames.DataFrame([1;2],{[]}).rows(:,1),[1;2])
            t.verifyEqual(frames.DataFrame([1;2],{}).rows(:,"dim1"),[1;2])
                                    
            % from file (TODO: add support for saving MultiIndex DataFrame)                        
            t.verifyError(@() t.df3Missing1.toFile('h.txt'), 'frames:DataFrame:toFile:MultiIndexNotSupported');
            
            % 2D CHECKS
            
            % 1d cell array with linear indexes
            warning('off','frames:Index:notUnique');
            df1 = frames.DataFrame([1;2;3;4], {[1 1 1 2], frames.Index([1 2 3 1]), ["a" "a" "b" "b"]} );
            warning('on','frames:Index:notUnique');
            % 2d cell array with values
            df2 = frames.DataFrame([1;2;3;4], {1,1,"a";1,2,"a";1,3,"b";2,1,"b"} );               
            t.verifyEqual(df2,df1)
            % nested  cell array with values
            df3 = frames.DataFrame([1;2;3;4], {{1,1,"a"},{1,2,"a"},{1,3,"b"},{2,1,"b"}} );
            t.verifyEqual(df3,df1)
            % array of Index objects
            warning('off','frames:Index:notUnique');
            IndexObjArray = [ frames.Index([1 1 1 2]), frames.Index([1 2 3 1]), frames.Index(["a" "a" "b" "b"]) ]; 
            warning('on','frames:Index:notUnique');
            df4 = frames.DataFrame([1;2;3;4], frames.MultiIndex(IndexObjArray,Unique=true) );
            t.verifyEqual(df4,df1)
            df5 = frames.DataFrame([1;2;3;4], IndexObjArray );
            t.verifyEqual(df5,df1)
            
            % with only timeindex                        
            df = frames.DataFrame((1:3)', {frames.TimeIndex(1001:1003)});
            t.verifyTrue(isdatetime(df.rows(:,1)))
            t.verifyTrue(isa(df.getRowsObj().value_{1},'frames.TimeIndex') )
            
            % with multiple index types  
            df = frames.DataFrame((1:3), [], {["a" "b" "c"], frames.TimeIndex(1001:1003), [11 22 22]});
            t.verifyTrue(isstring(df.columns(:,1)))
            t.verifyTrue(isdatetime(df.columns(:,2)))
            t.verifyTrue(isnumeric(df.columns(:,3)))
            t.verifyTrue(isa(df.getColumnsObj().value_{2},'frames.TimeIndex') )
            
            % check non-unique error
            t.verifyError(@() frames.DataFrame([1;2;3], {{1,"a"},{1,"b"},{1,"a"}}), 'frames:MultiIndex:requireUniqueFail');
            
            % DIM NAME CHECKS        
            dat = magic(3);
            %with index obj indices
            df = frames.DataFrame(dat, [], rowDim="x", colDim="y");   
            t.verifyEqual(df.getRowsObj().name, "x");
            t.verifyEqual(df.getColumnsObj().name, "y");
            t.verifyError(@() frames.DataFrame(dat, [],rowDim=["x","y"]),'frames:Index:setname:invalidcount')
            t.verifyError(@() frames.DataFrame(dat, [],colDim=["x","y"]),'frames:Index:setname:invalidcount')
            
            %with MultiIndex obj indices
            df = frames.DataFrame(dat, {[]}, {[]}, rowDim="x", colDim="y");   
            t.verifyEqual(df.getRowsObj().name, "x");
            t.verifyEqual(df.getColumnsObj().name, "y");             
        end   
            
        function constructorTest_forceMultiIndex(t)    
            % constructor checks with forceMultiIndex enabled            
            frames.DataFrame.setDefaultSetting("forceMultiIndex", true); 
            dat = magic(3);
            
            % 1d MultiIndex indices
            df1 = frames.DataFrame(magic(3), [1;2;3], ["a","b","c"]);            % 1d array
            df1a = frames.DataFrame(dat, {[1;2;3]}, {["a";"b";"c"]});            % cell with array (col vect) per dim 
            df1b = frames.DataFrame(dat, {[1,2,3]}, {["a","b","c"]});            % cell with array (row vect) per dim  
            df1c = frames.DataFrame(dat, {1;2;3}, {"a","b","c"});                % 1d cell with single values            
            df1d = frames.DataFrame(dat, {{1},{2},{3}}, {{"a"},{"b"},{"c"}});    % nested cell with single values
            df1e = frames.DataFrame(dat, df1.rows, df1.columns);                 % from .rows/.columns
            df1f = frames.DataFrame(dat, df1.rows(:,:), df1.columns(:,:));       % from .rows(:,:)/.columns(:,:)
            df1g = frames.DataFrame(dat, df1.rows(:,1), df1.columns(:,1));       % from .rows(:,1)/.columns(:,1)
            df1h = frames.DataFrame(dat, df1.getRowsObj(), df1.getColumnsObj()); % from rows/columns obj
            df1i = frames.DataFrame(dat, [], df1.getColumnsObj());               % rows default
            df1j = frames.DataFrame(dat, {}, df1.getColumnsObj());               % rows default
            df1k = frames.DataFrame(dat, frames.Index([1,2,3]), ...
                                         frames.Index(["a","b","c"]));           % convert Index obj to MultiIndex obj                        
            t.verifyTrue(isa(df1.getColumnsObj(), "frames.MultiIndex"));
            t.verifyTrue(isa(df1.getRowsObj(), "frames.MultiIndex"));            
            t.verifyEqual(df1,df1a);
            t.verifyEqual(df1,df1b);
            t.verifyEqual(df1,df1c);
            t.verifyEqual(df1,df1d);
            t.verifyEqual(df1,df1e);
            t.verifyEqual(df1,df1f);
            t.verifyEqual(df1,df1g);
            t.verifyEqual(df1,df1h);
            t.verifyEqual(df1,df1i);
            t.verifyEqual(df1,df1j);
            t.verifyEqual(df1,df1k);
            
            % 2d MultiIndex indices
            df2  = frames.DataFrame(dat, [1 1; 2 1; 3 2],   ["a","b","c" ; "A","A","B" ]);     % 2d array
            df2a = frames.DataFrame(dat, {[1;2;3],[1;1;2]}, {["a";"b";"c"],["A";"A";"B"] });   % cell with array per dim
            df2b = frames.DataFrame(dat, {[1,2,3],[1,1,2]}, {["a","b","c"],["A","A","B"] });   % cell with array per dim
            df2c = frames.DataFrame(dat, {1 1; 2 1; 3 2}, {"a","b","c" ; "A","A","B" });       % 2d cell            
            df2d = frames.DataFrame(dat, {{1,1},{2,1},{3,2}}, {{"a","A"},{"b","A"},{"c","B"}});% nested cell                       
            df2e = frames.DataFrame(dat, df2.rows, df2.columns);                               % from .rows/.columns           
            df2f = frames.DataFrame(dat, df2.rows(:,:), df2.columns(:,:));                     % from .rows/.columns            
            df2g = frames.DataFrame(dat, df2.getRowsObj(), df2.getColumnsObj());               % from .rows/.columns obj            
            warning('off', 'frames:Index:notUnique');
            df2i = frames.DataFrame(dat, [frames.Index([1,2,3]), frames.Index([1,1,2])], ...   % array of Index obj per dim
                                         [frames.Index(["a","b","c"]),frames.Index(["A","A","B"])]); 
            warning('on', 'frames:Index:notUnique');
            t.verifyTrue(isa(df2.getColumnsObj(), "frames.MultiIndex"));
            t.verifyTrue(isa(df2.getRowsObj(), "frames.MultiIndex"));            
            t.verifyEqual(df2,df2a);
            t.verifyEqual(df2,df2b);
            t.verifyEqual(df2,df2c);
            t.verifyEqual(df2,df2d);
            t.verifyEqual(df2,df2e);
            t.verifyEqual(df2,df2f);
            t.verifyEqual(df2,df2g);
            t.verifyEqual(df2,df2i);
            
            % dim name tests
            df = frames.DataFrame(dat, [1 1; 2 1; 3 2], rowDim=["x","y"]);
            t.verifyEqual(df.getRowsObj().name, ["x","y"]);
            df = frames.DataFrame(dat, [1 1; 2 1; 3 2], colDim="dd");
            t.verifyEqual(df.getColumnsObj().name, "dd");
            df  = frames.DataFrame(dat, [1,1;2,1;3,2],["a","b","c";"A","A","B"], rowDim=["x","y"], colDim=["XX","YY"]); 
            t.verifyEqual(df.getRowsObj().name, ["x","y"]);
            t.verifyEqual(df.getColumnsObj().name, ["XX","YY"]);
            t.verifyError(@() frames.DataFrame(dat,[1,1;2,1;3,2],rowDim="x"),'frames:MultiIndex:setname:invalidcount')
            t.verifyError(@() frames.DataFrame(dat,[1,1;2,1;3,2],colDim=["X","Y"]),'frames:MultiIndex:setname:invalidcount')
                             
            % restore settings
            frames.DataFrame.setDefaultSetting("forceMultiIndex", false);           
        end
        
        
        function initCopyTest(t)
            % checks MultiIndex dataframe            
            df = frames.DataFrame([1, 2; 3, 4], {{1,"a"},{2,"b"}},{[11,22]});            
            df1 = df.initCopy([91,92;93,94;95,96], {{33,"aa"},{33,"ab"},{34,"ab"}},df.getColumnsObj());
            df1_ref = frames.DataFrame([91,92;93,94;95,96], {{33,"aa"},{33,"ab"},{34,"ab"}},{[11,22]});
            t.verifyEqual(df1, df1_ref)
            df2 = df.initCopy([91,92,11;93,94,22], df.rows,[11,22,33]);
            df2_ref = frames.DataFrame([91,92,11;93,94,22], {{1,"a"},{2,"b"}},{[11,22,33]});
            t.verifyEqual(df2, df2_ref)
                                    
            % check settings
            df.settings.alignMethod = "full";
            df3 = df.initCopy([91,92,11;93,94,22], df.rows,[11,22,33]);
            df3_ref = df2_ref;
            df3_ref.settings.alignMethod = "full";
            t.verifyEqual(df3, df3_ref)
            
            % check datasize
            t.verifyError(@() df.initCopy([11,22;33,44],{{1,"a"},{2,"b"},{3,"c"}},[1,2]), 'frames:initCopy:mismatchrows');
            t.verifyError(@() df.initCopy([11,22;33,44],{{1,"a"},{2,"b"}},[1,2,3]), 'frames:initCopy:mismatchcolumns');            
        end

        
        
        
        function catsIndexSpecTest1D(t)
            % 1D CHECKS            
            warning('off','frames:MultiIndex:notUnique')
            duplicate = frames.MultiIndex([1 1 3]');            
            warning('on','frames:MultiIndex:notUnique')
            unique = frames.MultiIndex([6 5 4]',Unique=true);
            sorted = frames.MultiIndex([10 20 30]',UniqueSorted=true);
            d1 = [1 2 3;4 5 6;7 8 9];
            d2 = d1.*10;
            d3 = d1.*100;
            
            dd = frames.DataFrame(d1,duplicate,duplicate);
            ds = frames.DataFrame(d1,duplicate,sorted);
            du = frames.DataFrame(d1,duplicate,unique);
            ud = frames.DataFrame(d2,unique,duplicate);
            uu = frames.DataFrame(d2,unique,unique);
            us = frames.DataFrame(d2,unique,sorted);
            sd = frames.DataFrame(d3,sorted,duplicate);
            su = frames.DataFrame(d3,sorted,unique);
            ss = frames.DataFrame(d3,sorted,sorted);
            e = frames.DataFrame([],{[]},frames.MultiIndex([])); %.setRowsName("")
                        
            % VERTCAT            
            warning('off','frames:MultiIndex:notUnique')
            t.verifyEqual([du;uu],frames.DataFrame([du.data;uu.data],...
                frames.MultiIndex([1 1 3 6 5 4]',Unique=false),du.getColumnsObj())) % original error 'frames:requireUniqueIndex'            
            
            t.verifyError(@() [su;du],'frames:DataFrame:combine:notAllRowsUnique') % original error 'frames:vertcat:rowsNotUnique'
            t.verifyError(@() [uu;ud],'frames:DataFrame:combine:notAllColumnsUnique') % original error 'frames:vertcat:rowsNotUnique'
            
            warning_id = 'frames:concat:overlap';
            t.verifyWarning(@() [su;su] , warning_id );
            warning('off',warning_id)
            t.verifyEqual([su;su], su) % original error 'frames:vertcat:rowsNotUnique'
            warning('on',warning_id)
                                              
            % can concatenate duplicates if same columns
            t.verifyEqual([ud;sd],frames.DataFrame([ud.data;sd.data],...
                frames.MultiIndex([6 5 4 10 20 30]',Unique=true),ud.getColumnsObj()))
            
            % sorts if first rows is required sorted
            % and align same columns
            uutmp = uu;
            uutmp.rows(1) = 25;
            uutmp.columns(1) = 20;
            tmp = [su;uutmp];
            tmpdata = NaN(6,4);
            tmpdata([3,4,6],1:3) = su.data;
            tmpdata([5 2 1],[4 2 3]) = uu.data;
            t.verifyEqual(tmp,frames.DataFrame(tmpdata,...
                frames.MultiIndex([4 5 10 20 25 30]',UniqueSorted=true),frames.MultiIndex([6 5 4 20]',Unique=true)))
            % with sorted columns
            tmp = [ss;uutmp];
            tmpdata = NaN(6,5);
            tmpdata([3,4,6],3:5) = ss.data;
            tmpdata([5 2 1],[4 2 1]) = uu.data;
            t.verifyEqual(tmp,frames.DataFrame(tmpdata,...
                frames.MultiIndex([4 5 10 20 25 30]',UniqueSorted=true), ...
                frames.MultiIndex([4 5 10 20 30]',UniqueSorted=true)))
            
            % with empty
            t.verifyEqual([us;e;su;e],[us;su])
            t.verifyEqual([e;su],su.setRowsType('unique').setColumnsType('duplicate'))
            
            
            %HORZCAT            
            data_ok = nan(5,6); data_ok(1:3,1:3) = uu.data; data_ok(4:5,4:6) = ds.data(2:3,:);
            df_ok = frames.DataFrame(data_ok, frames.MultiIndex([6 5 4 1 3]',Unique=true), ...
                                              frames.MultiIndex([unique;sorted],Unique=true));                                 
            t.verifyError(@() [uu,ds], 'frames:DataFrame:combine:notAllRowsUnique') % error originall 'frames:requireUniqueIndex'            
            
            
            % horzcat does not accept duplicate rows unless it is the same            
            t.verifyEqual([du,ds],frames.DataFrame([du.data,ds.data],duplicate,[unique;sorted]))            
            t.verifyEqual([dd,du],frames.DataFrame([dd.data,du.data],duplicate,[duplicate;unique]))            
            
            uud = uu.setColumnsType('duplicate');
            sstmp = ss;
            sstmp.columns(1) = 5;
            sstmp.rows(1:2) = [4 6];
            warning('off','frames:Index:notUnique') % warning with 'frames:Index' raised instead of 'frames:MultiIndex'
            tmp = [uud,sstmp,sstmp];
            tmpdata = NaN(4,9);
            tmpdata(1:3,1:3) = uud.data;
            tmpdata([3 1 4],4:end) = [sstmp.data,sstmp.data];
            t.verifyEqual(tmp,frames.DataFrame(tmpdata,...
                frames.MultiIndex([6 5 4 30]',Unique=true),[uud.columns,sstmp.columns,sstmp.columns]))
            warning('off','frames:Index:notUnique')
            
            uutmp = us;
            uutmp.rows(2) = 10;
            tmpdata = NaN(5,6);
            tmpdata(3:end,1:3) = su.data;
            tmpdata([2 3 1],4:end) = uutmp.data;
            tmp = [su,uutmp];
            t.verifyEqual(tmp,frames.DataFrame(tmpdata,...
                frames.MultiIndex([4 6 10 20 30]',UniqueSorted=true),[unique;sorted]))
            
            %t.verifyError(@()[ss,su],'frames:Index:requireSortedFail') %<== remove? it (now) gives sorted output
            t.verifyEqual([su,ss],frames.DataFrame([su.data,ss.data],sorted,[unique;sorted]))
             
            warning('on','frames:MultiIndex:notUnique')
        end
        
        function subsasgnTest(t)
            df = frames.DataFrame([1 2 3 4 5 6; 2 5 NaN 1 3 2]',{1:6});
            % test removal
            df{:,2} = [];
            df([1 3]) = [];
            df.iloc(4,:) = [];
            t.verifyEqual(df,frames.DataFrame([2 4 5]',{[2 4 5]'}))
            % test loc iloc
            df.loc([2 5],:) = [22 55]';
            df.iloc(2,:) = 44;
            t.verifyEqual(df.data,[22 44 55]')
            df.iloc(2) = 43;
            t.verifyEqual(df.data,[22 43 55]')
            df.iloc(:,1) = 100;
            t.verifyEqual(df.data,[100 100 100]')
            % test (), {}
            df(2) = 20;
            t.verifyEqual(df.data,[20 100 100]')
            df{2:end,:} = 80;
            t.verifyEqual(df.data,[20 80 80]')
            df=frames.DataFrame([1 2 3; 2 5 NaN],{[1 2]}, {[11,22,33]});
            df(2,[22,33]) = 3.14;
            t.verifyEqual(df.data,[1 2 3; 2 3.14 3.14])
            df(true,22) = 2.72;
            t.verifyEqual(df.data,[1 2.72 3; 2 3.14 3.14])
            
            % end in selection
            df=frames.DataFrame([1 2;3 4;5 6],{1:3});
            t.verifyEqual(df{end-1:end},df{end-1:end,:})
            t.verifyEqual(df{end-1:end},frames.DataFrame([3 4;5 6],{[2 3]'}))

            % empty all keeps the rows type
            tf=t.tfMissing1;
            tf{1:length(tf.rows),:} = [];
            t.verifyEqual(tf.rows,datetime.empty(0,1))
            
            % repeating columns            
            warning('off','frames:MultiIndex:notUnique')
            df = frames.DataFrame([1 2 3; 2 5 NaN],{[]},{["a","b","a"]});
            df(:,"a") = 100;
            expected = frames.DataFrame([100 2 100; 100 5 100],{[]},{["a","b","a"]});
            t.verifyEqual(df,expected)            
            warning('on','frames:MultiIndex:notUnique')
            
            % shuffled identifiers
            df = frames.DataFrame([1 2 3; 2 5 NaN],{[1 2]'},{[1 2 3]'});
            df([2 1],[3 1 2]) = [1 2 3; 4 5 6];
            expected = frames.DataFrame([5 6 4; 2 3 1],{[1 2]'},{[1 2 3]'});
            t.verifyEqual(df,expected)
            df{[2 1],[3 1 2]} = [10 20 30; 40 50 60];
            expected = frames.DataFrame([50 60 40; 20 30 10],{[1 2]'},{[1 2 3]'});
            t.verifyEqual(df,expected)
            df = df.setRowsType('sorted');
            %t.verifyError( @() f(df), 'frames:Index:requireSortedFail' )   
            %function f(x), x.loc([2 1], 2) = 20; end             % <== why should assign fail? end result is sorted
            %t.verifyError( @() fi(df), 'frames:Index:requireSortedFail' )
            %function fi(x), x.loc{[2 1], 2} = 20; end            % <== why should assign fail? end result is sorted
            
            % assign []
            df = frames.DataFrame([1 2 3; 2 5 NaN],{[1 2]},{[1 2 3]});
            df1 = df; df2 = df;
            df1(1,:) = [];
            expected = frames.DataFrame([2 5 NaN],{2},{[1 2 3]});
            t.verifyEqual(df1,expected)
            df2{:,:} = [];
            expected = frames.DataFrame([],{[]},{[1 2 3]});
            t.verifyEqual(df2,expected)
            
            % data is a DF
            df = frames.DataFrame([1 2 3; 2 5 NaN; NaN 0 1],{1:3});
            data = df{[1 3]}*2;
            df{[1 3],:} = data;
            t.verifyEqual(df,frames.DataFrame([2 4 6; 2 5 NaN; NaN 0 2],{1:3}))
            df(2) = frames.DataFrame([3 4 5],NaN,RowSeries=true);
            t.verifyEqual(df,frames.DataFrame([2 4 6; 3 4 5; NaN 0 2],{1:3}))
            t.verifyError(@isnotseries,'frames:elementWiseHandler:differentRows')
            function isnotseries, df(2) = frames.DataFrame([3 4 5]); end
            df(2) = frames.DataFrame([3 4 6]).data;
            t.verifyEqual(df,frames.DataFrame([2 4 6; 3 4 6; NaN 0 2],{1:3}))
            
            % col row
            df = frames.DataFrame([1 2 3; 2 5 NaN; NaN 0 1],{1:3});
            df.col("Var1") = df.col("Var2") + df.col("Var3");
            t.verifyEqual(df,frames.DataFrame([5 2 3; NaN 5 NaN; 1 0 1],{1:3}))
            df.row(2) = 4;
            t.verifyEqual(df,frames.DataFrame([5 2 3; 4 4 4; 1 0 1],{1:3}))
            df.col("newCol") = df.col("Var2");
            t.verifyEqual(df,frames.DataFrame([5 2 3 2; 4 4 4 4; 1 0 1 0],{[]},["Var1","Var2","Var3","newCol"]))
            df.rows = [1 3 4];
            df = df.setRowsType('sorted');
            df.row(2) = df.row(1);
            t.verifyEqual(df,frames.DataFrame([5 2 3 2; 5 2 3 2; 4 4 4 4; 1 0 1 0],frames.MultiIndex({1:4},UniqueSorted=true,Name="dim1"),["Var1","Var2","Var3","newCol"]))
            t.verifyError(@isnotseries2,'frames:elementWiseHandler:differentRows')
            function isnotseries2, df.row(1) = df(2); end
            
            t.verifyError(@cannotMultAsgn,'frames:subsasgn:rowMultiple')
            function cannotMultAsgn, df.row([1 2]) = 3; end
                        
            warning('off','frames:MultiIndex:notUnique')
            df = frames.DataFrame([1 2 3; 2 5 NaN],{[]},{["a","b","a"]});
            t.verifyError(@occursTwice,'frames:subsasgn:colMultiple')
            function occursTwice, df.col("a") = 3; end            
            warning('on','frames:MultiIndex:notUnique')
            
%             
%             tf = frames.TimeFrame(1,frames.TimeIndex(["01#11#2021","02#11#2021","03#11#2021"],Format='dd#MM#yyyy'));
%             tf1 = tf; tf2 = tf; tf3 = tf;
%             tf1(["01.11.2021","03.11.2021"]) = 2;
%             tf2(["01#11#2021","03#11#2021"]) = 2;
%             tf3(datetime(["01.11.2021","03.11.2021"])) = 2;
%             t.verifyEqual(tf1,tf2)
%             t.verifyEqual(tf1,tf3)
%             t.verifyEqual(tf1.data,[2 1 2]')
%             
%             tf1("01#11#2021:02#11#2021") = 3;
%             t.verifyEqual(tf1.data,[3 3 2]')
         end
        
        function subsasgnWithDFTest1D(t)
            df = frames.DataFrame([1 2;3 4],frames.MultiIndex([1 2]'),{[]});
            dfbool = frames.DataFrame([false,true;true,false],{[1 2]},{[]});
            seriesbool = frames.DataFrame([false,true]',{[1 2]},{[]}).asColSeries();
            series = frames.DataFrame([1 2]',{[1 2]},{2}).asColSeries(); %#ok<SETNU>
            vector = frames.DataFrame([false,true],{[]},df.columns).asRowSeries();
            dfother = frames.DataFrame([false,true;true,false],{[2 3]},{[]});
            
            df{dfbool} = NaN;
            t.verifyEqual(df,frames.DataFrame([1 NaN;NaN 4],frames.MultiIndex([1 2]'),{[]}))
            df(dfbool) = 44;
            t.verifyEqual(df,frames.DataFrame([1 44;44 4],frames.MultiIndex([1 2]'),{[]}))
            df.iloc(dfbool) = 33;
            t.verifyEqual(df,frames.DataFrame([1 33;33 4],frames.MultiIndex([1 2]'),{[]}))
            
            df{seriesbool} = 9;
            t.verifyEqual(df,frames.DataFrame([1 33;9 9],frames.MultiIndex([1 2]'),{[]}))
            
            df.loc(seriesbool) = 8;
            t.verifyEqual(df,frames.DataFrame([1 33;8 8],frames.MultiIndex([1 2]'),{[]}))
            
            df(seriesbool,["Var1","Var2"]) = 10;
            t.verifyEqual(df,frames.DataFrame([1 33;10 10],frames.MultiIndex([1 2]'),{[]}))
            
            df{seriesbool,vector} = 11;
            t.verifyEqual(df,frames.DataFrame([1 33;10 11],frames.MultiIndex([1 2]'),{[]}))
            
            df{:,vector} = 12;
            t.verifyEqual(df,frames.DataFrame([1 12;10 12],frames.MultiIndex([1 2]'),{[]}))
            
            t.verifyError(@notSeries,'frames:elementWiseHandler:differentColumns')
            function notSeries, df.iloc(seriesbool.asColSeries(false)) = 0; end
            
            seriesboolInd = seriesbool.asColSeries(false);
            t.verifyWarningFree(@dfnotSeries)   %default column name "Var" works (because of default names used in conversion, todo fix?)
            seriesboolInd.columns = "test";
            t.verifyError(@dfnotSeries,'frames:elementWiseHandler:differentColumns') % does not work with other name
            function dfnotSeries, series{seriesboolInd} = 0; end
            
            t.verifyError(@notAligned,'frames:elementWiseHandler:differentRows')
            function notAligned, df{dfother} = 0; end
            
            t.verifyError(@noTwoElements,'frames:subsasgn:OnlySingleIndexAllowed2DBool')
            function noTwoElements, df{dfbool,:} = 0; end
            
            t.verifyError(@noEmptyDataBool2D,'frames:modifyFromBool2D:mustBeNonempty')
            function noEmptyDataBool2D, df{dfbool} = []; end
            
            t.verifyError(@noFirstCol,'frames:logicalIndexChecker:onlyColSeries')
            function noFirstCol, df{vector} = 0; end
        end
        
        function subsrefTest(t)                        
            warning('off','frames:MultiIndex:notUnique')            
            
            % 1D CHECKS
            
            % repeating columns
            df = frames.DataFrame([1 2 3; 2 5 NaN],{[]},{["a","b","a"]});
            sol = df(:,"a");
            expected = frames.DataFrame([1 3; 2 NaN],{[]},{["a","a"]});
            t.verifyEqual(sol,expected)
            
            % simple selection
            sol = df(2,"b");
            expected = frames.DataFrame(5,{2},{"b"}); %#ok<STRSCALR>
            t.verifyEqual(sol,expected)
            
            % selection with logical
            sol1 = df(true, [false true]);
            sol2 = df{true, [false true]};
            sol3 = df{1, [false true]};
            sol4 = df(1, [false true]);
            sol5 = df(1, frames.DataFrame([false true false],{NaN},df.columns,RowSeries=true));
            sol6 = df(frames.DataFrame([true false]',df.rows,{NaN},ColSeries=true), ...
                frames.DataFrame([false true false],{NaN},df.columns,RowSeries=true));
            t.verifyEqual(sol1,sol2)
            t.verifyEqual(sol1,sol3)
            t.verifyEqual(sol1,sol4)
            t.verifyEqual(sol1,sol5)
            t.verifyEqual(sol1,sol6)
            t.verifyEqual(sol1,frames.DataFrame(2,{1},{"b"})) %#ok<STRSCALR>
            t.verifyError(@() df(1, frames.DataFrame([false true],{NaN},{["a" "b"]},RowSeries=true)), ...
                'frames:logicalIndexChecker:differentColumns')
            t.verifyError(@() df(1, frames.DataFrame([false true],{1},{["a" "b"]})), ...
                'frames:logicalIndexChecker:onlyRowSeries')
            
            % rows only selection
            sol = df(2);
            expected = frames.DataFrame([2 5 NaN],{2},{["a","b","a"]});
            t.verifyEqual(sol,expected)
            
            % selection while repeating columns exist
            sol = df(1,{["b","a"]});
            expected = frames.DataFrame([2 1 3],{1},{["b","a","a"]});
            t.verifyEqual(sol,expected)
            
            % col row
            %t.verifyEqual(df.col('b'),frames.DataFrame([2;5],{[]},{string(missing)},ColSeries=true))
            t.verifyEqual(df.col('b'),frames.DataFrame([2;5],{[]},{missing},ColSeries=true))           
            t.verifyError(@() df.col('a'),'frames:Index:setSingleton')
            t.verifyEqual(df.row(1),frames.DataFrame([1 2 3],{NaN},{["a","b","a"]},RowSeries=true))            
            
            % test empty selection
            df = frames.DataFrame([1 2;3 4],{[1,2]},{["a","b"]});
            %t.verifyWarning(@() df{:,double.empty(1,0)}, 'frames:MultiIndex:emptySelection');
            %t.verifyWarning(@() df(double.empty(0,1),"b"), 'frames:MultiIndex:emptySelectorSet');
            warning('off', 'frames:MultiIndex:emptySelection');
            warning('off', 'frames:MultiIndex:emptySelectorSet');
            t.verifyEqual(df{:,double.empty(1,0)},frames.DataFrame([],{[1,2]},{[]}))            
            t.verifyEqual(df(double.empty(0,1),"b"),frames.DataFrame([],{[]},{"b"}))
            warning('on','frames:MultiIndex:emptySelection');                        
            warning('on', 'frames:MultiIndex:emptySelectorSet');
            
            % sorted rows 
            t.verifyEqual(df(([2 1])),frames.DataFrame([3 4;1 2],{[2 1]},{["a","b"]}))
            df = df.setRowsType('sorted');
            t.verifyError(@() df([2 1]),'frames:MultiIndex:requireSortedFail')
            t.verifyError(@() df{[2 1]},'frames:Index:requireSortedFail')
             
            % unique rows
            df = frames.DataFrame([1 2;3 4],{[1,2]},{["a","b"]});
            t.verifyError(@() df{[2 1 2]},'frames:Index:requireUniqueFail')
            t.verifyError(@() df([2 1 2]),'frames:MultiIndex:requireUniqueFail')
            df = df.setRowsType('duplicate');            
            t.verifyEqual(df([1 2 1],"b"), ...
                frames.DataFrame([2;4;2], frames.MultiIndex({[1,2,1]}),frames.MultiIndex({"b"})))            
            warning('on','frames:MultiIndex:notUnique')
        end
        
        function modifyIlocFailTest1D(t)            
            % 1D check
            df = frames.DataFrame([1 2;3 4],{});
            
            t.verifyError(@selTooLarge,'MATLAB:badsubscript')
            function selTooLarge, df{[true true false true],:}; end %#ok<VUNUS>
            t.verifyError(@selNotVector,'frames:logicalIndexChecker:VectorRequired')
            function selNotVector, df{[true false; true true]}; end %#ok<VUNUS>
            
            t.verifyError(@modNotVector,'frames:modifyFromBool2D:WrongSize')
            function modNotVector, df{[true false; true true; false false]} = 44; end
            t.verifyError(@modExceed,'frames:modify:badIndex')
            function modExceed, df{[true false true true]} = 44; end
            t.verifyError(@modExceed2,'frames:subsasgn:OnlySingleIndexAllowed2DBool')
            function modExceed2, df{[true false; true true],true} = 44; end
            
            df{[true false; true true]} = 44;
            t.verifyEqual(df,frames.DataFrame([44 2;44 44],{}))
                        
        end
        
        function equivalentSubsasgnBoolTest1D(t)
            df = frames.DataFrame([-1 3; -2 4],{});
            df2 = df;
            df{df<0} = NaN;
            df2{df2.data<0} = NaN;
            t.verifyEqual(df,df2)
            t.verifyEqual(df,frames.DataFrame([NaN 3;NaN 4],{}))
        end
         
        function oneifyTest1D(t)
            t.verifyEqual(frames.DataFrame([2 NaN],{1:2}).oneify(),frames.DataFrame([1 NaN],{1:2}))
            t.verifyEqual(frames.DataFrame(string([2 NaN]),{1:2}).oneify(),frames.DataFrame(["" string(missing)],{1:2}))
        end
        
        function setRowsTest1D(t)
            df = frames.DataFrame([1 2 3 3 2 1; 2 5 NaN 1 3 2;5 0 4 1 3 2]',{1:6});
            df = df.setRows("Var3");
            expected = frames.DataFrame([1 2 3 3 2 1; 2 5 NaN 1 3 2]', frames.MultiIndex({[5 0 4 1 3 2]'},name="Var3",Unique=true));
            t.verifyEqual(df,expected)
        end
        
        function rowsSetterTest1D(t)
            df = frames.DataFrame([1 2; 2 5],{1:2});
            df.rows = frames.MultiIndex([3 5]',UniqueSorted=true);
            t.verifyEqual(df.rows(:,1),[3 5]')
            
            t.verifyError(@idxNotSorted,'frames:MultiIndex:requireSortedFail')
            function idxNotSorted(), df.rows(:,1)=[6 3]; end
            
            t.verifyError(@wrongSize,'frames:rowsValidation:wrongSize')
            function wrongSize(), df.rows=3; end
            
            t.verifyError(@idxNotSorted2,'frames:MultiIndex:requireSortedFail')
            function idxNotSorted2(), df.rows(1)=33; end
            
            df.rows = [3 6];
            t.verifyEqual(df.rows(:,1),[3 6]')   
            
            df.rows = frames.MultiIndex([3 5]');
            t.verifyEqual(df.rows(:,1),[3 5]')   
            t.verifyFalse(df.identifierProperties.rows.requireUniqueSorted)   
            
            df.rows=frames.MultiIndex([6 3]');
            t.verifyFalse(df.identifierProperties.rows.requireUniqueSorted)              
        end
        
        function rowsAssignTest1D(t)
            dfs = frames.DataFrame(1,frames.MultiIndex([1 2 3 10 20]',UniqueSorted=true));
            dfu = frames.DataFrame(1,frames.MultiIndex([1 2 3 10 20]',Unique=true));            
            warning('off','frames:MultiIndex:notUnique')
            dfd = frames.DataFrame(1,frames.MultiIndex([1 2 3 10 10]',Unique=false));            
            warning('on','frames:MultiIndex:notUnique')
            
            df1=dfs;
            df1.rows([3,1]) = [4,0];
            t.verifyEqual(df1.rows(:,1),[0 2 4 10 20]')
            t.verifyError(@notSorted,'frames:MultiIndex:requireSortedFail')
            function notSorted, df1.rows([1,3]) = [4,0]; end
            t.verifyError(@notSortedAll,'frames:MultiIndex:requireSortedFail')
            function notSortedAll, df1.rows = [1 2 3 20 10]; end
            t.verifyError(@notSortedAll2,'frames:MultiIndex:requireSortedFail')
            function notSortedAll2, df1.rows(1:end) = [1 2 3 20 10]; end
            
            df2=dfu;
            df2.rows([3,1]) = [0,4];
            t.verifyEqual(df2.rows(:,1),[4 2 0 10 20]')
                        
            t.verifyError(@notUnique,'frames:MultiIndex:requireUniqueFail')            
            function notUnique, df2.rows([3,1]) = [2,0]; end
            t.verifyError(@notUniqueAll,'frames:MultiIndex:requireUniqueFail')
            function notUniqueAll, df2.rows = [1 2 3 20 20]; end
            t.verifyError(@notUniqueAll2,'frames:MultiIndex:requireUniqueFail')            
            function notUniqueAll2, df1.rows(1:end) = [1 2 3 20 20]; end            
            
            df3=dfd;
            warning('off','frames:MultiIndex:notUnique')
            df3.rows([3,1]) = [0,4];
            warning('on','frames:MultiIndex:notUnique')
            t.verifyEqual(df3.rows(:,1),[4 2 0 10 10]')
            t.verifyWarning(@duplicate1,'frames:MultiIndex:notUnique') %was frames:Index:subsagnNotUnique
            function duplicate1, df3.rows([3,1]) = [2,0]; end
            t.verifyWarning(@duplicate2,'frames:MultiIndex:notUnique') %was frames:Index:subsagnNotUnique
            function duplicate2, df3.rows([3,1]) = [6,6]; end
            
            dfcs = frames.DataFrame(1,[],frames.MultiIndex([1 2 3 10 20]',UniqueSorted=true));
            df4=dfcs;
            df4.columns([3,1]) = [4,0];
            t.verifyEqual(df4.columns(:,1),[0 2 4 10 20])
            t.verifyError(@notSortedCol,'frames:MultiIndex:requireSortedFail')
            function notSortedCol, df4.columns([1,3]) = [4,0]; end
            
            df = frames.DataFrame([1 2; 2 5],{[]});
            t.verifyError(@missing1,'frames:validators:mustBeFullVector')
            function missing1(), df.rows(1:2)=[NaN 1]; end
            
            t.verifyError(@missing2,'frames:validators:mustBeFullVector')
            function missing2(), df.rows(:,1)=[NaN 1]'; end
            
            t.verifyError(@cannotBeEmpty,'frames:rowsValidation:mustBeNonempty')
            function cannotBeEmpty(), df.rows(2)=[]; end
            
            t.verifyError(@cannotBeEmpty2,'frames:rowsValidation:mustBeNonempty')
            function cannotBeEmpty2(), df.rows=[]; end
                        
            t.verifyError(@notUnique1,'frames:MultiIndex:requireUniqueFail')
            function notUnique1(), df.rows=[6 6]; end
            
            
            t.verifyError(@notUnique2,'frames:MultiIndex:requireUniqueFail')
            function notUnique2(), df.rows(1)=2; end
%             
%             tf = frames.TimeFrame([1 2; 2 5],[738315,738316]);
%             tf.rows = [738315,738317];
%             t.verifyTrue(isdatetime(tf.rows))
%             t.verifyEqual(datenum(tf.rows),[738315,738317]') 
%             
%             tf.rows(1) = 738314;
%             t.verifyEqual(datenum(tf.rows),[738314,738317]') 
%             t.verifyError(@tiNotSorted,'frames:Index:requireSortedFail')
%             function tiNotSorted(), tf.rows(1)=738318; end
         end
%         
        function columnsSetterTest1D(t)
            df = frames.DataFrame([1 2; 2 5],{[]},{[]});
            
            t.verifyWarning(@colsNotUniqueWarning,'frames:MultiIndex:notUnique')
            function colsNotUniqueWarning(), df.columns=[6 6]; end
            
            df.columns = ["3" "5"];
            t.verifyEqual(df.columns(:,1),["3" "5"])
            
            df.columns = frames.MultiIndex([3 5]',Unique=true); % MultiIndex requires col-vector for seperate items 
            t.verifyEqual(df.columns(:,1),[3 5]) % output as row-vector
                        
            t.verifyError(@colsNotUnique,'frames:MultiIndex:requireUniqueFail')
            function colsNotUnique(), df.columns=[6 6]; end            
            
            t.verifyError(@colsNotUnique2,'frames:MultiIndex:requireUniqueFail')
            function colsNotUnique2(), df.columns(1)=5; end            
                        
            t.verifyError(@wrongSize,'frames:columnsValidation:wrongSize')
            function wrongSize(), df.columns=3; end
            
            t.verifyError(@missing1,'frames:validators:mustBeFullVector')
            function missing1(), df.columns(1:2)=[NaN 1]; end
            
            t.verifyError(@missing2,'frames:validators:mustBeFullVector')
            function missing2(), df.columns=[NaN 1]'; end
            
            t.verifyError(@cannotBeEmpty,'frames:rowsValidation:mustBeNonempty')
            function cannotBeEmpty(), df.columns(2)=[]; end
            
            df.columns = [3 6];
            t.verifyEqual(df.columns(:,1),[3 6]) 
        end
        
        function dataSetterTest1D(t)
            df = frames.DataFrame([1 2; 2 5],{[]},{[]});
            t.verifyError(@wrongSize,'frames:dataValidation:wrongSize')
            function wrongSize(), df.data=3; end
            
            df.data = [1 2;3 4];
            t.verifyEqual(df.data,[1 2;3 4]) 
        end
        
        function extendRowsTest(t)
            df = frames.DataFrame([1 1;2 2],{[1 2]'});
            ext = df.extendRows([3 2 0]');
            t.verifyEqual(ext.data, [1 1;2 2;NaN NaN;NaN NaN]);
            t.verifyEqual(ext.rows(:,1), [1 2 3 0]');
            
            df = df.setRowsType('sorted');
            ext = df.extendRows([3 2 0]');
            t.verifyEqual(ext.data, [NaN NaN;1 1;2 2;NaN NaN]);
            t.verifyEqual(ext.rows(:,1), [0 1 2 3]');            
            t.verifyEqual(df.extendRows([2 1 2]),df);
                        
            dupli = frames.DataFrame([1 3 4 5]',frames.MultiIndex([1 3 4 5]',Unique=false)).extendRows([1 2 4]');            
            t.verifyEqual(dupli.data, [1 3 4 5 NaN]');
            t.verifyEqual(dupli.rows(:,1), [1 3 4 5 2]');
        end
         
        function dropRowsTest(t)
            df = frames.DataFrame([1 1;2 2;3 3;4 4],{[1 2 3 4]});
            t.verifyEqual(df.dropRows([2 3]).data, [1 1;4 4]);
            t.verifyEqual(df.dropRows([false true true false]).data, [1 1;4 4]);            
        end
        
        function extendColumnsTest1D(t)
            df = frames.DataFrame([1 1;2 2]',{[]},{[1 2]});
            t.verifyEqual(df.extendColumns([3 1]).data, [1 1;2 2;NaN NaN]');                        
            warning('off','frames:MultiIndex:notUnique')
            wDuplicates = frames.DataFrame([1 2 3 4 5 6],{[]},{[1 3 1 4 5 4]}).extendColumns([1 2 4 2]');
            warning('on','frames:MultiIndex:notUnique')
            t.verifyEqual(wDuplicates.data, [1 2 3 4 5 6 NaN NaN]);
            t.verifyEqual(wDuplicates.columns(:,1), [1 3 1 4 5 4 2 2]);            
            sorted = frames.DataFrame([1 3 4 5],{[]},frames.MultiIndex([1 3 4 5]',UniqueSorted=true)).extendColumns([1 2 4]');
            t.verifyEqual(sorted.data, [1 NaN 3 4 5]);
            t.verifyEqual(sorted.columns(:,1), [1 2 3 4 5]);
            uniq = frames.DataFrame([1 3 4 5],[],frames.MultiIndex([1 3 4 5]',Unique=true)).extendColumns([1 2 4]');
            t.verifyEqual(uniq.data, [1 3 4 5 NaN]);
            t.verifyEqual(uniq.columns(:,1), [1 3 4 5 2]);
        end
        
        function dropColumnsTest(t)            
            warning('off','frames:MultiIndex:notUnique')
            df = frames.DataFrame([1 1;2 2;3 3;4 4;5 5]',{[]},{[1 2 4 2 5]'});
            t.verifyEqual(df.dropColumns([2 5]').data, [1 1;3 3]');
            t.verifyEqual(df.dropColumns([false true false true true]).data, [1 1;3 3]');            
            warning('on','frames:MultiIndex:notUnique')
        end
        
        function shiftTest(t)
            df = frames.DataFrame([1 1 3 1; NaN 1 NaN 1]',{[]});
            t.verifyEqual(df.shift().data, [NaN 1 1 3; NaN NaN 1 NaN]');
            t.verifyEqual(df.shift(-2).data, [3 1 NaN NaN; NaN 1 NaN NaN]');
        end
        
        function replaceStartByTest(t)
            df = frames.DataFrame([1 1 3 1; NaN 1 NaN 1;NaN 2 2 4]',{[]});
            t.verifyEqual(df.replaceStartBy(10).data, [10 10 3 1; 10 1 NaN 1;10 2 2 4]');
        end
        
        function emptyStart(t)
            df = frames.DataFrame([1 2 3 4; NaN NaN NaN 1;NaN 2 3 4]',{[]});
            t.verifyEqual(df.emptyStart(2).data, [NaN NaN 3 4; NaN NaN NaN NaN;NaN NaN NaN 4]',{[]});
        end
        
        function cumsumTest(t)
            df = frames.DataFrame([1 2 3 4; NaN 5 NaN 2;NaN NaN NaN NaN]',{[]});
            t.verifyEqual(df.cumsum().data, [1 3 6 10; NaN 5 NaN 7;NaN NaN NaN NaN]');
        end
        
        function cumprodTest(t)
            df = frames.DataFrame([1 2 3 4; NaN 5 NaN 2;NaN NaN NaN NaN]',{[]});
            t.verifyEqual(df.cumprod().data, [1 2 6 24; NaN 5 NaN 10;NaN NaN NaN NaN]');
        end
        
        function horzcatTest(t)            
            solUnsorted = [frames.DataFrame([4 2;1 1],{[1 3]'}, {[23 3]'}),frames.DataFrame([4 2;NaN 1],{[1 2]'}, {[4 2]'})];
            expectedUnsorted = frames.DataFrame([4 2 4 2;1 1 NaN NaN;NaN NaN NaN 1],{[1 3 2]'},{[23 3 4 2]'});
            t.verifyEqual(solUnsorted,expectedUnsorted)
            solSorted = [frames.DataFrame([4 2;1 1],frames.MultiIndex([1 3]',UniqueSorted=true), {[23 3]}),frames.DataFrame([4 2;NaN 1],{[1 2]'}, {[4 2]'})];
            expectedSorted = frames.DataFrame([4 2 4 2;NaN NaN NaN 1;1 1 NaN NaN],frames.MultiIndex([1 2 3]',UniqueSorted=true),{[23 3 4 2]});
            t.verifyEqual(solSorted,expectedSorted)
            
            % repeating
            a = frames.DataFrame(1,{1},{"a"});
            b = frames.DataFrame([11 11;22 22],{[1 3]'},{["b1","b2"]'});
            
            warning('off','frames:MultiIndex:notUnique')
            expected = frames.DataFrame([1 11 11 1; NaN 22 22 NaN],{[1 3]'},{["a","b1","b2","a"]'});
            warning('on','frames:MultiIndex:notUnique')
            warning('off','frames:Index:notUnique') % warning with 'frames:Index' raised instead of 'frames:MultiIndex'
            t.verifyEqual([a b a],expected)
            warning('on','frames:Index:notUnique')
            
            % disallow concatenation between different classes like [1,'1']
            c = b;
            c.data = char(c.data);
            warning('off','frames:Index:notUnique') % warning with 'frames:Index' raised instead of 'frames:MultiIndex'
            t.verifyError(@() [b c],'frames:concat:differentDatatype');
            warning('on','frames:Index:notUnique')
            
            
        end
        
        function vertcatTest(t)
            sol = [frames.DataFrame([4 2;1 1],frames.MultiIndex([1 2]',UniqueSorted=true),{[23 3]'});frames.DataFrame([4 2;1 1],{[3 4]'},{[3 44]'})];
            expected = frames.DataFrame([4 2 NaN;1 1 NaN;NaN 4 2;NaN 1 1],frames.MultiIndex([1 2 3 4]',UniqueSorted=true),{[23 3 44]'});
            t.verifyEqual(sol,expected)
            
%             % multiple concat with (un)sorted Frames
%             a = frames.TimeFrame(1,1,1);
%             b = frames.TimeFrame(2,[2 4],1);
%             c = frames.TimeFrame(3,3,2);
%             t.verifyEqual([a;c;b],frames.TimeFrame([1 2 NaN 2; NaN NaN 3 NaN]',[1 2 3 4],[1 2]))
            
%             warning_id = 'frames:concat:overlap';
%             t.verifyWarning(@() [a;a] , warning_id );
%             warning('off',warning_id)
%             t.verifyEqual([a;a], a) % original error 'frames:vertcat:rowsNotUnique'
%             warning('on',warning_id)                    
            
            a = frames.DataFrame(1,{1},{1});
            b = frames.DataFrame(2,{[2 4]'},{1});
            c = frames.DataFrame(3,{3},{2});
            t.verifyEqual([a;c;b],frames.DataFrame([1 NaN 2 2; NaN 3 NaN NaN]',{[1 3 2 4]'},{[1 2]'}))
        end
        
        function vertcatRowsPropsTest(t)
            df = frames.DataFrame([1 2;3 4],{[1 2]},frames.MultiIndex([1 3]',UniqueSorted=true));
            df2 = frames.DataFrame([30,20],{3},{[3 2]'});            
            t.verifyEqual([df;df2],frames.DataFrame([1 NaN 2;3 NaN 4;NaN 20 30],{[1 2 3]'},frames.MultiIndex([1 2 3]',UniqueSorted=true)))
            
        end
        
        function resampleTest(t)
            sortedframe = frames.DataFrame([4 1 NaN 3; 2 NaN 4 NaN]',{[1 4 10 20]'}).setRowsType("sorted");
            ffi = sortedframe.resample([2 5],FirstValueFilling='ffillFromInterval');
            t.verifyEqual(ffi, frames.DataFrame([4 1; 2 NaN]',{[2 5]'}).setRowsType("sorted"));
            ffi1 = sortedframe.resample([3 11],FirstValueFilling={'ffillFromInterval',1});
            t.verifyEqual(ffi1, frames.DataFrame([NaN 1; NaN 4]',{[3 11]'}).setRowsType("sorted"));
            ffla = sortedframe.resample([13 14 15],FirstValueFilling='ffillLastAvailable');
            t.verifyEqual(ffla, frames.DataFrame([1 NaN NaN;4 NaN NaN]',{[13 14 15]'}).setRowsType("sorted"));
            noff = sortedframe.resample([13 14 15],FirstValueFilling='noFfill');
            t.verifyEqual(noff, frames.DataFrame([NaN NaN NaN;NaN NaN NaN]',{[13 14 15]}).setRowsType("sorted"));
            noff2 = sortedframe.resample([4 14 15],FirstValueFilling='noFfill');
            t.verifyEqual(noff2, frames.DataFrame([1 NaN NaN;NaN 4 NaN]',{[4 14 15]'}).setRowsType("sorted"));
        end
        
        function sortByTest(t)
            sol = frames.DataFrame([1 2 3; 2 5 3]',{[1 3 65]'},{[4 3]'}).setRowsType("sorted").sortBy(3);
            t.verifyEqual(sol,frames.DataFrame([1 3 2;2 3 5]',{[1 65 3]'},{[4 3]'}))
        end
        
        function sortRowsTest(t)
            sol = frames.DataFrame([1 2 3; 2 5 3]', frames.MultiIndex([2 6 1]',Unique=true,Name="dim1")).sortRows();
            t.verifyEqual(sol,frames.DataFrame([3 1 2;3 2 5]',{[1 2 6]}))
        end
        
        function splitapplyTest(t)
            % 1D MULTIINDEX CHECKS
            
            % simple split with cell
            df=frames.DataFrame([1 2 3;2 5 3;5 0 1]', {[6 2 1]}, {[4 1 3]});
            g1 = frames.Groups(cell2struct({[4,3],1}',["d","e"]'));
            x1 = df.split(g1).apply(@(x) x);
            t.verifyEqual(x1,frames.DataFrame([1 2 3;2 5 3;5 0 1]',{[6 2 1]},{[4 1 3]}))
            % apply function using group names
            ceiler.d = {2.5,4.5};
            ceiler.e = {2.6};
            x2 = df.split(g1).apply(@(x) x.clip(ceiler.(x.description){:}), 'applyToFrame');
            % split with structure
            s.d = [4 3]; s.e = 1;
            x3 = df.split(frames.Groups(s)).apply(@(x) x.clip(ceiler.(x.description){:}), 'applyToFrame');
            % split with a Group
            g2 = frames.Groups(s).shrink([1 4 3]);
            x4 = df.split(g2).apply(@(x) x.clip(ceiler.(x.description){:}), 'applyToFrame');
            expected = frames.DataFrame([2.5 2.5 3;2 2.6 2.6;4.5 2.5 2.5]',{[6,2,1]},{[4 1 3]});
            t.verifyEqual(x2,expected)
            t.verifyEqual(x3,expected)
            t.verifyEqual(x4,expected)
            x5 = df.split(g2).aggregate(@(x) x.sum(2), 'applyToFrame');
            t.verifyEqual(x5,frames.DataFrame([6 2 4;2 5 3]',{[6 2 1]},{["d","e"]}))
            x6 = df.split(g2).aggregate(@(x) sum(x.data,2), 'applyToFrame');
            t.verifyEqual(x6,x5)
            x65 = df.split(g2).aggregate(@(x) sum(x,2),'applyToData');
            t.verifyEqual(x65,x5)
            x7 = df.split(g2.select(["d","e"])).apply(@(x) x.data, 'applyToFrame');
            t.verifyEqual(x7,df)
            
            % split without group names            
            splitted = frames.DataFrame(1:5,{},{}).split(frames.Groups({"Var"+(1:2:5),"Var"+(4:-2:2)}));
            t.verifyEqual(splitted.aggregate(@(x) x.sum(2), 'applyToFrame'), frames.DataFrame([9,6],{},{["Group1","Group2"]}))
            %t.verifyEqual(splitted.apply(@(x) x.sum(1)), frames.DataFrame([1,3,5,4,2],{NaN},{"Var"+[1:2:5,4:-2:2]},RowSeries=true))
            
            % with a group frame
            tf = frames.TimeFrame([1 2 3;4 5 6;4 5 6; 7 8 9],[],{});
            groups = frames.Groups(frames.TimeFrame([1 1 2;1 1 2; 1 2 1; 1 2 NaN],[],{}));
            g1 = tf.split(groups).apply(@mean,2, 'applyToFrame');
            g2 = tf.split(groups).apply(@(x) x.mean(2), 'applyToFrame');
            g3 = tf.split(groups).apply(@(x) mean(x.data,2), 'applyToFrame');
            t.verifyEqual(g1,frames.TimeFrame([1.5 1.5 3;4.5 4.5 6;5 5 5;7 8 NaN],[],{}))
            t.verifyEqual(g1,g2)
            t.verifyEqual(g1,g3)
            groupsRow = frames.Groups(frames.TimeFrame([1 1 2;1 1 2; 1 2 1; 1 2 NaN],[],{}),'rowGroups');
            f1 = tf.split(groupsRow).apply(@mean,1);
            t.verifyEqual(f1,frames.TimeFrame([4 4 4 4;3.5 3.5 6.5 6.5;4.5 4.5 6 NaN]',[],{}))
                        
            % with flags
            nObs = 2;
            nVars = 1000;
            nGroups = 3;
            operatorData = @(x) std(x,1,2,'omitnan');
            operatorFrame = @(x) x.std(2,1);            
            data = frames.DataFrame(rand(nObs,nVars),{},{});
            groupframe = frames.DataFrame(ceil(nGroups*rand(nObs,nVars)),{},{});
            groups = frames.Groups(groupframe);
            s1 = data.split(groups).apply(operatorData,'applyToData');
            s2 = data.split(groups).apply(operatorFrame,'applyToFrame');
            t.verifyEqual(s1,s2)
            
            grouprow = frames.Groups(groupframe.row(1));
            s3 = data.split(grouprow).apply(@std,1,2,'omitnan','applyToData');
            s4 = data.split(grouprow).apply(operatorFrame,'applyToFrame');
            t.verifyEqual(s3,s4)
            t.verifyEqual(s1{1}.data,s4{1}.data,'AbsTol',t.tol)
                       
            % missing groups
            groups = frames.Groups(frames.DataFrame(string([4 NaN 2 4;NaN 3 1 3]),{},{}));
            data = frames.DataFrame([1 2 3 4;5 6 7 8],{},{});
            s1 = data.split(groups).apply(@(x) x.sum(2), 'applyToFrame');
            s2 = data.split(groups).apply(@(x) sum(x,2),'applyToData');
            s3 = data.split(groups).apply(@(x) sum(x.data,2),'applyToFrame');
            t.verifyEqual(s1,frames.DataFrame([5 NaN 3 5;NaN 14 7 14],{},{}))
            t.verifyEqual(s1,s2)
            t.verifyEqual(s1,s3)
        end
        
        function firstRowsTest1D(t)
            % WARNING: behavior changed wrt to Index()
            df = frames.DataFrame([ NaN 2 3 4 NaN 6;NaN NaN NaN 1 NaN 1;NaN NaN 33 44 55 66]', {[]});
            t.verifyEqual(df.firstCommonRow(),{{4}}); % outputs a cell array
            t.verifyEqual(df.firstValidRow(),{{2}}) % outputs a cell array
            noCommon = frames.DataFrame([4 NaN 6;NaN 55 NaN]',{string([1 2 3])'}).firstCommonRow();
            t.verifyEqual(noCommon,cell(0,1)); % outputs empty cell array
        end
        
        function relChangeTest(t)
            dfp = frames.DataFrame([1 NaN 3; NaN 2 3;5 1 NaN]', {[]});
            exp = frames.DataFrame([NaN 1 3; NaN 2 3;5 1 NaN]', {[]});
            t.verifyEqual(dfp.relChg('log').compoundChange('log',[1 2 5]).data,exp.data,'AbsTol',t.tol)
            t.verifyEqual(dfp.relChg().compoundChange('simple',[1 2 5]).data,exp.data,'AbsTol',t.tol)
            df2 = frames.DataFrame([1 2]', {[]});
            t.verifyEqual(df2.relChg('log').data,[NaN log(2)]')
            t.verifyEqual(df2.relChg().data,[NaN 1]')
            
%             % test other arguments
%             tf = frames.TimeFrame([1 1 NaN 2]');
%             t.verifyEqual(tf.relChg(),frames.TimeFrame([NaN 0 NaN 1]'));
%             t.verifyEqual(tf.relChg('simple',2),frames.TimeFrame([NaN NaN NaN 1]'));
%             t.verifyEqual(tf.relChg('simple',2,false),frames.TimeFrame([NaN 1]',[2 4]));
        end
        
        function mathOperationsTest1D(t)
            mat1 = frames.DataFrame([1 2;3 4],{[]},{[]});
            mat2 = frames.DataFrame([10 20;30 40],{[]},{["a","b"]});
            vecV = frames.DataFrame([6 7]',{[]},{[]},ColSeries=true);
            vecV2 = frames.DataFrame([6 7]',{[]},{[]},ColSeries=true);
            vecH = frames.DataFrame([6 7]',{[]},{[]},ColSeries=true);
            tf = frames.TimeFrame([738331:738336;1:6]',738331:738336); %not changed to MultiIndex
            
            tfOp = tf' * tf;
            t.verifyEqual(tfOp,frames.DataFrame(tf.data'*tf.data,tf.getColumnsObj(),tf.getColumnsObj()))
            mtimesM = mat1' * mat2;
            t.verifyEqual(mtimesM,frames.DataFrame([100 140;140 200],mat1.getColumnsObj(),mat2.getColumnsObj()))
            mtimesV = mat1' * vecV2;
            t.verifyEqual(mtimesV,frames.DataFrame([27;40],mat1.getColumnsObj(),vecV2.getColumnsObj(),ColSeries=true))
            times = mat1 .* vecV;
            t.verifyEqual(times,frames.DataFrame([6 12;21 28],mat1.rows,mat1.columns))
            plus1 = mat1 + vecH;
            t.verifyEqual(plus1,frames.DataFrame([7 8;10 11],mat1.rows,mat1.columns))
            plus2 = vecH + mat1;
            t.verifyEqual(plus2,frames.DataFrame([7 8;10 11],mat1.rows,mat1.columns))
            plusSeries = vecV2 + vecV;
            t.verifyEqual(plusSeries,frames.DataFrame([12;14],vecV2.rows,vecV2.columns,ColSeries=true))
            t.verifyError(@notAligned,'frames:matrixOpHandler:notAligned')
            function notAligned(), mat1*mat2; end %#ok<VUNUS>
            t.verifyError(@notSameColumns,'frames:Index:align:unequalIndex')
            function notSameColumns(), mat1-mat2; end %#ok<VUNUS>
            
            t.verifyError(@seriesError,'frames:Index:align:unequalIndex')
            function seriesError(), mat1.*mat1(1); end %#ok<VUNUS>
            loc = mat1 .* mat1(1).asRowSeries();
            t.verifyEqual(loc,frames.DataFrame([1 4;3 8],mat1.rows,mat1.columns))
            summing = mat1 .* mat1.sum();
            t.verifyEqual(summing,frames.DataFrame([4 12;12 24],mat1.rows,mat1.columns))
            iloc = -mat1 - mat1{:,1}.asColSeries();
            t.verifyEqual(iloc,frames.DataFrame([-2 -3;-6 -7],mat1.rows,mat1.columns))

            % with arrays
            df = frames.DataFrame([1 2;3 4],{["a" "b"]'},{["one" "two"]'});
            two = frames.DataFrame(2,{[]},{[]},ColSeries=true,RowSeries=true);
            t.verifyEqual(df*2,frames.DataFrame(2*[1 2;3 4],{["a" "b"]'},{["one" "two"]'}))
            t.verifyEqual(2*df,df*2)
            t.verifyEqual(2*df,two.*df)
            t.verifyError(@() two*df,'frames:matrixOpHandler:notAligned')
            t.verifyEqual([1 2]*df,frames.DataFrame([7 10],1,df.columns))
            t.verifyEqual(df*[1;2],frames.DataFrame([5;11],df.rows))
            
            % element-wise with a 1x1
            oneone = frames.DataFrame(2,{[]},{[]});
            oneoneSeries = oneone.asRowSeries().asColSeries();
            matr = frames.DataFrame([1 2; 3 4],{[]},{[2 3]'});
            t.verifyEqual(oneoneSeries.*matr,matr.*oneoneSeries)
            t.verifyError(@cantMatOp,'frames:matrixOpHandler:notAligned')
            function cantMatOp(), oneoneSeries*matr; end %#ok<VUNUS>
            
            % col mtimes row
            res = frames.DataFrame([1 2 3]',{(2:4)'},{"u"})*frames.DataFrame([1 2 3],{"u"},{["a" "b" "c"]'});
            t.verifyEqual(res.rows(:,1),(2:4)')
            t.verifyEqual(res.columns(:,1),["a" "b" "c"])
            
            % logical operations
            df = frames.DataFrame([true,false;false,true]);
            t.verifyEqual(~df,frames.DataFrame([false,true;true,false]))
        end
        
        
        function mathOperationsAlignTest1D(t)
            % verify 1D math operations including index alignment
            dat = magic(4);
            df = frames.DataFrame(dat,{},{});

            % rows, default alignMethod 'strict'
            df1a = df + 100*df;
            df1b = df + 100*df{[2 3 1 4]};   % auto aligned to match order first df
            t.verifyEqual(df1a,df1b)
            t.verifyError(@() df + 100*df{[2 3]}, 'frames:Index:align:unequalIndex')
            t.verifyEqual( df.iloc(1:2,:) - df.row(3), ...
                  frames.DataFrame([7,-5,-3,1;-4,4,4,-4],df.rows_.getSubIndex(1:2),df.columns_))
            t.verifyError(@() df - df{3,1:3}.asRowSeries(), 'frames:Index:align:unequalIndex')

            % rows with auto-alignment ("full")
            df5a = df{[1 3 4]}.autoAlign() + 100*df{[4 2]};   % auto align, result is expanded to contain all row values            
            dfs = df.sortRows().setRowsType("sorted");
            df5b = dfs{[1 3 4]}.autoAlign() + 100*df{[4 2]};  % auto align+sort, result is expanded to contain all row values
            t.verifyEqual(df5a.rows(:,1), [1;3;4;2])
            t.verifyEqual(df5b.rows(:,1), [1;2;3;4]) 
            t.verifyEqual(df5a(1:4).data, df5b.data)          % compare after making df5a sorted

            df6a = df.autoAlign() - df{3,1:3}.asRowSeries();  % auto align, rowseries with subset
            t.verifyEqual(df6a.data, dat- repmat([dat(3,1:3), 0],4,1) );

            % rows with other alignment methods available
            df7a = df{[1 3 4]}.alignMethod("left") + 100*df{[4 2]};  % align method "left", use values from 1st df, ignore others
            t.verifyEqual(df7a, df5a([1,3,4]).alignMethod("left") );
            df7b = df{[1 3 4]}.alignMethod("inner") + 100*df{[4 2]}; % align method "inner", keep only common subset
            t.verifyEqual(df7b, df5a(4).alignMethod("inner") );

            % rows with duplicates
            warning('off', 'frames:MultiIndex:notUnique'); % TODO: fix some unnecessary non-unique warnings                        
            dfd = frames.DataFrame(magic(5),frames.MultiIndex([1 3 2 3 1]',unique=false)); 
            t.verifyEqual(dfd-dfd, frames.DataFrame(zeros(5), dfd.rows_, dfd.columns_)); % exactly same index allowed
            t.verifyError(@() dfd{1:4}.alignMethod("full") - dfd{2:5}, 'frames:Index:align:notUnique')
            
            df8a = dfd{1:4,2:4}.alignMethod("full").duplicateOption("duplicates") - dfd{2:3,3:5};
            t.verifyEqual(df8a.data, [24,1,8,NaN;5,0,0,-16;6,0,0,-22;12,19,21,NaN]);
            t.verifyEqual(df8a.rows(:,1),[1;3;2;3]);
            
            df8b = dfd{1:4,2:4}.alignMethod("full").duplicateOption("unique") - dfd{2:3,3:5};
            t.verifyEqual(df8b.data, [24,1,8,NaN;5,0,0,-16;6,0,0,-22]);
            t.verifyEqual(df8b.rows(:,1),[1;3;2]);
            
            df8c = dfd{1:4,2:4}.alignMethod("full").duplicateOption("expand") - dfd{2:3,3:5};
            t.verifyEqual(df8c.data, [24,1,8,NaN;5,0,0,-16;6,0,0,-22;12,12,7,-16]);
            t.verifyEqual(df8c.rows(:,1),[1;3;2;3]);            
            warning('on', 'frames:MultiIndex:notUnique');
                                    
            % row&column alignment
            dfC = frames.DataFrame(magic(4),{},{}).alignMethod("full");
            dfC1a = dfC + 100*dfC{[1 3 4],[1 3 4]};          % auto align, sub-dataframe is added with less columns
            t.verifyEqual(dfC1a, frames.DataFrame([1616,2,303,1313;5,11,10,8;909,7,606,1212;404,14,1515,101], ...
                dfC.rows_, dfC.columns_).alignMethod("full"));
            
            dfC1b = 100*dfC{[1 3 4],[1 3 4]} + dfC;          % auto align, expand to all rows/columns
            t.verifyEqual(dfC1b, dfC1a{[1,3,4,2],[1,3,4,2]});
            
            dfC2a = dfC{[1 3 4],[1 3 4]} - dfC{[2 3],[2 3]};  % auto align, expand, missing values are NaN
            t.verifyEqual(dfC2a, frames.DataFrame([16,3,13,NaN;9,0,12,-7;4,15,1,NaN;NaN,-10,NaN,-11],...
                 {[1,3,4,2]},  {["Var1","Var3","Var4","Var2"]}).alignMethod("full"));
            
            dfC2b = df{[1 3 4],[1 3 4]}.alignMethod("inner") - df{[2 3 4],[2 3]};  % inner align
            t.verifyEqual(dfC2b, frames.DataFrame([0;0],{[3;4]}, {["Var3"]}).alignMethod("inner"));
            
            dfC2c = df{[1 3 4],[1 3 4]}.alignMethod("left") - df{[2 3 4],[2 3]};  % left align
            t.verifyEqual(dfC2c, frames.DataFrame([16,3,13;9,0,12;4,0,1],dfC2c.rows_, dfC2c.columns_).alignMethod("left"));
        end
        
        function mathOperationsAlignTestMultiDim(t)
            frames.DataFrame.restoreDefaultSettings();
            
            ftestdat  = @(sx,sy) (1:sx)' + 10*(1:sy);
            % linear axes            
            x=1:3;
            y=1:2;
            z=1:4;
            k=11:13;
            dfX = frames.DataFrame( ftestdat(length(x),2)*1, frames.MultiIndex({x},name="x"), ["A","B"]);
            dfY = frames.DataFrame( ftestdat(length(y),2)*3, frames.MultiIndex({y},name="y"), ["A","B"]);
            dfZ = frames.DataFrame( ftestdat(length(z),2)*4, frames.MultiIndex({z},name="z"), ["A","B"]);
            dfK = frames.DataFrame( ftestdat(length(k),2)*4, frames.MultiIndex({k},name="k"), ["A","B"]);
            
            % perform operations
            
            % no common dimensions            
            df0 = dfX+dfY;
            [inddf0_0, inddf0_1] = meshgrid(x,y);
            t.verifyEqual(df0.rows(:,1), inddf0_0(:))
            t.verifyEqual(df0.rows(:,2), inddf0_1(:))
            t.verifyEqual(df0{[1 2 4],2}, frames.DataFrame([84;87;88], ...
                         frames.MultiIndex({[1 1 2],[1 2 2]}, unique=false), "B", RowDim=["x","y"]) )

            dfX_tmp = dfX; dfX_tmp.settings.allowDimExpansion = false;
            t.verifyError(@() dfX_tmp .* dfY, 'frames:MultiIndex:align:expansiondisabled')            
            df1 = (dfX+dfY)-(dfY+dfX);
            t.verifyEqual(df1.data, zeros(6,2) )
            df2 = (dfX{[2 1 3]}+dfY{[2 1]}+dfZ{[4 2 1 3]}) - ((dfY+(dfZ+0.75*dfX))+0.25*dfX);
            t.verifyEqual(df2.data, zeros(24,2) )
                         
            % handle subsets
            dfXY = dfX + dfY;
            t.verifyError(@() dfXY{1:5} - dfX([3 1]).col("A"), 'frames:Index:align:unequalIndex');
            df3 = dfXY{1:5}.alignMethod("full") - dfX([3 1]).col("A");
            t.verifyEqual(df3.data, [33,73;36,76;45,85;48,88;33,73] )
            df4 = (dfX.alignMethod("full")+dfZ{[1 3]}+dfY) ./ (dfY+dfZ(3)+dfX) ./  (dfZ(1)+dfX+dfY);
            t.verifyEqual(df4.data, ones(12,2 ) )
            
            % align common dimension(s) and expand
            dfXYZ = dfX + dfY + dfZ;
            dfYK = dfY{[2 1]} + dfK{[2 3 1]};
            dfYKZ = dfY{[2 1]} + dfK{[2 3 1]} + dfZ{[4 3 1 2]};
            [k_mat,z_mat,y_mat,x_mat] = ndgrid(dfK.data(:,1), dfZ.data(:,1), dfY.data(:,1), dfX.data(:,1));
            df5 = dfXYZ .* dfYK; % 1 common dimension + both sides have unique dimension                      
            t.verifyEqual(df5.rows_.name,["x","y","z","k"]);            
            t.verifyEqual(df5.col("A").sortRows().data, (x_mat(:)+y_mat(:)+z_mat(:)).*(y_mat(:)+k_mat(:)) )
            df6 = dfXYZ.*dfYKZ;  % 2 common dimensions + both sides unique dimension 
            t.verifyEqual(df6.rows_.name,["x","y","z","k"]);            
            t.verifyEqual(df6.col("A").sortRows().data, (x_mat(:)+y_mat(:)+z_mat(:)).*(y_mat(:)+k_mat(:)+z_mat(:)) )
            
            t.verifyError(@() dfXYZ.alignMethod("full") + (dfY(2)+dfK), 'frames:MultiIndex:align:invalidexpansion');
            t.verifyError(@() dfXYZ.alignMethod("left") + (dfY(2)+dfK), 'frames:MultiIndex:align:invalidexpansion');                        
            df7 = dfXYZ.alignMethod("inner") + (dfY(2)+dfK); % inner removes values from common dimension(s) that are not shared
            t.verifyEqual(df7.rows_.name,["x","y","z","k"]);            
            t.verifyEqual(length(df7.rows_), length(df5.rows_)/2); % only half the y values ==> half the length            
            t.verifyError(@()(dfX.alignMethod("full")+dfY(1)+dfZ) + dfYK, 'frames:MultiIndex:align:invalidexpansion');
            df8a = t.verifyWarningFree(@()(dfX.alignMethod("left")+dfY(1)+dfZ) + dfYK);
            df8b = t.verifyWarningFree(@()(dfX.alignMethod("inner")+dfY(1)+dfZ) + dfYK);
            t.verifyEqual(  df8a.data, df8b.data);
            
            % expansion in columns            
            df9a = dfXYZ' + dfYKZ';
            df9b = dfXYZ  + dfYKZ;
            t.verifyEqual(df9a,df9b')
            
            % mix Index and MultiIndex obj in math operation
            dfXi = frames.DataFrame( dfX.data, frames.Index(x,name="x"), ["A","B"]);
            dfYi = frames.DataFrame( dfY.data, frames.Index(y,name="y"), ["A","B"]);
            df10a = dfX + dfY;
            df10b = dfX + dfYi;
            df10c = dfXi + dfY;
            t.verifyEqual(df10a, df10b)
            t.verifyEqual(df10a, df10c)
            t.verifyError(@() dfXi + dfYi, 'frames:Index:align:unequalIndex') %no conversion to MultiIndex in case of only Index obj
                           
            % handle duplicates
            warning('off', 'frames:MultiIndex:notUnique');
            dfXdup = frames.DataFrame([1 2 3 4 5]' ,frames.MultiIndex([1 2 3 2 3]',unique=false),"A"  ,RowDim="x");
            dfYdup = frames.DataFrame([10 20 30]'  ,frames.MultiIndex([1 2 1]'    ,unique=false),"A"  ,RowDim="y");
            dfXYdup =dfXdup + dfYdup;
            t.verifyEqual(length(dfXYdup.rows), length(dfXdup.rows)*length(dfYdup.rows));
            t.verifyError(@() dfXdup + dfX, 'frames:Index:align:notUnique');
            t.verifyError(@() dfXYdup + dfX.col("A"),  'frames:MultiIndex:align:invalidduplicatesexpansion');
            t.verifyError(@() dfXYdup + dfXY, 'frames:Index:align:notUnique');
            t.verifyError(@() dfXY + dfXYdup,'frames:Index:align:notUnique');
            t.verifyError(@() dfXYdup + dfXYZ,  'frames:MultiIndex:align:invalidduplicatesexpansion');
            df11a = dfXYdup.alignMethod("full","expand") - dfXY;   % obj2 values applied to all duplicate
            t.verifyEqual( df11a({2,':'},"A").data,[ -33 ;-26;-13;-31;-24;-11]);
            t.verifyEqual( df11a({2,':'},"B").data,[ -85;-88;-85;-85;-88;-85]);
            df11b = dfXYdup.alignMethod("full","duplicates") - dfXY; % obj2 values applied only to first duplicates
            t.verifyEqual( df11b({2,':'},"A").data,[ -33 ;-26; 32;14;24;34]); 
            t.verifyEqual( df11b({2,':'},"B").data,[ -85;-88;NaN;NaN;NaN;NaN]);
            warning('on', 'frames:MultiIndex:notUnique');
        end
        
        function mathOperationsMiscellaneousTest1D(t)
            df = t.dfMissing1;
            t.verifyEqual(df./df,df./df.data)
            div = 1./df;
            t.verifyEqual(div.data,1./df.data)
            t.verifyEqual(df/2,df./2)
            t.verifyEqual(df+1,1+df)
            t.verifyEqual(df-1,-(1-df))
            
            b = df{1,:}';
            expectedData = df.data * b.data;
            expected = frames.DataFrame(expectedData,df.rows,b.getColumnsObj());
            t.verifyEqual(df*b,expected)
        end
        
        function mat2seriesTest1D(t)
            df = frames.DataFrame([1:6;11:16;21:26],{[]},{[]});
            df.data(8) = NaN;
            t.verifyEqual(df.mean(),df.mean(1))
            t.verifyEqual(df.mean().data,mean(df.data,'omitnan'))
            t.verifyEqual(df.mean(2).data,mean(df.data,2,'omitnan'))
            
            t.verifyEqual(df.std(),df.std(1))
            t.verifyEqual(df.std().data,std(df.data,'omitnan'))
            t.verifyEqual(df.std(2).data,std(df.data,[],2,'omitnan'))
            t.verifyEqual(df.std(2,1).data,std(df.data,1,2,'omitnan'))
        end
        
        function isalignedTest1D(t)
            df = frames.DataFrame([1 2;10 0],{[]},{[]});
            t.verifyTrue(df.isaligned(df,df,df))
            df2 = frames.DataFrame([1 2;10 0],{[2 3]'},{[]});
            t.verifyFalse(df.isaligned(df2))
            t.verifyTrue(df.isaligned(df2,'columns'))
            t.verifyFalse(df.isaligned(df2,'rows'))
            df3 = frames.DataFrame([1 2;10 0],{[2 3]'},{[1,2]'});
            t.verifyFalse(df2.isaligned(df3))
            t.verifyFalse(df2.isaligned(df3,'columns'))
            t.verifyTrue(df2.isaligned(df3,'rows'))
        end
        
        function equalsTest1D(t)
            df=frames.DataFrame([1 2;3 4],{[]});
            df2=frames.DataFrame([1 2;3 4],{[]})+0.5;
            t.verifyTrue(df.equals(df2,1))
            t.verifyFalse(df.equals(df2))
        end
        
        function eqTest1D(t)
            df=frames.DataFrame([1 2;1 2],{[]},{[]});
            df2=frames.DataFrame([1 2],{[]},{[]});
            series=df2.asRowSeries();
            t.verifyEqual(df==series,frames.DataFrame([true true;true true],{[]},{[]}))
            t.verifyError(@()df==df2,'frames:Index:align:unequalIndex')
            
            df1 = frames.DataFrame([1 NaN],{[]},{[]});
            t.verifyEqual(df1==df2,frames.DataFrame([true false],{[]},{[]}));
            t.verifyEqual(df1.data==df2,frames.DataFrame([true false],{[]},{[]}));
            dfs = frames.DataFrame({'cc' 'aa'},{[]},{[]});
            t.verifyEqual(dfs==dfs,frames.DataFrame([true true],{[]},{[]}));
            t.verifyEqual('cc'==dfs,frames.DataFrame([true false],{[]},{[]}));
        end
        
        function anyTest1D(t)
            df=frames.DataFrame([false true; false false],{[]},{[]});
            t.verifyEqual(df.any(1),frames.DataFrame([false true],{[]},{[]},RowSeries=true));
            t.verifyEqual(df.any(1).any(2),true);
            t.verifyEqual(df.all(2),frames.DataFrame([false false]',{[]},{[]},ColSeries=true));
        end
%         
%         function selectFromTimeRangeTest(t)
%             tf = frames.TimeFrame(1,738318:738318+10); % 11 June 2021 to 21 June 2021
%             sel1 = tf("09.06.2021:14.06.2021:dd.MM.yyyy");
%             tr = timerange("09-Jun-2021","14-Jun-2021",'closed');
%             sel2 = tf(tr);
%             sel3 = tf("-inf:14-Jun-2021");
%             sel4 = tf({-inf,datetime("14.06.2021",Format='dd.MM.yyyy')});
%             sel5 = tf({"11-Jun-2021","14-Jun-2021"}); %#ok<CLARRSTR>
%             sel6 = tf(738318:738318+3);
%             expected = frames.TimeFrame(1,738318:738318+3);  % 11 June 2021 to 14 June 2021
%             t.verifyEqual(sel1,expected)
%             t.verifyEqual(sel2,expected)
%             t.verifyEqual(sel3,expected)
%             t.verifyEqual(sel4,expected)
%             t.verifyEqual(sel5,expected)
%             t.verifyEqual(sel6,expected)
%             
%             selSpecific = tf(["11-Jun-2021","14-Jun-2021"]);
%             expectedSpecific = frames.TimeFrame(1,[738318,738318+3]);  % 11 June 2021 and 14 June 2021
%             t.verifyEqual(selSpecific,expectedSpecific)
%             
%             % not possible to turn it into a timerange (use [] to get specific observations)
%             t.verifyError(@() tf({"11-Jun-2021","12-Jun-2021","14-Jun-2021"}),'TimeIndex:cellstrnotsupported') %#ok<CLARRSTR>
%             t.verifyError(@() frames.TimeFrame(1,{'11-Jun-2021','12-Jun-2021'}),'TimeIndex:cellstrnotsupported')
%             
%             t.verifyEqual(tf(withtol(datetime("18-Jun-2021"),days(1))), ...
%                 tf("17-Jun-2021:19-Jun-2021"))
%             
%             % verify that ':' works as expected
%             t.verifyEqual(tf(:),tf{:})
%             t.verifyEqual(tf(:),tf)
%             
%             durtf = frames.TimeFrame(1,seconds(1:3));
%             t.verifyEqual(durtf(:),durtf{':'})
%             t.verifyEqual(durtf(':'),durtf)
%             
%         end
%         
         function aggregateMatrixTest(t)
             % check aggregation functions
             
             % 1D checks
             df = t.dfMissing1;
             t.verifyEqual(df.sum(),frames.DataFrame([12 13 12],{},df.columns,RowSeries=true))
             t.verifyEqual(df.sum(2),frames.DataFrame([8 7 4 5 8 5]',df.getRowsObj(),[],ColSeries=true))
             t.verifyEqual(df.sum(':').sum(2,":"),37)
             
             % 2D checks (aggregate full index)
             df = t.df3Missing1;             
             t.verifyEqual(df.sum(),frames.DataFrame([12 13 12],{[]},df.columns,RowSeries=true))
             t.verifyEqual(df.sum(2),frames.DataFrame([8 7 4 5 8 5]',df.getRowsObj(),[],ColSeries=true))
             t.verifyEqual(df.sum(':').sum(2,":"),37)
             
             % 2D checks (aggregate only sub-dimension(s))             
             dfa = df';
             t.verifyEqual(df.sum("dim1").col("Var2"), ...
                 frames.DataFrame([4 1 8]', ...
                     frames.MultiIndex({{"a",11},{"a",22},{"b",11}},name=["dim2","dim3"],Unique=true), colSeries=true))
                             
             %t.verifyEqual(dfa.sum(2,"dim1").row("Var2"), ...
             %    frames.DataFrame([4 1 8], frames.Index(string(missing), name="", Singleton=true,Unique=true), ...
             %    frames.MultiIndex({{"a",11},{"a",22},{"b",11}},name=["dim2","dim3"]), rowSeries=true))
             
             t.verifyEqual(df.std("dim2",1), df.std("rows","dim2",1));
             t.verifyEqual(dfa.var(2,"dim2",1), dfa.var("columns","dim2",1));
             t.verifyEqual(df.sum("dim2").sum("dim1"), df.sum(["dim2","dim1"]));
             t.verifyEqual(df.median(), df.median(["dim2","dim1","dim3"]));
             
             t.verifyError(@() df.mean("wrong"),'frames:MultiIndex:getDimInd:notAllDimFound');
         end
%         
%         function maxminTest(t)
%             df = frames.DataFrame([4 NaN;3 1]);
%             t.verifyEqual(df.maxOf(3).data,[4 3;3 3])
%             t.verifyEqual(df.maxOf(df+1),df+1)
%             [~,colmax1min2] = df.max().min(2);
%             t.verifyEqual(colmax1min2,"Var2")
%             [~,idxmax2min1] = df.max(2).min();
%             t.verifyEqual(idxmax2min1,2)
%             df2 = df;
%             df2.rows(end) = 7;
%             t.verifyError(@misaligned,'frames:Index:align:unequalIndex')
%             function misaligned(), df.maxOf(df2); end
%             
%             df = frames.DataFrame([1 10;8 0]);
%             [df1,idx1] = df.max(1);
%             [df2,idx2] = df.max(2);
%             t.verifyEqual({frames.DataFrame([8 10]).asRowSeries(),[2;1]},{df1,idx1})
%             t.verifyEqual({frames.DataFrame([10;8]).asColSeries(),["Var2","Var1"]},{df2,idx2})
%         end
%         
        function nansumTest(t)
            df1 = frames.DataFrame([1 NaN;NaN 4],{[]},{[]});
            df2 = frames.DataFrame([1 2;NaN 4],{[]},{[]});
            df3 = frames.DataFrame([1 2;NaN 4],{[2 3]'},{[]});
            t.verifyEqual(df1.nansum(df1,df1),3.*df1)
            t.verifyEqual(df1.nansum(df2),frames.DataFrame([2 2;NaN 8],{[]},{[]}))
            t.verifyEqual(df1.nansum(df2.data),frames.DataFrame([2 2;NaN 8],{[]},{[]}))
            
            t.verifyError(@()df1.nansum(2),'frames:nansum:differentSize')
            t.verifyError(@()df1.nansum(df3),'frames:nansum:notAligned')
        end
        
        function covcorrTest(t)
            df = t.dfMissing1;
            cor = df.corr();
            cov = df.cov();
            t.verifyEqual(cor.rows,cov.columns')
        end
        
        function dropMissingTest(t)
            df = frames.DataFrame([NaN NaN; NaN 1],{string([1 2])},{{'a'},{'b'}}); % cell array of char not supported as direct input for a single dimension, need to split it up
            dany = df.dropMissing(How='any');
            t.verifyEqual(dany,frames.DataFrame(double.empty(0,2),{string.empty(0,1)},{{'a'},{'b'}}));
            dall = df.dropMissing(How='all');
            t.verifyEqual(dall,frames.DataFrame([NaN 1],{string(2)},{{'a'},{'b'}}));
            dall2 = df.dropMissing(How='all',Axis=2);
            t.verifyEqual(dall2,frames.DataFrame([NaN 1]',{string([1 2])},{{'b'}})); % nested cell to force interpretation as MultiIndex
            dfstring = df;
            dfstring.data = string(df.data);
            dall2string = dfstring.dropMissing(How='all',Axis=2);
            t.verifyEqual(dall2string,frames.DataFrame(string([NaN 1]'),{string([1 2])},{{'b'}}));
        end
        
        function rollingEwmTest(t)            
            % 2D check
            df = frames.DataFrame([1 2 3 3 2 1;2 5 NaN 1 3 2;5 0 1 1 3 2]',{1:6,11:16});
            t.verifyEqual(df.rolling(4).sum().data,[NaN NaN 6 9 10 9;NaN NaN NaN 8 9 6;NaN NaN 6 7 5 7]');
            
            covdf = df.rolling(6).cov(df{:,3}.asColSeries());
            covVal = cov(df.data(:,[2,3]),'partialrows');
            t.verifyEqual(covdf.data(end,2),covVal(1,2),AbsTol=t.tol)
            
            cordf = df.rolling(6).corr(df{:,2}.asColSeries());
            corVal = corrcoef(df.data(:,[2,3]),Rows='pairwise');
            t.verifyEqual(cordf.data(end,3),corVal(1,2),AbsTol=t.tol)
            
            beta23 = cov(df.dropMissing(How='any').data(2:end,[2,3]),'partialrows') ./ var(df.dropMissing(How='any').data(2:end,[2,3]));
            beta2y = df{:,2}.asColSeries().rolling(5).betaXY(df);
            beta3y = df{:,3}.asColSeries().rolling(5).betaXY(df);
            betax3 = df.rolling(5).betaXY(df{:,3}.asColSeries());
            
            t.verifyEqual(beta2y.data(end,3),beta23(2,1),AbsTol=t.tol)
            t.verifyEqual(beta3y.data(end,2),beta23(1,2),AbsTol=t.tol)
            t.verifyEqual(betax3.data(end,2),beta23(2,1),AbsTol=t.tol)
            
            t.verifyEqual(df.ewm(Alpha=0.3).var().data(1,:),[NaN NaN NaN])
            t.verifyEqual(df.ewm(Alpha=0.3).mean().data,df.ewm(Window=2/0.3-1).mean().data,AbsTol=t.tol)
        end
        
        
        function dataNDTest(t)
            % check dataND function
            dat = magic(4);
            
            % dataframe with Index indices
            df = frames.DataFrame(dat, [1,2,3,4], ColDim="Col");            
            [datout, dimnames, dimvalues] = df.dataND();
            t.verifyEqual(datout, dat);
            t.verifyEqual(dimnames, ["Row","Col"]);
            t.verifyEqual(dimvalues,{[1;2;3;4],["Var1";"Var2";"Var3";"Var4"]});
            
            % dataframe with Index indices, non-unique
            warning('off', 'frames:Index:notUnique');
            df = frames.DataFrame(dat, frames.Index([1 2 3 2],unique=false) );
            warning('on', 'frames:Index:notUnique');
            t.verifyError(@() df.dataND(), 'frames:DataFrame:dataND:rowsIndexNotUnique');
            
            % dataframe with 2d MultiIndex rows & 1d column Index
            df = frames.DataFrame(dat(:,1:2), {[1,3,2,2], [1,2,1,2]}, ["Var2","Var1"], RowDim=["x","y"], ColDim="Col");
            [datout, dimnames, dimvalues] = df.dataND();
            t.verifyEqual(datout, cat(3,[2,NaN;7,14;NaN,11],[16,NaN;9,4;NaN,5]));
            t.verifyEqual(dimnames, ["x","y","Col"]);
            t.verifyEqual(dimvalues,{[1;2;3],[1;2],["Var1";"Var2"]});
            
            % colseries
            [datout, dimnames, dimvalues] = df.col("Var1").dataND();
            t.verifyEqual(datout, [2,NaN;7,14;NaN,11]);
            t.verifyEqual(dimnames, ["x","y"]);
            t.verifyEqual(dimvalues,{[1;2;3],[1;2]});
            
            % dataframe with 2D MultiIndex rows & columns
            df = frames.DataFrame(dat(:,1:2), {[1,3,2,2], [1,2,1,2]}, {["Var2","Var1"],[1,2]}, ...
                   RowDim=["x","y"], ColDim=["B","A"]);
            [datout, dimnames, dimvalues] = df.dataND();
            t.verifyEqual(datout, cat(4,cat(3,NaN(3,2),[16,NaN;9,4;NaN,5]),cat(3,[2,NaN;7,14;NaN,11],NaN(3,2))));
            t.verifyEqual(dimnames, ["x","y","B","A"]);
            t.verifyEqual(dimvalues,{[1;2;3],[1;2],["Var1";"Var2"],[1;2]}); 
             
            % rowseries
            [datout, dimnames, dimvalues] = df.row({3,2}).dataND();
            t.verifyEqual(datout, [NaN,11;5,NaN]);
            t.verifyEqual(dimnames, ["B","A"]);
            t.verifyEqual(dimvalues,{["Var1";"Var2"],[1;2]});            
        end
        
        
        function fromDataNDtest(t)
            dataND = cat(3,[2,NaN;7,14;NaN,11],[16,NaN;9,4;NaN,5]);
            % input errors
            t.verifyError(@() frames.DataFrame.fromDataND( dataND, {["a","b","c"],[1,2]},["x","y","z"]), ...
                'frames:DataFrame:fromDataND:invaliddimvalues');
            t.verifyError(@() frames.DataFrame.fromDataND( dataND, {["a","b","c"],[1,2],[1,2,3]},["x","y","z"]), ...
                'frames:DataFrame:fromDataND:invaliddimvalues');            
            t.verifyError(@() frames.DataFrame.fromDataND( dataND, {["a","b","c"],[1,2],[1,2]},["x","y"]), ...
                'frames:DataFrame:fromDataND:invaliddimnames');
            
            % dataframe colseries
            df1a = frames.DataFrame.fromDataND(dataND,{["a","b","c"],[1,2],["A","B"]},["X","Y","Z"]);
            df1b = frames.DataFrame.fromDataND(dataND,{["a","b","c"],[1,2],["A","B"]},["X","Y","Z"], ColDim=[]);
            df1c = frames.DataFrame.fromDataND(dataND,{["a","b","c"],[1,2],["A","B"]},["X","Y","Z"], RowDim=["X","Y","Z"]);
            df1_ref = frames.DataFrame( dataND(:),{["a","b","c","a","b","c","a","b","c","a","b","c"], ...
                                                  [1 1 1 2 2 2 1 1 1 2 2 2], ...
                                                  ["A","A","A","A","A","A","B","B","B","B","B","B"]}, ...
                                                  [],   RowDim=["X","Y","Z"], colseries=true);
            t.verifyEqual(df1a,df1_ref);
            t.verifyEqual(df1b,df1_ref);
            t.verifyEqual(df1c,df1_ref);
            
            % dataframe 2 rows, 1 col
            df2a = frames.DataFrame.fromDataND( dataND, {["a","b","c"],[1,2],["A","B"]}, ["X","Y","Z"], ...
                                   RowDim=["Y","Z"],ColDim=["X"]);
            df2b = frames.DataFrame.fromDataND( permute(dataND,[2,3,1]),...
                                  {[1,2], ["A","B"], ["a","b","c"]}, ["Y","Z","X"], RowDim=["Y","Z"],ColDim=["X"]);
            df2c = frames.DataFrame.fromDataND( permute(dataND,[2,3,1]),...
                                  {[1,2], ["A","B"], ["a","b","c"]}, ["Y","Z","X"], ColDim=["X"]);
            df2d = frames.DataFrame.fromDataND( permute(dataND,[2,3,1]),...
                                  {[1,2], ["A","B"], ["a","b","c"]}, ["Y","Z","X"], RowDim=["Y","Z"]);                              
                               
            df2_ref = frames.DataFrame( reshape(dataND,3,4)', {[1,2,1,2], ["A","A","B","B"]},{["a","b","c"]}, ...
                                                    RowDim=["Y","Z"], ColDim=["X"]);
            t.verifyEqual(df2a,df2_ref);
            t.verifyEqual(df2b,df2_ref);
            t.verifyEqual(df2c,df2_ref);
            t.verifyEqual(df2d,df2_ref);
            
            % check dim errors
            t.verifyError(@() frames.DataFrame.fromDataND(dataND,{[1,2,3],[1,2],[1,2]},["X","Y","Z"], ...
                 RowDim=["Y","Z"],ColDim=["X","Y"]),'frames:DataFrame:fromDataND:invaliddims');
            t.verifyError(@() frames.DataFrame.fromDataND(dataND,{[1,2,3],[1,2],[1,2]},["X","Y","Z"], ...
                 RowDim=["Y","Z"],ColDim=["Y"]),'frames:DataFrame:fromDataND:invaliddims');
            t.verifyError(@() frames.DataFrame.fromDataND(dataND,{[1,2,3],[1,2],[1,2]},["X","Y","Z"], ...
                 RowDim=["Y","ZZZ"],ColDim=["X"]),'frames:DataFrame:fromDataND:invaliddims');   
        end
        
         
     end
end
