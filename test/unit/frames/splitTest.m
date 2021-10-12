classdef (SharedTestFixtures = {matlab.unittest.fixtures.PathFixture('../../../')} ) ...
        splitTest < matlab.unittest.TestCase
    
    methods(Test)
        
        function splitApplyTest(t)
            
            rowseries = frames.DataFrame(["grp2" "grp1" "grp2" "grp2"], RowSeries=true);
            g1 = frames.Groups(rowseries);
            series = frames.DataFrame([10 20 30 40], RowSeries=true);
            s1 = series.split(g1).apply(@(x) sum(x,2), 'applyToData');
            s2 = series.split(g1).apply(@sum, 2, 'applyToData');
            s3 = series.split(g1).apply(@(x) x.sum(2), 'applyToFrame');
            t.verifyEqual(s1,frames.DataFrame([80 20 80 80]).asRowSeries())
            t.verifyEqual(s1,s2)
            t.verifyEqual(s1,s3)
            
            df = frames.DataFrame([1 2 3;4 5 6], [], [2 1 3]);
            gcell = {[3 1],2};
            g2 = frames.Groups(gcell);
            s4 = df.split(g2).apply(@(x) sum(x,2), 'applyToData');
            t.verifyEqual(s4,frames.DataFrame([1 5 5;4 11 11],[],[2 1 3]))
            
            df = frames.DataFrame([1 2 3 30;4 5 6 60]);
            gcell = frames.DataFrame([0 22 0 0;0 22 6 22]);
            g3 = frames.Groups(gcell);
            s5 = df.split(g3).apply(@(x) sum(x,2));
            t.verifyEqual(s5,frames.DataFrame([34 2 34 34;4 65 6 65]))
            
        end
        
        function splitAggregateTest(t)
            
            rowseries = frames.DataFrame(["grp2" "grp1" "grp2" "grp2"], RowSeries=true);
            g1 = frames.Groups(rowseries);
            series = frames.DataFrame([10 20 30 40],RowSeries=true);
            s1 = series.split(g1).aggregate(@(x) sum(x,2));
            s2 = series.split(g1).aggregate(@sum, 2, 'applyToData');
            s3 = series.split(g1).aggregate(@(x) x.sum(2), 'applyToFrame');
            t.verifyEqual(s1,frames.DataFrame([80 20],[],["grp2" "grp1"]).asRowSeries())
            t.verifyEqual(s1,s2)
            t.verifyEqual(s1,s3)
            
            df = frames.DataFrame([1 2 3;4 5 6], [], [2 1 3]);
            gcell = {[3 1],2};
            g2 = frames.Groups(gcell);
            s4 = df.split(g2).aggregate(@(x) sum(x,2));
            t.verifyEqual(s4,frames.DataFrame([5 1;11 4],[],["Group1" "Group2"]))
            
            df = frames.DataFrame([1 2 3 30;4 5 6 60]);
            gcell = frames.DataFrame([0 22 0 0;0 22 6 22]);
            g3 = frames.Groups(gcell);
            s5 = df.split(g3).aggregate(@(x) sum(x,2), 'applyToData');
            t.verifyEqual(s5,frames.DataFrame([34 NaN 2;4 6 65],[],[0 6 22]))
            
        end
        
        function splitApplyRowTest(t)
            
            rowseries = frames.DataFrame(["grp2" "grp1" "grp2" "grp2"]', ColSeries=true);
            g1 = frames.Groups(rowseries,'rowGroups');
            series = frames.DataFrame([10 20 30 40]', ColSeries=true);
            s1 = series.split(g1).apply(@(x) sum(x), 'applyToData');
            s2 = series.split(g1).apply(@sum, 1);
            s3 = series.split(g1).apply(@(x) x.sum(), 'applyToFrame');
            t.verifyEqual(s1,frames.DataFrame([80 20 80 80]').asColSeries())
            t.verifyEqual(s1,s2)
            t.verifyEqual(s1,s3)
            
            df = frames.DataFrame([1 2 3;4 5 6]', [2 1 3]);
            gcell = {[3 1],2};
            g2 = frames.Groups(gcell,'rowGroups');
            s4 = df.split(g2).apply(@(x) sum(x,1), 'applyToData');
            t.verifyEqual(s4,frames.DataFrame([1 5 5;4 11 11]',[2 1 3]))
            
            df = frames.DataFrame([1 2 3 30;4 5 6 60]');
            gcell = frames.DataFrame([0 22 0 0;0 22 6 22]');
            g3 = frames.Groups(gcell,'rowGroups');
            s5 = df.split(g3).apply(@(x) x.sum(), 'applyToFrame');
            t.verifyEqual(s5,frames.DataFrame([34 2 34 34;4 65 6 65]'))
            
        end
        
        function splitAggregateRowTest(t)
            
            rowseries = frames.DataFrame([2 1 2 2]', ColSeries=true);
            g1 = frames.Groups(rowseries,'rowGroups');
            series = frames.DataFrame([10 20 30 40]');
            s1 = series.split(g1).aggregate(@(x) sum(x,1), 'applyToData');
            s2 = series.split(g1).aggregate(@sum, 1, 'applyToData');
            s3 = series.split(g1).aggregate(@(x) x.sum(), 'applyToFrame');
            t.verifyEqual(s1,frames.DataFrame([80 20]',[2 1]))
            t.verifyEqual(s1,s2)
            t.verifyEqual(s1,s3)
            
            df = frames.DataFrame([1 2 3;4 5 6]', [2 1 3]);
            gcell = {[3 1],2};
            g2 = frames.Groups(gcell,'rowGroups');
            s4 = df.split(g2).aggregate(@(x) sum(x,1), 'applyToData');
            t.verifyEqual(s4,frames.DataFrame([5 1;11 4]',["Group1" "Group2"]))
            
            df = frames.DataFrame([1 2 3 30;4 5 6 60]');
            gcell = frames.DataFrame([0 22 0 0;0 22 6 22]');
            g3 = frames.Groups(gcell,'rowGroups');
            s5 = df.split(g3).aggregate(@(x) sum(x), 'applyToData');
            t.verifyEqual(s5,frames.DataFrame([34 NaN 2;4 6 65]',[0 6 22]))
            
        end
        
        function timeframeTest(t)
            rows = 738336 - 200 : 738336;
            dates = datetime(rows,'ConvertFrom','datenum',Format='dd-MMM-yyyy');
            months = month(dates);
            
            s=struct();
            for m = unique(months,'stable')
                vals = dates(months == m);
                s.(string(month(vals(1),'name'))) = vals;
            end
            
            g = frames.Groups(s,'rowGroups');
            tf = frames.TimeFrame(1,dates);
            nbdays = tf.split(g).aggregate(@sum);
            t.verifyEqual(nbdays, ...
                frames.DataFrame([21;31;28;31;30;31;29],...
                {'December','January','February','March','April','May','June'}))
        end
        
        function unordedgroupsTest(t)
            groups = frames.Groups(frames.DataFrame([5 5;5 5;NaN 1; 1 1;NaN NaN; 5 1]));
            data = frames.DataFrame([1 2;3 4;5 6;7 8;9 10;11 12]);
            sol = data.split(groups).apply(@(x) sum(x,2));
            expected = [3 3;7 7;NaN 6;15 15;NaN NaN; 11 12];
            expected = frames.DataFrame(expected);
            
            t.verifyEqual(sol,expected)
            
            sol = data.split(groups).aggregate(@(x) sum(x,2));
            expected = [NaN 3;NaN 7;6 NaN;15 NaN;NaN NaN; 12 11];
            expected = frames.DataFrame(expected,[],[1 5]);
            
            t.verifyEqual(sol,expected)
            
            groups = frames.Groups(frames.DataFrame([5 5;5 5;NaN 1; 1 1;NaN NaN; 5 1]),'rowGroups');
            sol = data.split(groups).aggregate(@sum);
            expected = frames.DataFrame([7 26;15 6],[1 5]);
            
            t.verifyEqual(sol,expected)
        end
        
        function spanErrorTest(t)
            df = frames.DataFrame([1 2 3 4 5],[],[1 2 3 4 5]);
            t.verifyError(@() df.split(frames.Groups({[1 2 3 5]})), ...
                'frames:SplitNonexhaustive')
            t.verifyError(@() df.split(frames.Groups({[1 2 3 5], [4 5]})), ...
                'frames:SplitOverlap')

            t.verifyEqual(df.split(frames.Groups({[1 2 3 5], [4 5]}),'allowOverlaps').aggregate(@sum,2).data,[11,9])
            t.verifyEqual(df.split(frames.Groups({[1 2 3 5]}),'isNonExhaustive').aggregate(@sum,2).data,11)
        end
    end
end

