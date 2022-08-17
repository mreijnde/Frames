classdef alignTest < AbstractFramesTests
    
    %#ok<*ASGLU> 
    methods(Test)
        function basicTest(t)
            df1 = frames.DataFrame([10 50 100 150]',[1 5 10 15]).setRowsType('sorted');
            df2 = frames.DataFrame([20 50 90 150]',[2 5 9 15]).setRowsType('sorted');
            [df1a,df2a] = frames.align(df1,df2);
            t.verifyEqual(df1a.data,[10 NaN 50 NaN 100 150]');
            t.verifyEqual(df1a.rows,[1 2 5 9 10 15]');
            t.verifyEqual(df2a.data,[NaN 20 50 90 NaN 150]');
            t.verifyEqual(df2a.rows,[1 2 5 9 10 15]');
            
            df1aSingleOutput = frames.align(df1,df2,df1,df1,df2);
            t.verifyEqual(df1a,df1aSingleOutput);

            a = frames.TimeFrame([1,11], [2 3], [2 3]).setColumnsType('sorted').setRowsType('sorted');
            b = frames.TimeFrame([2,22], [1 3], [1 3]).setColumnsType('sorted').setRowsType('sorted');
            [x, y] = frames.align(a, b, dimension='both');
            xExp = frames.TimeFrame([NaN NaN NaN; NaN 1 11; NaN 1 11], [1 2 3], [1 2 3]).setColumnsType('sorted').setRowsType('sorted');
            yExp = frames.TimeFrame([2 NaN 22; NaN NaN NaN; 2 NaN 22], [1 2 3], [1 2 3]).setColumnsType('sorted').setRowsType('sorted');
            t.verifyEqual(x, xExp)
            t.verifyEqual(y, yExp)
        end

        function rowTest(t)
            a = frames.DataFrame([1;11], [1 3], [1 2]);
            b = frames.DataFrame([2;22], [2 3], [1 3]);
            [x, y] = frames.align(a, b, dimension='rows');
            xExp = frames.DataFrame([1 1; 11 11; NaN NaN], [1 3 2], [1 2]);
            yExp = frames.DataFrame([NaN NaN; 22 22; 2 2], [1 3 2], [1 3]);
            t.verifyEqual(x, xExp)
            t.verifyEqual(y, yExp)

            a = frames.DataFrame([1;11], [1 3], [1 2]).setRowsType('sorted');
            b = frames.DataFrame([2;22], [2 3], [1 3]).setRowsType('sorted');
            [x, y] = frames.align(a, b, dimension='rows');
            xExp = frames.DataFrame([1 1; NaN NaN; 11 11], [1 2 3], [1 2]).setRowsType('sorted');
            yExp = frames.DataFrame([NaN NaN; 2 2; 22 22], [1 2 3], [1 3]).setRowsType('sorted');
            t.verifyEqual(x, xExp)
            t.verifyEqual(y, yExp)

            a = frames.DataFrame([1 10;11 110], [1 3], [3 2]);
            b = frames.DataFrame([2;22], [2 3], [1 3]);
            c = frames.DataFrame([3;33;333], [4 1 2]);
            xExp = frames.DataFrame([1 10; 11 110; NaN NaN; NaN NaN], [1 3 2 4], [3 2]);
            yExp = frames.DataFrame([NaN NaN; 22 22; 2 2; NaN NaN], [1 3 2 4], [1 3]);
            zExp = frames.DataFrame([33;NaN;333;3], [1 3 2 4]);

            [x, y] = frames.align(a, b, c, dimension='rows');
            t.verifyEqual(x, xExp)
            t.verifyEqual(y, yExp)

            [x, y, z] = frames.align(a, b, c, dimension='rows');
            t.verifyEqual(x, xExp)
            t.verifyEqual(z, zExp)

            [x, y, z, ind_rows, ind_cols] = frames.align(a, b, c, dimension='rows');
            t.verifyEqual(ind_rows,    [ 1   NaN     2;
                                         2     2   NaN;
                                       NaN     1     3;
                                       NaN   NaN     1 ])
            t.verifyTrue(isempty(ind_cols))
        end

        function columnTest(t)

            a = frames.DataFrame([1,11], [1 3], [3 2]);
            b = frames.DataFrame([2,22], [2 3], [1 3]);
            [x, y] = frames.align(a, b, dimension='columns');
            xExp = frames.DataFrame([1 11 NaN; 1 11 NaN], [1 3], [3 2 1]);
            yExp = frames.DataFrame([22 NaN 2; 22 NaN 2], [2 3], [3 2 1]);
            t.verifyEqual(x, xExp)
            t.verifyEqual(y, yExp)

            a = frames.DataFrame([1,11], [1 3], [2 3]).setColumnsType('sorted');
            b = frames.DataFrame([2,22], [2 3], [1 3]).setColumnsType('sorted');
            [x, y] = frames.align(a, b, dimension='columns');
            xExp = frames.DataFrame([NaN 1 11; NaN 1 11], [1 3], [1 2 3]).setColumnsType('sorted');
            yExp = frames.DataFrame([2 NaN 22; 2 NaN 22], [2 3], [1 2 3]).setColumnsType('sorted');
            t.verifyEqual(x, xExp)
            t.verifyEqual(y, yExp)
        end

        function duplicateTest(t)
            warning('off', 'frames:Index:notUnique')
            a = frames.DataFrame([1 2 3],[],[1 1 1]);
            b = frames.DataFrame([1 2],[],[1 1]);
            t.verifyError(@() frames.align(a,b), 'frames:Index:align:notUnique')
            [c, d] = frames.align(a,b,duplicateOption='duplicates');
            cExp = frames.DataFrame([1 2 3],[],[1 1 1]);
            dExp = frames.DataFrame([1 2 NaN],[],[1 1 1]);
            t.verifyEqual(c, cExp)
            t.verifyEqual(d, dExp)
            [c, d] = frames.align(a,b,duplicateOption='unique');
            cExp = frames.DataFrame(1,[],1);
            dExp = frames.DataFrame(1,[],1);
            t.verifyEqual(c, cExp)
            t.verifyEqual(d, dExp)
            [c, d] = frames.align(a,b,duplicateOption='duplicates');
            dExp = frames.DataFrame([1 2 NaN],[],[1 1 1]);
            t.verifyEqual(c, a)
            t.verifyEqual(d, dExp)
            warning('on', 'frames:Index:notUnique')
        end

        function noInputTest(t)
            t.verifyError(@() frames.align(), 'MATLAB:align:WrongNumberInputs')
        end

        function tooManyOutputTest(t)
            t.verifyError(@f, 'MATLAB:unassignedOutputs')
            function f(), [a,b,c,d] = frames.align(frames.DataFrame(1)); end
        end

        
    end
end
