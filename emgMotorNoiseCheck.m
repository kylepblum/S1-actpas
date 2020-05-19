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
    emgNum = [19:22];
    
    %directions to look at
    %dirs = [0,45,90,135,180,225,270,315];
    dirs = [0,90,180,270];
    directions = string(dirs);
    
    %combine all trials per direction? if no, specify howMany to combine
    allTrials = true;
    %howMany = 10;
    windowSize = 0.05; %ms -bumpTime,+(bumpTime+bumpHold)
    
    %define x axis
    fs = 2000; %sampling frequency (hz)
    tstep = 1/fs; %sampling period/time step (s)
    timeArray = 0:tstep:(0.05*2+0.125); %seconds
    %xaxis = fs*(0:((length(timeArray)-1)/2))/length(timeArray);

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
        windowSizes = [];
        trialBumpTime = table2array(cds.trials(:,17));
        trialBumpHold = table2array(cds.trials(:,22));
        emgtArray = table2array(cds.emg(:,1));
        for t=1:numel(trialList)
            zero = trialBumpTime(trialList(t),1);
            startT = round((zero - windowSize),3);
            tStart = find(emgtArray(:,1)==startT);
            endT = round((zero + trialBumpHold(1,1)+windowSize),3);
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
            windowSizes = [windowSizes (tEnd-tStart+1)];
            newEMGtable = vertcat(newEMGtable,table2array(cds.emg(tStart:tEnd,:)));
        end
        newEMGtable(:,1) = [];
        
        %fast fourier transform of emg signal
        %emgfreq = fft(newEMGtable);
        
        %welch's power spectral density estimate of emg signal
        [emgPWelch,xaxis] = pwelch(newEMGtable,(tEnd-tStart+1),0,[],fs);
        emgfreq = emgPWelch;
        
        k=n;
        %look at each muscle
        for i=emgNum
            %emg plots
            set(0,'CurrentFigure',figEMGfreq2)
            subplot(numel(emgNum),numel(dirs),k);
            emgArrayFreq = transpose(emgfreq(:,muscleArrayEMG(i)));
            %emgPlot = semilogx(xaxis, emgArrayFreq(1,1:(numel(emgArrayFreq)+1)/2),'k','LineWidth',1)
            emgPlot = loglog(xaxis, emgArrayFreq(1,:),'k','LineWidth',1)
            set(gca,'XTick',[10,100,1000]);
            xtickangle(90);
            title(strcat(muscleNames(i),string(dirs(j))));
            hold on
            sgtitle('EMG motor noise check, pwelch on concat array');
            
            k=k+numel(dirs);
        end
    end
    
    
    %% plot emg in frequency domain separated by direction (for bumps)
    %averaged pwelch, to compare with pwelch on entire concatenated array
    
    %define muscles
    muscleArrayEMG = [1:22]; %from emgFFT (removed 1st time column)
    muscleNames = string({'biMed','FCR','FCU','FDS','deltAnt','deltMid',...
        'deltPos','trap','lat','terMaj','infSpin','triMid',...
        'triLat','triMed','brad','ECRb','ECU','EDC',...
        'pecSup','pecInf','brach','biLat'});
    emgNum = [1:4];
    
    %directions to look at
    dirs = [0,90,180,270];
    directions = string(dirs);
    
    %combine all trials per direction? if no, specify howMany to combine
    allTrials = true;
    %howMany = 10;
    windowSize = 0.05; %ms -bumpTime,+(bumpTime+bumpHold)
    
    %define x axis for fft
    fs = 2000; %sampling frequency (hz)
    tstep = 1/fs; %sampling period/time step (s)
    timeArray = 0:tstep:(0.05*2+0.125); %seconds
    %xaxis = fs*(0:((length(timeArray)-1)/2))/length(timeArray);

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
            newEMGtable = cat(3,newEMGtable,table2array(cds.emg(tStart:tEnd,:)));
        end
        newEMGtable(:,1,:) = [];
        
        %fast fourier transform of emg signal
        for d=1:size(newEMGtable,3)
            [emgPWelch,xaxis] = pwelch(newEMGtable(:,:,d),size(newEMGtable,1),0,[],fs);
            emgfreq(:,:,d) = emgPWelch;
        end
        emgfreq = mean(emgfreq,3);
        
        k=n;
        %look at each muscle
        for i=emgNum
            
            %emg plots
            set(0,'CurrentFigure',figEMGfreq2)
            subplot(numel(emgNum),numel(dirs),k);
            emgArrayFreq = transpose(emgfreq(:,muscleArrayEMG(i)));
            %emgPlot = semilogx(xaxis, emgArrayFreq(1,1:(numel(emgArrayFreq)+1)/2),'k','LineWidth',1)
            emgPlot = semilogx(xaxis, emgArrayFreq(1,:),'k','LineWidth',1)
            xlim([0 2])
            set(gca,'XTick',[0,10,100,1000]);
            xtickangle(90);
            title(strcat(muscleNames(i),string(dirs(j))));
            hold on
            sgtitle('EMG motor noise check, pwelch averaged');
            
            k=k+numel(dirs);
        end
    end
    
    %% plot emg in frequency domain w pwelch 2 ways (for bumps)
    
    %define muscles
    muscleArrayEMG = [1:22]; %from emgFFT (removed 1st time column)
    muscleNames = string({'biMed','FCR','FCU','FDS','deltAnt','deltMid',...
        'deltPos','trap','lat','terMaj','infSpin','triMid',...
        'triLat','triMed','brad','ECRb','ECU','EDC',...
        'pecSup','pecInf','brach','biLat'});
    emgNum = [19:22];
    
    %directions to look at
    %dirs = [0,45,90,135,180,225,270,315];
    dirs = [0,90,180,270];
    directions = string(dirs);
    
    %combine all trials per direction? if no, specify howMany to combine
    allTrials = true;
    %howMany = 10;
    windowSize = 0.05; %ms -bumpTime,+(bumpTime+bumpHold)
    
    %define x axis
    fs = 2000; %sampling frequency (hz)
    tstep = 1/fs; %sampling period/time step (s)
    timeArray = 0:tstep:(0.05*2+0.125); %seconds
    %xaxis = fs*(0:((length(timeArray)-1)/2))/length(timeArray);

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
        segEMGtable = [];
        windowSizes = [];
        trialBumpTime = table2array(cds.trials(:,17));
        trialBumpHold = table2array(cds.trials(:,22));
        emgtArray = table2array(cds.emg(:,1));
        for t=1:numel(trialList)
            zero = trialBumpTime(trialList(t),1);
            startT = round((zero - windowSize),3);
            tStart = find(emgtArray(:,1)==startT);
            endT = round((zero + trialBumpHold(1,1)+windowSize),3);
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
            windowSizes = [windowSizes (tEnd-tStart+1)];
            newEMGtable = vertcat(newEMGtable,table2array(cds.emg(tStart:tEnd,:)));
            segEMGtable = cat(3,segEMGtable,table2array(cds.emg(tStart:tEnd,:)));
        end
        newEMGtable(:,1) = [];
        segEMGtable(:,1,:) = [];
        
        %pwelch of each segment averaged
        for d=1:size(segEMGtable,3)
            [emgPWelch,xaxis] = pwelch(segEMGtable(:,:,d),size(segEMGtable,1),0,[],fs);
            pwelchSegTrials(:,:,d) = emgPWelch;
        end
        pwelchSeg = mean(pwelchSegTrials,3);
        
        %pwelch of concatenated array
        [emgPWelch,xaxis] = pwelch(newEMGtable,(tEnd-tStart+1),0,[],fs);
        pwelchConcat = emgPWelch;
        
        k=n;
        %look at each muscle
        for i=emgNum
            
            %emg plots
            set(0,'CurrentFigure',figEMGfreq2)
            subplot(numel(emgNum),numel(dirs),k);
            pwelchSegArray = transpose(pwelchSeg(:,muscleArrayEMG(i)));
            pwelchConcatArray = transpose(pwelchConcat(:,muscleArrayEMG(i)));
            emgPlot = loglog(xaxis, pwelchSegArray,'k','LineWidth',1)
            hold on
            loglog(xaxis, pwelchConcatArray,'r--')
            set(gca,'XTick',[0,10,100,1000]);
            xtickangle(90);
            title(strcat(muscleNames(i),string(dirs(j))));
            hold on
            sgtitle('EMG in frequency domain, pwelch 2 ways');
            if k==1
                legend('pwelch on each segment averaged','pwelch on concatenated array',...
                    'Position',[0 0.8 0.12 0.1])
            end
            
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
    emgNum = [19:22];
    
    %directions to look at
    dirs = [0,90,180,270];
    directions = string(dirs);
    
    %combine all trials per direction? if false, specify howMany to combine
    allTrials = true;
    %howMany = 10;
    windowSize = 0.05; %ms -goCueTime,+(goCueTimeTime+bumpHold)

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
            endT = round((zero + 0.125 + windowSize),3);
            tEnd = find(emgtArray(:,1)==endT);
            newEMGtable = vertcat(newEMGtable,table2array(cds.emg(tStart:tEnd,:)));
        end
        newEMGtable(:,1) = [];
        
        %fast fourier transform of emg signal
        %emgFFT = fft(newEMGtable);
        %emgfreq = emgFFT;
        
        %welch's power spectral density estimate of emg signal
        fs = 2000; %sampling frequency (hz)
        tstep = 1/fs; %sampling period/time step (s)
        [emgPWelch,xaxis] = pwelch(newEMGtable,(endT-startT)/0.0005+1,0,[],fs);
        emgfreq = emgPWelch;
        
        k=n;
        %look at each muscle
        for i=emgNum
            %define x axis
            %timeArray = 0:tstep:(length(emgfreq)-1)*tstep; %seconds
            %xaxis = fs*(0:((length(timeArray)-1)/2))/length(timeArray);
            %emg plots
            set(0,'CurrentFigure',figEMGfreq2)
            subplot(numel(emgNum),numel(dirs),k);
            emgArrayFreq = transpose(emgfreq(:,muscleArrayEMG(i)));
            %emgPlot = semilogx(xaxis, emgArrayFreq(1,1:(numel(emgArrayFreq)+1)/2),'k','LineWidth',1)
            emgPlot = loglog(xaxis, emgArrayFreq(1,:),'k','LineWidth',1)
            set(gca,'XTick',[0,10,100,1000]);
            xtickangle(90);
            title(strcat(muscleNames(i),string(dirs(j))));
            hold on
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
    
    
    
    %% for lee
    
    %[deltAntPWelch,xax] = pwelch(table2array(cds.emg(:,6)),2000);
    [deltAntPWelch,xax] = pwelch(table2array(cds.emg(:,6)), 10000, 0, [], 2000)
    deltAntPWelchFlip = deltAntPWelch';
    xaxFlip = xax';
    deltAntFig = figure('Name','DeltAnt PWelch');
    semilogy(xaxFlip, deltAntPWelchFlip)
    
    deltAntEMG = table2array(cds.emg(100:60100,6));
    xtime = table2array(cds.emg(100:60100,1));
    deltAntEMGFlip = deltAntEMG';
    xtimeFlip = xtime';
    deltAntFig = figure('Name','DeltAnt EMG');
    plot(xtimeFlip, deltAntEMGFlip)
    ylim([-100 150])
    
    
    %% spectrogram analysis (for bumps)
    
    trials = table2struct(cds.trials);
    trials = trials(find([trials.result]=='R'));
    
    %define muscles
    muscleArrayEMG = [1:22]; %from emgFFT (removed 1st time column)
    muscleNames = string({'biMed','FCR','FCU','FDS','deltAnt','deltMid',...
        'deltPos','trap','lat','terMaj','infSpin','triMid',...
        'triLat','triMed','brad','ECRb','ECU','EDC',...
        'pecSup','pecInf','brach','biLat'});
    emgNum = [20:22];
    
    %directions to look at
    %dirs = [0,45,90,135,180,225,270,315];
    dirs = [0,90,180,270];
    directions = string(dirs);
    
    %combine all trials per direction? if no, specify howMany to combine
    allTrials = true;
    %howMany = 10;
    windowSize = 0.025; %ms -bumpTime,+(bumpTime+bumpHold)
    
    %define x axis
    fs = 2000; %sampling frequency (hz)
    tstep = 1/fs; %sampling period/time step (s)
    timeArray = 0:tstep:(windowSize*2+trials(1).bumpHoldPeriod); %seconds
    %timeArray = 0:tstep:(windowSize+0.1); %seconds
    %xaxis = fs*(0:((length(timeArray)-1)/2))/length(timeArray);

    %plot 'em
    figEMGspectro = figure('Name','EMG motor noise check, spectrogram averaged across trials');

    n=0;
    
    for j=1:numel(dirs)
        n=n+1;
        %find bumpTimes based on bumpDirections
        dirArray = find(([trials.bumpDir]==dirs(j))==1);
        %combine all trials or howMany number of trials
        if allTrials == true
            trialList = dirArray;
        else
            trialList = dirArray(sort(randperm(length(dirArray),howMany)));
        end 
        %create newEMGtable
        newEMGtable = [];
        segEMGtable = [];
        windowSizes = [];
        emgtArray = table2array(cds.emg(:,1));
        for t=1:numel(trialList)
            zero = trials(trialList(t)).bumpTime;
            startT = round((zero - windowSize),3);
            tStart = find(emgtArray(:,1)==startT);
            endT = round((zero + trials(1).bumpHoldPeriod + windowSize),3);
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
            newEMGtable = vertcat(newEMGtable,table2array(cds.emg(tStart:tEnd,:)));
            segEMGtable = cat(3,segEMGtable,table2array(cds.emg(tStart:tEnd,:)));
        end
        newEMGtable(:,1) = [];
        segEMGtable(:,1,:) = [];
        segEMGtable = abs(segEMGtable);
        
        k=n;
        %look at each muscle
        for i=emgNum
            %spectrogram of each segment averaged
            spectSegTrials = [];
            for d=1:size(segEMGtable,3)
                [spectroSeg,fx,tx] = spectrogram(segEMGtable(:,muscleArrayEMG(i),d),20,[],[],fs,'yaxis');
                spectSegTrials(:,:,d) = spectroSeg;
            end
            meanSpectSeg = mean(spectSegTrials,3);
            %emg plots
            set(0,'CurrentFigure',figEMGspectro)
            subplot(numel(emgNum),numel(dirs),k);
            %spectrogram
            %Try to plot the spectrogram from the output 
%             surf(tx(1:(0.1/0.005)), fx, 20*log10(abs(meanSpectSeg(:,1:(0.1/0.005)))), 'EdgeColor', 'none');
            surf(tx, fx, 20*log10(abs(meanSpectSeg)), 'EdgeColor', 'none');
            axis xy; 
            axis tight; 
            view(0,90);
            xlabel('Time (secs)');
            colorbar;
            ylabel('Frequency(HZ)');
            caxis([-20 20]);
            title(strcat(muscleNames(i),string(dirs(j))));
            hold on
            xline(windowSize,'--r','LineWidth',1)
            xline(windowSize+0.03,'k')
            xline(windowSize+trials(1).bumpHoldPeriod,'--r','LineWidth',1)
            sgtitle('Rectified EMG motor noise check, spectrogram averaged across trials');
            
            k=k+numel(dirs);
        end
    end
    
    
        %% spectrogram analysis
    
    trials = table2struct(cds.trials);
    trials = trials(find([trials.result]=='R'));
    
    %define muscles
    muscleArrayEMG = [1:22]; %from emgFFT (removed 1st time column)
    muscleNames = string({'biMed','FCR','FCU','FDS','deltAnt','deltMid',...
        'deltPos','trap','lat','terMaj','infSpin','triMid',...
        'triLat','triMed','brad','ECRb','ECU','EDC',...
        'pecSup','pecInf','brach','biLat'});
    emgNum = [20:22];
    
    %directions to look at
    %dirs = [0,45,90,135,180,225,270,315];
    dirs = [0,90,180,270];
    directions = string(dirs);
    
    %combine all trials per direction? if no, specify howMany to combine
    allTrials = true;
    %howMany = 10;
    windowSize = 0.05; %ms -bumpTime,+(bumpTime+bumpHold)
    
    %define x axis
    fs = 2000; %sampling frequency (hz)
    tstep = 1/fs; %sampling period/time step (s)
    timeArray = 0:tstep:(windowSize*2+0.5); %seconds
    %xaxis = fs*(0:((length(timeArray)-1)/2))/length(timeArray);

    %plot 'em
    figEMGspectro = figure('Name','EMG motor noise check NON-bump reaches, spectrogram averaged across trials');

    n=0;
    
    for j=1:numel(dirs)
        n=n+1;
        %find reach time based on tgtDirections
        dirArray = find(([trials.tgtDir]==dirs(j))==1);
        %combine all trials or howMany number of trials
        if allTrials == true
            trialList = dirArray;
        else
            trialList = dirArray(sort(randperm(length(dirArray),howMany)));
        end 
        %create newEMGtable
        newEMGtable = [];
        segEMGtable = [];
        trialTime = [];
        emgtArray = table2array(cds.emg(:,1));
        for t=1:numel(trialList)
            zero = trials(trialList(t)).goCueTime;
            startT = round((zero - windowSize),3);
            tStart = find(emgtArray(:,1)==startT);
            endT = round((zero + 0.5 + windowSize),3);
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
            newEMGtable = vertcat(newEMGtable,table2array(cds.emg(tStart:tEnd,:)));
            segEMGtable = cat(3,segEMGtable,table2array(cds.emg(tStart:tEnd,:)));
            
            %goCueTime to endTime
            
        end
        newEMGtable(:,1) = [];
        segEMGtable(:,1,:) = [];
        
        k=n;
        %look at each muscle
        for i=emgNum
            %spectrogram of each segment averaged
            spectSegTrials = [];
            for d=1:size(segEMGtable,3)
                [spectroSeg,fx,tx] = spectrogram(segEMGtable(:,muscleArrayEMG(i),d),20,[],[],fs,'yaxis');
                spectSegTrials(:,:,d) = spectroSeg;
            end
            meanSpectSeg = mean(spectSegTrials,3);
            %emg plots
            set(0,'CurrentFigure',figEMGspectro)
            subplot(numel(emgNum),numel(dirs),k);
            %spectrogram
            %Try to plot the spectrogram from the output 
            surf(tx, fx, 20*log10(abs(meanSpectSeg)), 'EdgeColor', 'none');
            axis xy; 
            axis tight; 
            view(0,90);
            xlabel('Time (secs)');
            colorbar;
            ylabel('Frequency(HZ)');
            caxis([-20 15]);
            title(strcat(muscleNames(i),string(dirs(j))));
            hold on
            xline(0.05,'--')
            xline(0.5,'--')
            sgtitle('EMG motor noise check for NON-bump reaches, spectrogram averaged across trials');
            
            k=k+numel(dirs);
        end
    end
