%% load file

load('Han_20171201_COactpas_CDS_001.mat')
    
%% plot emg in time domain
    
    %define x axis
    timeArray = [-50:0.5:175]; %ms
    %define muscles
    muscleArrayEMG = [2:23]; %from EMG list
    muscleNames = string({'biMed','FCR','FCU','FDS','deltAnt','deltMid',...
        'deltPos','trap','lat','terMaj','infSpin','triMid',...
        'triLat','triMed','brad','ECRb','ECU','EDC',...
        'pecSup','pecInf','brach','biLat'});
    emgNum = [13:18];
    %directions to look at
    dirs = [0,45,90,135,180,225,270,315];
    directions = string(dirs);
    if emgNum(1)==1
        trials = zeros(numel(muscleArrayEMG),numel(directions));
    end
        
    %plot 'em
    figEMGtime = figure('Name','EMG motor noise check, time domain (ms)');

    k=0;
    %look at each muscle
    for i=emgNum
        %look at trials representing each direction
        for j=1:numel(directions)
            k=k+1;
            %pick random trial number based on direction
            dirArray = find(([cds.trials.bumpDir]==dirs(j))==1);
            trial = dirArray(randperm(length(dirArray),1));
            trials(i,j) = trial;
            %set time arrays
            trialBumpTime = table2array(cds.trials(:,17));
            emgtArray = table2array(cds.emg(:,1));
            zero = trialBumpTime(trial,1);
            startT = round((zero - 0.05),3);
            tStart = find(emgtArray(:,1)==startT);
            endT = round((zero + 0.125 + 0.05),3);
            tEnd = find(emgtArray(:,1)==endT);
            if (tEnd-tStart+1)~=length(timeArray)
                diff = (tEnd-tStart+1)-length(timeArray);
                if rem(diff,2)==0
                    tStart = tStart+(diff/2);
                    tEnd = tEnd-(diff/2);
                else
                    tStart = tStart+(diff/2)-0.5;
                    tEnd = tEnd-(diff/2)+0.5;
                end
            end
            %emg plots
            set(0,'CurrentFigure',figEMGtime)
            subplot(numel(emgNum),numel(directions),k);
            title(strcat(muscleNames(i),string(dirs(j))));
            hold on
            emgArray = transpose(table2array(cds.emg(:,muscleArrayEMG(i))));
            emgPlot = plot(timeArray, emgArray(1,tStart:tEnd),'k','LineWidth',1)
            xline(0,'b');
            xline(125,'bs');
            xlim([-50 175]);
            sgtitle('EMG motor noise check');
        end
    end
    
    
    %% plot emg in frequency domain separated by direction (for bumps)
    
    %define muscles
    muscleArrayEMG = [1:22]; %from emgFFT (removed 1st time column)
    muscleNames = string({'biMed','FCR','FCU','FDS','deltAnt','deltMid',...
        'deltPos','trap','lat','terMaj','infSpin','triMid',...
        'triLat','triMed','brad','ECRb','ECU','EDC',...
        'pecSup','pecInf','brach','biLat'});
    emgNum = [13:18];
    
    %directions to look at
    dirs = [0,45,90,135,180,225,270,315];
    directions = string(dirs);
    
    %combine all trials per direction? if no, specify howMany to combine
    allTrials = true;
    %howMany = 10;
    windowSize = 0.05; %ms -bumpTime,+(bumpTime+bumpHold)

    %plot 'em
    figEMGfreq2 = figure('Name','EMG motor noise check, frequency domain');

    n=0;
    
    for j=1:numel(dirs)
        n=n+1;
        %find bumpTimes based on bumpDirections
        dirArray = find(([cds.trials.bumpDir]==dirs(j))==1);
        %combine all trials or howMany number of trials
        if allTrials == true
            trialList = dirArray;
        else
            trialList = dirArray(sort(randperm(length(dirArray),howMany)));
        end 
        %create newEMGtable
        newEMGtable = [];
        trialBumpTime = table2array(cds.trials(:,17));
        trialBumpHold = table2array(cds.trials(:,22));
        emgtArray = table2array(cds.emg(:,1));
        for t=1:numel(trialList)
            zero = trialBumpTime(trialList(t),1);
            startT = round((zero - windowSize),3);
            tStart = find(emgtArray(:,1)==startT);
            endT = round((zero + trialBumpHold(1,1)+windowSize),3);
            tEnd = find(emgtArray(:,1)==endT);
            newEMGtable = vertcat(newEMGtable,table2array(cds.emg(tStart:tEnd,:)));
        end
        
        %fast fourier transform of emg signal
        emgFFT = fft(newEMGtable);
        emgFFT(:,1) = [];
        
        k=n;
        %look at each muscle
        for i=emgNum
            %define x axis
            fs = 2000; %sampling frequency (hz)
            tstep = 1/fs; %sampling period/time step (s)
            timeArray = 0:tstep:(length(newEMGtable)-1)*tstep; %seconds
            xaxis = fs*(0:((length(timeArray)-1)/2))/length(timeArray);
            %emg plots
            set(0,'CurrentFigure',figEMGfreq2)
            subplot(numel(emgNum),numel(dirs),k);
            title(strcat(muscleNames(i),string(dirs(j))));
            hold on
            emgArrayFFT = transpose(emgFFT(:,muscleArrayEMG(i)));
            emgPlot = plot(xaxis, emgArrayFFT(1,1:(numel(emgArrayFFT)+1)/2),'k','LineWidth',1)
            set(gca,'XTick',0:100:xaxis(numel(xaxis)));
            xtickangle(90);
            sgtitle('EMG motor noise check');
            
            k=k+numel(dirs);
        end
    end
    
    
    %% plot emg in frequency domain separated by direction (for non-bumps)
    
    %define muscles
    muscleArrayEMG = [1:22]; %from emgFFT (removed 1st time column)
    muscleNames = string({'biMed','FCR','FCU','FDS','deltAnt','deltMid',...
        'deltPos','trap','lat','terMaj','infSpin','triMid',...
        'triLat','triMed','brad','ECRb','ECU','EDC',...
        'pecSup','pecInf','brach','biLat'});
    emgNum = [7:12];
    
    %directions to look at
    dirs = [0,45,90,135,180,225,270,315];
    directions = string(dirs);
    
    %combine all trials per direction? if false, specify howMany to combine
    allTrials = true;
    %howMany = 10;
    windowSize = 0.05; %ms -bumpTime,+(bumpTime+bumpHold)

    %plot 'em
    figEMGfreq2 = figure('Name','non-bump reaches, frequency domain');

    n=0;
    
    %find non-bump trials
    nonBumps = isnan([cds.trials.bumpDir])==1;
    cdsNoBumps = cds.trials(nonBumps,:);
    goCueTimeNotNaN = isnan(table2array(cdsNoBumps(:,9)))==0;
    cdsNoBumps = cdsNoBumps(goCueTimeNotNaN,:);
    
    for j=1:numel(dirs)
        n=n+1;
        %find reach times based on tgtDirections
        cdsDirs = table2array(cdsNoBumps(:,15));
        dirArray = find((cdsDirs==dirs(j))==1);
        %combine all trials or howMany number of trials
        if allTrials == true
            trialList = dirArray;
        else
            trialList = dirArray(randperm(length(dirArray),howMany));
        end 
        %create newEMGtable
        newEMGtable = [];
        goCueTime = table2array(cdsNoBumps(:,9));
        emgtArray = table2array(cds.emg(:,1));
        for t=1:numel(trialList)
            zero = goCueTime(trialList(t),1);
            startT = round((zero - windowSize),3);
            tStart = find(emgtArray(:,1)==startT);
            endT = round((zero + windowSize),3);
            tEnd = find(emgtArray(:,1)==endT);
            newEMGtable = vertcat(newEMGtable,table2array(cds.emg(tStart:tEnd,:)));
        end
        
        %fast fourier transform of emg signal
        emgFFT = fft(newEMGtable);
        emgFFT(:,1) = [];
        
        k=n;
        %look at each muscle
        for i=emgNum
            %define x axis
            fs = 2000; %sampling frequency (hz)
            tstep = 1/fs; %sampling period/time step (s)
            timeArray = 0:tstep:(length(newEMGtable)-1)*tstep; %seconds
            xaxis = fs*(0:((length(timeArray)-1)/2))/length(timeArray);
            %emg plots
            set(0,'CurrentFigure',figEMGfreq2)
            subplot(numel(emgNum),numel(dirs),k);
            title(strcat(muscleNames(i),string(dirs(j))));
            hold on
            emgArrayFFT = transpose(emgFFT(:,muscleArrayEMG(i)));
            emgPlot = plot(xaxis, emgArrayFFT(1,1:(numel(emgArrayFFT)+1)/2),'k','LineWidth',1)
            set(gca,'XTick',0:100:xaxis(numel(xaxis)));
            xtickangle(90);
            sgtitle('EMG motor noise check');
            
            k=k+numel(dirs);
        end
    end

    %% plot emg in frequency domain
    
    %define x axis
    fs = 2000; %sampling frequency (hz)
    tstep = 1/fs; %sampling period/time step (s)
    timeArray = 0.004:tstep:2500; %seconds
    lastIdx = find(table2array(cds.emg(:,1))==2500);
    xaxis = fs*(0:(length(timeArray)/2-1))/length(timeArray);
    
    %fast fourier transform of emg signal
    emgFFT = fft(table2array(cds.emg));
    emgFFT(:,1) = [];
    
    %define muscles
    muscleArrayEMG = [1:22]; %from emgFFT (removed 1st time column)
    muscleNames = string({'biMed','FCR','FCU','FDS','deltAnt','deltMid',...
        'deltPos','trap','lat','terMaj','infSpin','triMid',...
        'triLat','triMed','brad','ECRb','ECU','EDC',...
        'pecSup','pecInf','brach','biLat'});
    emgNum = [19:22];
    %directions to look at
    dirs = [0,45,90,135,180,225,270,315];
    directions = string(dirs);
    %0,45,90,135,180,225,270,315

    %plot 'em
    figEMGfreq = figure('Name','EMG motor noise check, frequency domain');

    k=0;
    %look at each muscle
    for i=emgNum
        k=k+1;
        %emg plots
        set(0,'CurrentFigure',figEMGfreq)
        subplot(numel(emgNum),1,k);
        title(muscleNames(i));
        hold on
        emgArrayFFT = transpose(emgFFT(:,muscleArrayEMG(i)));
        emgPlot = plot(xaxis, emgArrayFFT(1,1:lastIdx/2),'k','LineWidth',1)
        sgtitle('EMG motor noise check');
    end 
