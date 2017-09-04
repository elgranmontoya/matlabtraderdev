function [ output_args ] = govtbond_trading_pairs_callback( obj,event,w,pairs,model,mode,externaldata )

% �������룺
% w - WIND�����
% pairs - ���ڽ��׵�������Լ
% model - cointegration����ģ�Ͳ���

if nargin < 6
    mode = 'realtime';
end

if nargin == 6 && ~strcmpi(mode,'realtime')
    error('external data shall be supplied with replay mode')
end

if strcmpi(mode,'replay') && isempty(externaldata)
    error('external data shall be supplied with replay mode')
end

M = model.LookbackPeriod;
N = model.RebalancePeriod;

quoteFN = model.QuoteFN;
tradeFN = model.TradeFN;

if strcmpi(mode,'realtime')
    dt = datenum(event.Data.time);
    day = floor(dt);
    
    % �й���ծ�ڻ�����ʱ��Σ����� 09:15 �� 11:30; ���� 13:00 �� 15:15
    % ��Ϊtimer���е�ʱ�䲻һ���������ӣ�����������һ���ӵĻ���
    tAMStart = datenum([datestr(day),' 09:15:00']);
    tAMStop = datenum([datestr(day),' 11:31:00']);
    tPMStart = datenum([datestr(day),' 13:00:00']);
    tPMStop = datenum([datestr(day),' 15:16:00']);

    % ���ؿ�ֵ����г��ڷǽ���ʱ��
    if ~((dt >= tAMStart && dt <= tAMStop) ||...
            (dt >= tPMStart && dt <= tPMStop))
        fprintf([datestr(event.Data.time),' timer runs....']);
        fprintf('bond futures market closed...\n');
        return
    end
    fprintf([datestr(event.Data.time,'yyyy-mm-dd HH:MM'),' timer runs....\n']);
end



legs = regexp(pairs,',','split');

if isempty(obj.UserData)
    tsOld = model.HD0;
    count = size(tsOld,1);
    idx = min(max(M,N),size(tsOld,1));
    [h,~,~,~,reg1] = egcitest(tsOld(idx-M+1:idx,2:3));
    if h ~= 0
        modelParams = reg1;
    else
        modelParams = 0;
    end
    
    %������δ�������ǿ����ǽ��trading bookֱ�ӵض�ͷ����Ϣ
    obj.UserData = struct('Count',count,...
        'TimeSeries',tsOld,...
        'ModelParameters',modelParams,...
        'Positions',[0,0]);            
end

ud = obj.UserData;
count = ud.Count;
tsOld = ud.TimeSeries;
modelParams = ud.ModelParameters;
positions = ud.Positions;

if strcmpi(mode,'realtime')
    % [data,~,~,t,~,~] = w.wsq(pairs,'rt_latest,rt_bid1,rt_ask1');
    [data,~,~,t,~,~] = w.wsq(pairs,'rt_latest');
    % ʱ�����б���б�����ʱ�䡢���³ɽ���(leg1)�����³ɽ���(leg2)
    % todo:�˴�Ӧ���ж�һ��ԭʼ�����Ƿ��д�
    data = [t,data(1,1),data(2,1)];
    fprintf('\n%s\t%s:%4.3f;\t%s:%4.3f\n',...
        datestr(data(1,1),'yyyy-mm-dd HH:MM'),...
        legs{1},data(2),legs{2},data(3));
    %
    if ~isempty(quoteFN) && ~isnan(quoteFN)
        fprintf(quoteFN,'%s\t%4.3f\t%4.3f\n',datestr(data(1),'yyyy-mm-dd HH:MM'),...
            data(2),data(3));
    end
        
elseif strcmpi(mode,'replay')
    if count + 1 > size(externaldata,1)
        return
    end
    data = externaldata(count+1,:);
    fprintf('\nreplay on %s\t%s:%4.3f;\t%s:%4.3f\n',...
        datestr(data(1,1),'yyyy-mm-dd HH:MM'),...
        legs{1},data(2),legs{2},data(3));
end

count = count + 1;
if strcmpi(mode,'realtime')
    [nRows,nCols] = size(tsOld);
    tsNew = zeros(nRows+1,nCols);
    if nRows > 1
        tsNew(1:nRows,:) = tsOld;
    end
    tsNew(nRows+1,:) = data;
elseif strcmpi(mode,'replay')
    tsNew = externaldata(1:count,:);
end
    
%% model estimation part
%
doRebalance = mod(count-M,N) == 0;
nRebalance =  floor((count - M)/N);
if doRebalance
    % rebalance the model parameters
    idx = max(M,N)+N*nRebalance;
    [h,~,~,~,reg1] = egcitest(tsNew(idx-M+1:idx,2:3));
    if h ~= 0
        modelParams = reg1;
    else
        modelParams = 0;
    end    
end

% fprintf('%d\n',count);
    
reg1 = modelParams;
if isstruct(reg1)
    res = tsNew(end,2) ...
        - (reg1.coeff(1) + reg1.coeff(2) *tsNew(end,3));
    indicate = res/reg1.RMSE;
    
    % If the residuals are large and positive, then the first series
    % is likely to decline vs. the seond series. Short the first series
    % by a scaled number of shares and long the second series by 1
    % share. If the residuals are large and negative, do the opposite
    if indicate > model.UpperBound
        s = [-reg1.coeff(2),1];
        fprintf('\tsignal:%s overbought\n',legs{1});
        %
        if sum(positions) == 0  % previous position is empty
            printmsg = '\ttrade:short open %4.2f lots of %s at %4.3f; long open %d lots of %s at %4.3f\n'; 
            fprintf(printmsg,abs(s(1)),legs{1},tsNew(end,2),abs(s(2)),legs{2},tsNew(end,3));
            
            if ~isempty(tradeFN) && ~isnan(tradeFN)
                logmsg = '%s:short open %4.2f lots of %s at %4.3f; long open %d lots of %s at %4.3f\n';
                fprintf(tradeFN,logmsg,datestr(tsNew(end,1),'yyyy-mm-dd'),...
                    abs(s(1)),legs{1},tsNew(end,2),abs(s(2)),legs{2},tsNew(end,3));
            end
            
            
        elseif sign(positions(2)) == 1
            %the same signal: do nothing
            fprintf('\ttrade keep current positions\n');
        elseif sign(positions(2)) == -1
            %the opposite signal:unwind and open new trade
            printmsg = '\ttrade:short close %4.2f lots of %s at %4.3f; long close %d lots of %s at %4.3f\n';
            fprintf(printmsg,abs(positions(1)),legs{1},tsNew(end,2),abs(positions(2)),legs{2},tsNew(end,3));
            %
            if ~isempty(tradeFN) && ~isnan(tradeFN)
                logmsg = '%s:short close %4.2f lots of %s at %4.3f; long close %d lots of %s at %4.3f\n';
                fprintf(tradeFN,logmsg,datestr(tsNew(end,1),'yyyy-mm-dd'),...
                    abs(s(1)),legs{1},tsNew(end,2),abs(s(2)),legs{2},tsNew(end,3));
            end
            %            
            printmsg = '\ttrade:short open %4.2f lots of %s at %4.3f; long open %d lots of %s at %4.3f\n';
            fprintf(printmsg,abs(s(1)),legs{1},tsNew(end,2),abs(s(2)),legs{2},tsNew(end,3));
            %
            if ~isempty(tradeFN) && ~isnan(tradeFN)
                logmsg = '%s:short open %4.2f lots of %s at %4.3f; long open %d lots of %s at %4.3f\n';
                fprintf(tradeFN,logmsg,datestr(tsNew(end,1),'yyyy-mm-dd'),...
                    abs(s(1)),legs{1},tsNew(end,2),abs(s(2)),legs{2},tsNew(end,3));
            end
        end
        
    elseif indicate < model.LowerBound
        s = [reg1.coeff(2),-1];
        fprintf('\tsignal:%s oversold\n',legs{1});
        %
        if sum(positions) == 0 % previous position is empty
            printmsg = '\ttrade:long open %4.2f lots of %s at %4.3f; short open %d lots of %s at %4.3f\n';
            fprintf(printmsg,abs(s(1)),legs{1},tsNew(end,2),abs(s(2)),legs{2},tsNew(end,3));
            %
            if ~isempty(tradeFN) && ~isnan(tradeFN)
                logmsg = '%s:long open %4.2f lots of %s at %4.3f; short open %d lots of %s at %4.3f\n';
                fprintf(tradeFN,logmsg,datestr(tsNew(end,1),'yyyy-mm-dd'),...
                    abs(s(1)),legs{1},tsNew(end,2),abs(s(2)),legs{2},tsNew(end,3));
            end
            
        elseif sign(positions(2)) == -1
            %the same signal:do nothing
            fprintf('\ttrade:keep current positions\n');
        elseif sign(positions(2)) == 1
            %the opposite signal:unwind and open new trade
            printmsg = '\ttrade:long close %4.2f lots of %s at %4.3f; short close %d lots of %s at %4.3f\n';
            fprintf(printmsg,abs(positions(1)),legs{1},tsNew(end,2),abs(positions(2)),legs{2},tsNew(end,3));
            %
            if ~isempty(tradeFN) && ~isnan(tradeFN)
               logmsg = '%s:long close %4.2f lots of %s at %4.3f; short close %d lots of %s at %4.3f\n';
               fprintf(tradeFN,logmsg,datestr(tsNew(end,1),'yyyy-mm-dd'),...
                    abs(s(1)),legs{1},tsNew(end,2),abs(s(2)),legs{2},tsNew(end,3));
            end
            %
            printmsg = '\ttrade:long open %4.2f lots of %s at %4.3f; short open %d lots of %s at %4.3f\n'; 
            fprintf(printmsg,abs(s(1)),legs{1},tsNew(end,2),abs(s(2)),legs{2},tsNew(end,3));
            %
            if ~isempty(tradeFN) && ~isnan(tradeFN)
                logmsg = '%s:long open %4.2f lots of %s at %4.3f; short open %d lots of %s at %4.3f\n';
                fprintf(tradeFN,logmsg,datestr(tsNew(end,1),'yyyy-mm-dd'),...
                    abs(s(1)),legs{1},tsNew(end,2),abs(s(2)),legs{2},tsNew(end,3));
            end
        end
            
    else
        s = [0,0];
        fprintf('\tsignal:neutral\n');
        if sum(positions) == 0 % previous position is empty
            fprintf('\ttrade:keep neutral positions\n');
        elseif sign(positions(2)) == 1 %leg1 was overbought
            printmsg = '\ttrade:long close %4.2f lots of %s at %4.3f; short close %d lots of %s at %4.3f\n';
            fprintf(printmsg,abs(positions(1)),legs{1},tsNew(end,2),abs(positions(2)),legs{2},tsNew(end,3));
            %
            if ~isempty(tradeFN) && ~isnan(tradeFN)
                logmsg = '%s:long close %4.2f lots of %s at %4.3f; short close %d lots of %s at %4.3f\n';
                fprintf(tradeFN,logmsg,datestr(tsNew(end,1),'yyyy-mm-dd'),...
                    abs(s(1)),legs{1},tsNew(end,2),abs(s(2)),legs{2},tsNew(end,3));
            end
            %
        elseif sign(positions(2)) == -1 %leg1 was oversold
            printmsg = '\ttrade:short close %4.2f lots of %s at %4.3f; long close %d lots of %s at %4.3f\n';
            fprintf(printmsg,abs(positions(1)),legs{1},tsNew(end,2),abs(positions(2)),legs{2},tsNew(end,3));
            %
            if ~isempty(tradeFN) && ~isnan(tradeFN)
                logmsg = '%s:short close %4.2f lots of %s at %4.3f; long close %d lots of %s at %4.3f\n';
                fprintf(tradeFN,logmsg,datestr(tsNew(end,1),'yyyy-mm-dd'),...
                    abs(s(1)),legs{1},tsNew(end,2),abs(s(2)),legs{2},tsNew(end,3));
            end
        end
            
    end
else
    s = [0,0];
    fprintf('\tsignal:no cointegration found\n');
    if sum(positions) == 0 % previous position is empty
            fprintf('\ttrade:keep neutral positions\n');
        elseif sign(positions(2)) == 1 %leg1 was overbought
            printmsg = '\ttrade:long close %4.2f lots of %s at %4.3f; short close %d lots of %s at %4.3f\n';
            fprintf(printmsg,abs(positions(1)),legs{1},tsNew(end,2),abs(positions(2)),legs{2},tsNew(end,3));
            %
            if ~isempty(tradeFN) && ~isnan(tradeFN)
                logmsg = '%s:long close %4.2f lots of %s at %4.3f; short close %d lots of %s at %4.3f\n';
                fprintf(tradeFN,logmsg,datestr(tsNew(end,1),'yyyy-mm-dd'),...
                    abs(s(1)),legs{1},tsNew(end,2),abs(s(2)),legs{2},tsNew(end,3));
            end
            %
        elseif sign(positions(2)) == -1 %leg1 was oversold
            printmsg = '\ttrade:short close %4.2f lots of %s at %4.3f; long close %d lots of %s at %4.3f\n';
            fprintf(printmsg,abs(positions(1)),legs{1},tsNew(end,2),abs(positions(2)),legs{2},tsNew(end,3));
            %
            if ~isempty(tradeFN) && ~isnan(tradeFN)
                logmsg = '%s:short close %4.2f lots of %s at %4.3f; long close %d lots of %s at %4.3f\n';
                fprintf(tradeFN,logmsg,datestr(tsNew(end,1),'yyyy-mm-dd'),...
                    abs(s(1)),legs{1},tsNew(end,2),abs(s(2)),legs{2},tsNew(end,3));
            end
    end
end

obj.UserData = struct('Count',count,...
    'TimeSeries',tsNew,...
    'ModelParameters',modelParams,....
    'Positions',s);




end

