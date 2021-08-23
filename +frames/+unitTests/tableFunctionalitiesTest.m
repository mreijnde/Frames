classdef tableFunctionalitiesTest < matlab.unittest.TestCase
    
    properties
        
    end
    %         function varargout = groupfilter(obj,varargin)
    %         function varargout = grouptransform(obj,varargin)
    %         function varargout = groupsummary(obj,varargin)
    %         function varargout = groupcounts(obj,varargin)
    
    methods(Test)
        function joinTest(t)
            % Append Values from One Table to Another
            Tleft = table({'Janice','Jonas','Javier','Jerry','Julie'}',compose('%d',[1;2;1;2;1]),...
                'VariableNames',{'Employee' 'Department'});
            Tright = table(compose('%d',[1 2]'),{'Mary' 'Mona'}',...
                'VariableNames',{'Department' 'Manager'});
            T = join(Tleft,Tright);
            T.Properties.RowNames = compose('%d',1:height(T));
            DFleft = frames.DataFrame.fromTable(Tleft);
            DFright = frames.DataFrame.fromTable(Tright);
            DF = join(DFleft,DFright);
            t.verifyEqual(DF.t,T)
            
            % Merge Tables with One Variable in Common
            Tleft = table(compose('%d',[5;12;23;2;6]),...
                {'cereal';'pizza';'salmon';'cookies';'pizza'},...
                'VariableNames',{'Age','FavoriteFood'},...
                'RowNames',{'Amy','Bobby','Holly','Harry','Sally'});
            Tright = table({'cereal';'cookies';'pizza';'salmon';'cake'},...
                compose('%d',[110;160;140;367;243]),...
                {'B';'D';'B-';'A';'C-'},...
                'VariableNames',{'FavoriteFood','Calories','NutritionGrade'});
            T = join(Tleft,Tright);
            DFleft = frames.DataFrame.fromTable(Tleft);
            DFright = frames.DataFrame.fromTable(Tright);
            DF = join(DFleft,DFright);
            t.verifyEqual(DF.t,T)
            
            %Merge Tables by Specifying One Key Variable
            left = table([10;4;2;3;7],[5;4;9;6;1],[10;3;8;8;4]);
            right = table([6;1;1;6;8],[5;4;9;6;1]);
            T = join(left,right,'Keys','Var2');
            T.Properties.RowNames = compose('%d',1:height(T));
            DFleft = frames.DataFrame.fromTable(left);
            DFright = frames.DataFrame.fromTable(right);
            DF = join(DFleft,DFright,'Keys','Var2');
            t.verifyEqual(DF.t,T)
            
            % Merge Tables Using Row Names as Keys
            Tleft = table([1;1;0;0;0],[38;43;38;40;49],...
                'VariableNames',{'Gender' 'Age'},...
                'RowNames',{'Smith' 'Johnson' 'Williams' 'Jones' 'Brown'});
            Tright = table([64;69;67;71;64],...
                [119;163;133;176;131],...
                [122; 109; 117; 124; 125],...
                'VariableNames',{'Height' 'Weight' 'BloodPressure'},...
                'RowNames',{'Brown' 'Johnson' 'Jones' 'Smith' 'Williams'});
            T = join(Tleft,Tright,'Keys','Row');
            DFleft = frames.DataFrame.fromTable(Tleft);
            DFright = frames.DataFrame.fromTable(Tright);
            DF = join(DFleft,DFright,'Keys','Row');
            t.verifyEqual(DF.t,T)
            
            % Merge timetables
            Traffic = [0.8 0.9 0.1 0.7 0.9]';
            Noise = [0 1 1.5 2 2.3]';
            Tleft = timetable(hours(1:5)',Traffic,Noise);
            Distance = [0.88 0.86 0.91 0.9 0.86]';
            Tright = timetable(hours(1:5)',Distance);
            T = join(Tleft,Tright);
            DFleft = frames.TimeFrame.fromTable(Tleft);
            DFright = frames.TimeFrame.fromTable(Tright);
            DF = join(DFleft,DFright);
            t.verifyEqual(DF.t,T)
            
            % Merge Timetable and Table
            Measurements = compose('%d',[0.13 0.22 0.31 0.42 0.53 0.57 0.67 0.81 0.90 1.00]');
            Device = {'A';'B';'A';'B';'A';'B';'A';'B';'A';'B'};
            Tleft = timetable(seconds(1:10)',Measurements,Device);
            Device = {'A';'B'};
            Accuracy = compose('%d',[0.023;0.037]);
            Tright = table(Device,Accuracy);
            T = join(Tleft,Tright);
            DFleft = frames.TimeFrame.fromTable(Tleft);
            DFright = frames.DataFrame.fromTable(Tright);
            DF = join(DFleft,DFright);
            t.verifyEqual(DF.t,T)
            
        end
        
        function innerjoinTest(t)
            
            % Inner-Join Operation of Tables and Indices to Values
            Tleft = table({'a' 'b' 'c' 'e' 'h'}',compose('%d',[1 2 3 11 17]'),...
                'VariableNames',{'Key1' 'Var1'});
            Tright = table({'a' 'b' 'd' 'e'}',compose('%d',[4 5 6 7]'),...
                'VariableNames',{'Key1' 'Var2'});
            [T,ileft,iright] = innerjoin(Tleft,Tright);
            T.Properties.RowNames = compose('%d',1:height(T));
            DFleft = frames.DataFrame.fromTable(Tleft);
            DFright = frames.DataFrame.fromTable(Tright);
            [DF,il,ir] = innerjoin(DFleft,DFright);
            t.verifyEqual({DF.t,il,ir},{T,ileft,iright})
            
            %Inner-Join Operation of Tables Using Left and Right Keys
            left = table([10;4;2;3;7],[5;4;9;6;1],[10;3;8;8;4]);
            right = table([6;1;1;6;8],[2;3;4;5;6]);
            [T,ileft,iright] = innerjoin(left,right,'LeftKeys',1,'RightKeys',2);
            T.Properties.RowNames = compose('%d',1:height(T));
            DFleft = frames.DataFrame.fromTable(left);
            DFright = frames.DataFrame.fromTable(right);
            [DF,il,ir] = innerjoin(DFleft,DFright,'LeftKeys',1,'RightKeys',2);
            t.verifyEqual({DF.t,il,ir},{T,ileft,iright})
            
            %Inner-Join Operation of Timetables
            left = timetable(seconds([1;2;4;6]),[1 2 3 11]');
            right = timetable(seconds([2;4;6;7]),[4 5 6 7]');
            T = innerjoin(left,right);
            DFleft = frames.TimeFrame.fromTable(left);
            DFright = frames.TimeFrame.fromTable(right);
            DF = innerjoin(DFleft,DFright);
            t.verifyEqual(DF.t,T)
        end
        
        function outerjoinTest(t)
            
            %Merge Key Variable Pair to Single Variable
            Tleft = table({'a' 'b' 'c' 'e' 'h'}',compose('%d',[1 2 3 11 17]'),...
                'VariableNames',{'Key1' 'Var1'});
            Tright = table({'a','b','d','e'}',compose('%d',[4;5;6;7]),...
                'VariableNames',{'Key1' 'Var2'});
            T = outerjoin(Tleft,Tright,'MergeKeys',true);
            T.Properties.RowNames = compose('%d',1:height(T));
            DFleft = frames.DataFrame.fromTable(Tleft);
            DFright = frames.DataFrame.fromTable(Tright);
            DF = outerjoin(DFleft,DFright,'MergeKeys',true);
            t.verifyEqual(DF.t,T)
            
            % Left Outer-Join Operation of Tables and Indices to Values
            left = Tleft; right = Tright;
            [T,ileft,iright] = outerjoin(left,right,'Type','left');
            T.Properties.RowNames = compose('%d',1:height(T));
            [DF,il,ir] = outerjoin(DFleft,DFright,'Type','left');
            t.verifyEqual({DF.t,il,ir},{T,ileft,iright})
            
            
            left = timetable(seconds([1;2;4;6]),[1 2 3 11]');
            right = timetable(seconds([2;4;6;7]),[4 5 6 7]');
            T1 = outerjoin(left,right);
            T2 = outerjoin(left,right,'Type','left');
            DFleft = frames.TimeFrame.fromTable(left);
            DFright = frames.TimeFrame.fromTable(right);
            DF1 = outerjoin(DFleft,DFright);
            DF2 = outerjoin(DFleft,DFright,'Type','left');
            t.verifyEqual(DF1.t,T1)
            t.verifyEqual(DF2.t,T2)
            
            
        end
        
        function unionTest(t)
            A = table({'A';'B';'C';'D';'E'},compose('%d',[0;1;0;1;0]),'RowNames',compose('%d',(1:5)'));
            B = table({'A';'C';'E';'G';'I'},compose('%d',zeros(5,1)),'RowNames',compose('%d',(1:2:10)'));
            C = union(A,B);
            DFleft = frames.DataFrame.fromTable(A);
            DFright = frames.DataFrame.fromTable(B);
            DF = union(DFleft,DFright);
            t.verifyEqual(DF.t,C)
            
            
            
        end
        
        function intersectTest(t)
            A = table({'A';'B';'C';'D';'E'},compose('%d',[0;1;0;1;0]),'RowNames',compose('%d',(1:5)'));
            B = table({'A';'C';'E';'G';'I'},compose('%d',zeros(5,1)),'RowNames',compose('%d',(1:2:10)'));
            C = intersect(A,B);
            
            DFleft = frames.DataFrame.fromTable(A);
            DFright = frames.DataFrame.fromTable(B);
            DF = intersect(DFleft,DFright);
            DF2 = intersect(DFleft,DFright,'rows');
            t.verifyEqual(DF.t,C)
            t.verifyEqual(DF,DF2)
            
            
        end
        
        function ismemberTest(t)
            
            % ismember table does not look at rownames
            A = table({'A';'B';'C';'D';'E'},compose('%d',[0;1;0;1;0]),'RowNames',compose('%d',(1:5)'));
            B = table({'A';'C';'E';'G';'E'},compose('%d',zeros(5,1)),'RowNames',compose('%d',(1:2:10)'));
            Lia = ismember(A,B);
            DFleft = frames.DataFrame.fromTable(A);
            DFright = frames.DataFrame.fromTable(B);
            intr = ismember(DFleft,DFright);
            t.verifyEqual(intr,Lia)
            t.verifyEqual(logical([1 0 1 0 1]'),Lia)
            
            
            
            % ismember timetable does not look at rowTimes (but the help claims
            % otherwise??)
            A = timetable({'A';'B';'C';'D';'E'},compose('%d',[0;1;0;1;0]),'RowTimes',seconds((1:5)'));
            B = timetable({'A';'C';'E';'G';'E'},compose('%d',zeros(5,1)),'RowTimes',seconds((1:2:10)'));
            TTia = ismember(A,B);
            DFleft = frames.TimeFrame.fromTable(A);
            DFright = frames.TimeFrame.fromTable(B);
            intr = ismember(DFleft,DFright);
            t.verifyEqual(intr,TTia)
            t.verifyEqual(logical([1 0 1 0 1]'),TTia)
            
        end
        
        function setdiffTest(t)
            A = table({'A';'B';'C';'D';'E'},compose('%d',[0;1;0;1;0]),'RowNames',compose('%d',(1:5)'));
            B = table({'A';'C';'E';'G';'E'},compose('%d',zeros(5,1)),'RowNames',compose('%d',(1:2:10)'));
            C = setdiff(A,B);
            DFleft = frames.DataFrame.fromTable(A);
            DFright = frames.DataFrame.fromTable(B);
            DF = setdiff(DFleft,DFright);
            t.verifyEqual(DF.t,C)
            
            A = table({'M';'M';'F';'M';'F'},compose('%d',[27;52;31;46;35]),compose('%d',[74;68;64;61;64]),...
                'VariableNames',{'Gender' 'Age' 'Height'},...
                'RowNames',{'Ted' 'Fred' 'Betty' 'Bob' 'Judy'});
            B = table({'F';'M';'F';'F'},compose('%d',[64;68;62;58]),compose('%d',[31;47;35;23]),...
                'VariableNames',{'Gender' 'Height' 'Age'},...
                'RowNames',{'Meg' 'Joe' 'Beth' 'Amy'});
            [C,ia] = setdiff(A,B);
            DFleft = frames.DataFrame.fromTable(A);
            DFright = frames.DataFrame.fromTable(B);
            [DF,ia2] = setdiff(DFleft,DFright);
            t.verifyEqual({DF.t,ia2},{C,ia})
        end
        
        function setxorTest(t)
            A = table({'A';'B';'C';'D';'E'},compose('%d',[0;1;0;1;0]),'RowNames',compose('%d',(1:5)'));
            B = table({'A';'C';'E';'G';'E'},compose('%d',zeros(5,1)),'RowNames',compose('%d',(1:2:10)'));
            C = setxor(A,B);
            DFleft = frames.DataFrame.fromTable(A);
            DFright = frames.DataFrame.fromTable(B);
            DF = setxor(DFleft,DFright);
            t.verifyEqual(DF.t,C)
        end
        
        function findgroupsTest(t)
            load patients %#ok<LOAD>
            T = table(Gender,compose('%d',Smoker));
            [G,TID] = findgroups(T);
            TID.Properties.RowNames = compose('%d',1:height(TID));
            DF = frames.DataFrame.fromTable(T);
            [G2,TID2] = findgroups(DF);
            t.verifyEqual({G,TID},{G2,TID2.t})
            
            T = timetable(Gender,compose('%d',Smoker),'RowTimes',seconds(1:length(Gender))');
            [G,TID] = findgroups(T);
            TID.Properties.RowNames = compose('%d',1:height(TID));
            DF = frames.TimeFrame.fromTable(T);
            [G2,TID2] = findgroups(DF);
            t.verifyEqual({G,TID},{G2,TID2.t})
        end
        
        function splitapplyTest(t)
            load patients %#ok<LOAD>
            DT = table(Height,Weight);
            GT = table(Gender,compose('%d',Smoker));
            meanBMIFcn = @(h,w)mean((w ./ (h.^2)) * 703);
            G = findgroups(GT);
            meanBMI = splitapply(meanBMIFcn,DT,G);
            
            DFDT = frames.DataFrame.fromTable(DT);
            DFGT = frames.DataFrame.fromTable(GT);
            G2 = findgroups(DFGT);
            meanBMI2 = DFDT.splitapply(meanBMIFcn,G2);
            t.verifyEqual(meanBMI2,meanBMI)
        end
        
        
        function groupsummary(t)
            
            Gender = [1;0;0;1;1];
            Age = [38;43;38;40;49];
            Height = [71;69;64;67;64];
            Weight = [176;163;131;133;119];
            T = table(Gender,Age,Height,Weight);
            G = groupsummary(T,"Gender");
            G.Properties.RowNames = compose('%d',1:height(G));
            
            
            DF = frames.DataFrame.fromTable(T);
            G2 = groupsummary(DF,"Gender");
            t.verifyEqual(G,G2.t)
            
            G = groupsummary(T,"Gender","mean");
            G.Properties.RowNames = compose('%d',1:height(G));
            G2 = groupsummary(DF,"Gender","mean");
            t.verifyEqual(G,G2.t)
            
            G = groupsummary(T,"Gender","median","Height");
            G.Properties.RowNames = compose('%d',1:height(G));
            G2 = groupsummary(DF,"Gender","median","Height");
            t.verifyEqual(G,G2.t)
            
            
            Smoker = [1;0;1;0;1];
            T = table(Gender,Smoker,Weight);
            DF = frames.DataFrame.fromTable(T);
            
            G = groupsummary(T,{'Gender','Smoker'},'mean','Weight');
            G.Properties.RowNames = compose('%d',1:height(G));
            G2 = groupsummary(DF,{'Gender','Smoker'},'mean','Weight');
            t.verifyEqual(G,G2.t)
            
            G = groupsummary(T,{'Gender','Smoker'},'mean','Weight','IncludeEmptyGroups',true);
            G.Properties.RowNames = compose('%d',1:height(G));
            G2 = groupsummary(DF,{'Gender','Smoker'},'mean','Weight','IncludeEmptyGroups',true);
            t.verifyEqual(G,G2.t)
            
            
            TimeStamps = datetime([2017 3 4; 2017 3 2; 2017 3 15; 2017 3 10;...
                2017 3 14; 2017 3 31; 2017 3 25;...
                2017 3 29; 2017 3 21; 2017 3 18]);
            Profit = [2032 3071 1185 2587 1998 2899 3112 909 2619 3085]';
            TotalItemsSold = [14 13 8 5 10 16 8 6 7 11]';
            TT = timetable(TimeStamps,Profit,TotalItemsSold);
            
            TF = frames.TimeFrame.fromTable(TT,UniqueSorted=false);
            G = groupsummary(TT,'TotalItemsSold',[0 4 8 12 16],'mean','Profit');
            G2 = groupsummary(TF,'TotalItemsSold',[0 4 8 12 16],'mean','Profit');
            t.verifyEqual(G,G2)
            
            
            load patients %#ok<LOAD>
            GenderN = zeros(length(Gender),1);
            GenderN(strcmp(Gender,'Female')) = 1;
            Gender = GenderN;
            T = table(Gender,Systolic,Diastolic,Height,Weight);
            DF = frames.DataFrame.fromTable(T);
            G = groupsummary(T,"Gender",@(x,y)xcov(x,y,0,'coeff'),{["Height","Systolic"],["Weight","Diastolic"]});
            G.Properties.RowNames = compose('%d',1:height(G));
            G2 = groupsummary(DF,"Gender",@(x,y)xcov(x,y,0,'coeff'),{["Height","Systolic"],["Weight","Diastolic"]});
            t.verifyEqual(G,G2.t)
            
        end
    end
end