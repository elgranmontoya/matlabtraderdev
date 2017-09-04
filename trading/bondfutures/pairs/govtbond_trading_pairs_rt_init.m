%% ��ʼ�� WIND matlab
fprintf('init wind connection...\n');
if ~exist('w','var') || ~isa(w,'windmatlab')
    w = windmatlab;
end

%% ��ʼ�� pairs
fprintf('init pairs...\n');
leg1 = 'TF1712.CFE';
leg2 = 'T1712.CFE';
pairs = [leg1,',',leg2];

%% ��ʼ��ǰһ�������յ���ʷ����
lastBusDate = datestr(getlastbusinessdate(now),'yyyy-mm-dd');
fprintf('init market data of %s on %s...\n',pairs,lastBusDate);
[hd_leg1,~,~,t_leg1] = w.wsi(leg1,'close',[lastBusDate,' 09:15:00'],[lastBusDate,' 15:15:00']);
[hd_leg2,~,~,t_leg2] = w.wsi(leg2,'close',[lastBusDate,' 09:15:00'],[lastBusDate,' 15:15:00']);
% �˴���Ҫ����ʷ������һ�´���
hd_leg1 = [t_leg1,hd_leg1];
hd_leg2 = [t_leg2,hd_leg2];
[t,idx1,idx2] = intersect(hd_leg1(:,1),hd_leg2(:,1));
hd = [t,hd_leg1(idx1,2),hd_leg2(idx2,2)];

% %% ��ʼ��ǰһ�������յ���ʷ���ݣ�����
% % WIND�����ݿ��ܲ��ã��������û�����նˣ�������WIND��
% fut1 = windcode2contract(leg1(1:length(leg1)-4));
% fut2 = windcode2contract(leg2(1:length(leg2)-4));
% date_from = '08-Aug-2017';
% date_to = '10-Aug-2017';
% freq = '1m';
% 
% data1 = fut1.getTimeSeries('connection','bloomberg','fromdate',date_from,...
%     'todate',date_to,'fields',{'close','volume'},'frequency',freq);
% data2 = fut2.getTimeSeries('connection','bloomberg','fromdate',date_from,...
%     'todate',date_to,'fields',{'close','volume'},'frequency',freq);
% [t,idx1,idx2] = intersect(data1(:,1),data2(:,1));
% hd = [t,data1(idx1,2),data2(idx2,2)];


%% ��ʼ�� log �ļ�
fprintf('init log files...\n');
quoteFN = fopen('quotelog.txt','w');
tradeFN = fopen('tradelog.txt','w');

%% ��ʼ������model
fprintf('init trading model...\n');
lookbackPeriod = 270;
rebalancePeriod = 60;
upperBound = 1.65;
lowerBound = -1.65;

model = struct('LookbackPeriod',lookbackPeriod,...
    'RebalancePeriod',rebalancePeriod,...
    'UpperBound',upperBound,...
    'LowerBound',lowerBound,...
    'HD0',hd,...
    'QuoteFN',quoteFN,...
    'TradeFN',tradeFN);

warning('off','econ:egcitest:LeftTailStatTooSmall')
warning('off','econ:egcitest:LeftTailStatTooBig')


%% ��ʼ�� timer
% ��timerÿһ�����Զ�����һ�Σ�����н����źŻ��Զ�����
% ��timer��������д�����1000�Σ����̺�����stop����ֹͣ
fprintf('init timer...\n');
timer_govtbond_rt_pairs = timer('startDelay',0,'period',60,'tasksToExecute',1000,'executionMode','fixedRate');

timer_govtbond_rt_pairs.StartFcn = @(~,thisEvent)disp([datestr(thisEvent.Data.time),' timer starts...']);

timer_govtbond_rt_pairs.StopFcn = @(~,thisEvent)disp([datestr(thisEvent.Data.time),' timer stops...']);

timer_govtbond_rt_pairs.TimerFcn = {@govtbond_trading_pairs_callback,w,pairs,model};

set(timer_govtbond_rt_pairs,'UserData',{});


%% ���� timer
% 
% start(timer_govtbond_rt_pairs);
% �����趨ÿ������9��10�ֿ�ʼ����timer
% ���timer���е�ʱ���Ѿ�����9��10�֣�����ȡ��һ��׼���ӿ�ʼ����timer
if ~isholiday(today)
    hh = hour(now);
    if hh < 9
        H = 9;
        M = 10;
    elseif hh == 9
        mm = minute(now);
        if mm < 10
            H = 9;
            M = 10;
        elseif mm <  59 && mm >= 10
            H = 9;
            M = mm + 1;
        elseif mm == 59
            H = 10;
            M = 0;
        end
    elseif hh > 9 && hh <= 15
        mm = minute(now);
        if mm < 59;
            H = hh;
            M = mm+1;
        elseif mm == 60
            H = hh+1;
            M = 0;
        end
    end
    startat(timer_govtbond_rt_pairs,year(today),month(today),day(today),H,M,0);
else
    fprintf('take a break as it is a holiday today...\n');
end
% 

%% ֹͣ timer
stop(timer_govtbond_rt_pairs);
set(timer_govtbond_rt_pairs,'UserData',{});

%% �ر�log�ļ�
fprintf('close log files...\n');
fclose(quoteFN);
fclose(tradeFN);