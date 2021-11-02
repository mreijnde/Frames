classdef splitTest < AbstractFramesTests

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
            t.verifyEqual(df.split(frames.Groups({[1 2 3 5]}),'allowNonExhaustive').aggregate(@sum,2).data,11)
        end
        
        function byLine(t)
            df = frames.DataFrame([1 2 3 4 5],[1 2 3 4],[1 2 3 4 5]);
            groups = frames.Groups({[1 2], [3 4 5]});
            sol1 = df.split(groups).apply(@(x) mean(x,2),'applyByLine');
            t.verifyEqual(df.split(groups).apply(@(x) mean(x),'applyByLine'), sol1)
            t.verifyEqual(frames.DataFrame([1.5 1.5 4 4 4],[1 2 3 4],[1 2 3 4 5]), sol1)
            
            df = frames.DataFrame([1 2 3 4 5]',[1 2 3 4 5],[1 2 3 4]);
            groups = frames.Groups({[1 2], [3 4 5]},'rowGroups');
            sol1 = df.split(groups).apply(@(x) mean(x,1),'applyByLine');
            t.verifyEqual(df.split(groups).apply(@(x) mean(x),'applyByLine'), sol1)
            t.verifyEqual(frames.DataFrame([1.5 1.5 4 4 4]',[1 2 3 4 5],[1 2 3 4]), sol1)
            
            df = frames.DataFrame([1 2 3 4 5],[1 2],[1 2 3 4 5]);
            groups = frames.Groups(frames.DataFrame([1 1 2 2 2; 1 1 1 2 2],[1 2],[1 2 3 4 5]));
            t.verifyEqual(df.split(groups).apply(@(x) x.mean(2),'applyByLine','applyToFrame'), ...
                frames.DataFrame([1.5 1.5 4 4 4;2 2 2 4.5 4.5],[1 2],[1 2 3 4 5]))


        end
        
        function multipleFrames(t)
            df1 = frames.TimeFrame([1 2 3 4 5 6 7 8 9 10;1 1 1 1 1 1 1 1 1 1]);
            tiebreaker = frames.TimeFrame([1 1 1 1 1 1 1 1 1 1;10 9 8 7 6 5 4 3 2 1]);
            groupsDF = frames.TimeFrame([1 1 1 1 2 2 1 1 2 1;2 1 1 1 1 2 1 1 1 2]);
            groups = frames.Groups(groupsDF);
            sol = frames.Split({df1,tiebreaker},groups).apply(@sorter,'applyByLine');
            expected = frames.TimeFrame([1 2 3 4 1 2 5 6 3 7;3 7 6 5 4 2 3 2 1 1]);
            t.verifyEqual(sol,expected)
            function out = sorter(data)
                for ii = 1:numel(data), data{ii} = data{ii}'; end
                tb = sortrows(table(data{:},(1:size(data{1},1))'));
                out = tb{:,end}';
            end
            
            df1 = frames.TimeFrame([1 2 3 4 5 6 7 8 9 10;1 1 1 1 1 1 1 1 1 1]);
            tiebreaker = frames.TimeFrame([1 1 1 1 1 1 1 1 1 1;10 9 8 7 6 5 4 3 2 1]);
            groupsDF = frames.TimeFrame([1 1 1 1 2 2 1 1 2 1;2 1 1 1 1 2 1 1 1 2]);
            groups = frames.Groups(groupsDF);
            sol = frames.Split({df1,tiebreaker},groups).apply(@sorterDF,'applyByLine','applyToFrame');
            expected = frames.TimeFrame([1 2 3 4 1 2 5 6 3 7;3 7 6 5 4 2 3 2 1 1]);
            t.verifyEqual(sol,expected)
            function out = sorterDF(data)
                for ii = 1:numel(data), data{ii} = data{ii}.data'; end
                tb = sortrows(table(data{:},(1:size(data{1},1))'));
                out = tb{:,end}';
            end
            
            df1 = frames.TimeFrame([1 2 3 4 5 6 7 8 9 10;0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1]);
            df2 = frames.TimeFrame([10 20 30 40 50 60 70 80 90 100;10 9 8 7 6 5 4 3 2 1]);
            groupsDF = frames.TimeFrame([1 1 1 1 2 2 1 1 2 1;2 1 1 1 1 2 1 1 1 2]);
            groups = frames.Groups(groupsDF);
            sol = frames.Split({df1,df2},groups).aggregate(@summer,'applyByLine','applyToData');
            expected = frames.TimeFrame([35+350, 20+200; 3.8+39,1.7+16],[],[1 2]);
            t.verifyEqual(sol,expected)
            
            sol = frames.Split({df1,df2},groups).aggregate(@summer,'applyToData');
            expected = frames.TimeFrame([35+350, 20+200; 3.8+39,1.7+16],[],[1 2]);
            t.verifyEqual(sol,expected)
            
            sol = frames.Split({df1,df2},groups).apply(@summer);
            gdfd = [1 1 1 1 2 2 1 1 2 1;2 1 1 1 1 2 1 1 1 2];
            d = NaN(size(gdfd));
            d(1,gdfd(1,:)==1) = 35+350; d(1,gdfd(1,:)==2) = 20+200;
            d(2,gdfd(2,:)==1) = 3.8+39; d(2,gdfd(2,:)==2) = 1.7+16;
            expected = frames.TimeFrame(d);
            t.verifyEqual(sol,expected)
            
            df1 = frames.TimeFrame([1 2 3 4 5 6 7 8 9 10;0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1]);
            df2 = frames.TimeFrame([10 20 30 40 50 60 70 80 90 100;10 9 8 7 6 5 4 3 2 1]);
            groupsDF = frames.TimeFrame([1 1 1 1 2 2 1 1 2 1]).asRowSeries();
            groups = frames.Groups(groupsDF);
            sol = frames.Split({df1,df2},groups).aggregate(@summer);
            expected = frames.TimeFrame([35+350, 20+200;42+3.5, 13+2],[],[1 2]);
            t.verifyEqual(sol,expected)
            function res = summer(data,dim)
                if nargin < 2, dim = 2; end
                res = 0;
                for ii = 1:numel(data), res = res + sum(data{ii},dim); end
            end
            
            df1 = frames.TimeFrame([1 2 3 4 5 6 7 8 9 10;0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1]');
            df2 = frames.TimeFrame([10 20 30 40 50 60 70 80 90 100;10 9 8 7 6 5 4 3 2 1]');
            groupsDF = frames.TimeFrame([1 1 1 1 2 2 1 1 2 1]').asColSeries();
            groups = frames.Groups(groupsDF,'rowGroups');
            sol = frames.Split({df1,df2},groups).aggregate(@(x) summer(x,1));
            expected = frames.DataFrame([35+350, 20+200;42+3.5, 13+2]',[1 2]);
            t.verifyEqual(sol,expected)

        end
        
        function paramsComb(t)
            data = frames.DataFrame([1 2 3 4;5 6 7 8]');
            data2 = data .* 10;
            groupDF = frames.DataFrame([2 1 1 2;1 1 2 2]');
            groupSeries = groupDF.col(data.columns(1));
            groupMod = frames.Groups(groupDF,'rowGroups');
            groupCst = frames.Groups(groupSeries,'rowGroups');
            
            % cst group / on matrix / single
            a = frames.Split(data,groupCst).apply(@sum);
            % cst group / on matrix / cell
            b = frames.Split({data,data2},groupCst).apply(@(x) x{1} + x{2});
            % cst group / by line / single
            c = frames.Split(data,groupCst).apply(@sum,'applyByLine');
            % cst group /  by line / cell
            d = frames.Split({data,data2},groupCst).apply(@(x) x{1} + x{2},'applyByLine');
            % mod group / on matrix / single
            e = frames.Split(data,groupMod).apply(@sum);
            % mod group / on matrix / cell
            f = frames.Split({data,data2},groupMod).apply(@(x) x{1} + x{2});
            % mod group / by line / single
            g = frames.Split(data,groupMod).apply(@sum,'applyByLine');
            % mod group /  by line / cell
            h = frames.Split({data,data2},groupMod).apply(@(x) x{1} + x{2},'applyByLine');
            
            t.verifyEqual(a,c)
            t.verifyEqual(b,d)
            t.verifyEqual(e,g)
            t.verifyEqual(f,h)
            t.verifyEqual(b,h)
            
            t.verifyEqual(a.data,[5 5 5 5;13 13 13 13]')
            t.verifyEqual(b.data,[11 22 33 44;55 66 77 88]')
            t.verifyEqual(e.data,[5 5 5 5;11 11 15 15]')
        end
        
        function missingGroup(t)
            gdf = frames.DataFrame([2 1 1 NaN 2]);
            gs = gdf.asRowSeries();
            gdf = frames.Groups(gdf);
            gs = frames.Groups(gs);
            data = frames.DataFrame([1 2 3 4 5]);
            expected = frames.DataFrame([6 5 5 NaN 6]);
            t.verifyEqual(data.split(gdf).apply(@(x) sum(x,2)),expected)
            t.verifyEqual(data.split(gs).apply(@(x) sum(x,2)),expected)
        end
        
        function misalignedGroups(t)
            data = frames.DataFrame(1,[1 2],[1 2]);
            gTT = data; gTF = data; gFT = data;
            gTF.columns = [1 3]; gFT.rows = [1 3]; 
            gFF = gTF; gFF.rows = [1 3];
            gTT = frames.Groups(gTT);
            gTF = frames.Groups(gTF,'rowGroups');
            gFT = frames.Groups(gFT,'rowGroups');
            gFF = frames.Groups(gFF);
            t.verifyWarningFree(@() frames.Split(data,gTT))
            t.verifyError(@() frames.Split(data,gFT),'Groups:rowsMisaligned')
            t.verifyError(@() frames.Split(data,gTF),'Groups:columnsMisaligned')
            t.verifyError(@() frames.Split(data,gFF),'Groups:rowsMisaligned')
            
        end
    end
end

