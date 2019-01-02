path('~/matlab/axion/',path);
spk_files = dir('*.spk' );
for f = 1:length(spk_files)
    SpkRec = spk_files(f).name;
    SpkRecString = split(spk_files(f).name,[string('_'),string('Rec-')]);
    SpkRecData = AxisFile(SpkRec).DataSets.LoadData;
    for r = 1:8
        for c = 1:12
           for x = 1:3
             for y = 1:3
              try
		 arrayVolt = []; %clear arrayVolt to free mem in suscessive loops
	 	 arrayTime = []; %clear arrayTime
		 cellSD = []; %clear cellSD
		 vectorSD = [];%clear vectorSD
                 arrayVolt = SpkRecData{r,c,x,y}.GetVoltageVector;
		 arrayTime = SpkRecData{r,c,x,y}.GetTimeVector;
                 cellSD = {SpkRecData{r,c,x,y}.StandardDeviation};
                 vectorSD = cell2mat(cellSD);
                 catch ME
                    if (strcmp(ME.identifier,'MATLAB:structRefFromNonStruct'))
                            continue
                    end
              end
              plate = SpkRecString(3);
              rec = SpkRecString(9);
              row = num2str(r);
              column = num2str(c);
              array_x = num2str(x);
              array_y = num2str(y);
              filenameVolt = strcat(plate,'_',rec,'_',row,'_',column,...
                  '_',array_x,'_',array_y,'_','volt','.csv');
	      csvwrite(char(filenameVolt),arrayVolt);
	      filenameTime = strcat(plate,'_',rec,'_',row,'_',column,...
		  '_',array_x,'_',array_y,'_','time','.csv');
	      csvwrite(char(filenameTime),arrayTime(1,:));
              filenameSD = strcat(plate,'_',rec,'_',row,'_',column,...
                  '_',array_x,'_',array_y','_','SD','.csv');
              csvwrite(char(filenameSD),vectorSD);
             end
           end
        end
    end
end   
exit    
