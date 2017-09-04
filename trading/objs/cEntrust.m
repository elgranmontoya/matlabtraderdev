classdef cEntrust < handle
    %cEntrust ί���µ���
    
    properties
        % ������Ϣ 
        marketNo = '1';             %��@char���г���ţ�'1'�Ͻ�����'2'����� ���Ǳ���
        instrumentCode = '000000';  % ��@char����Լ����,
        instrumentName = 'Untitled';    % Ϊ�˷���
        instrumentNo;   % ��Լ���
        volume;         % ������ TODO: ��Ϊ��ֵ��( ����ί�е����� )
        price;          % �۸�
        direction;      % ��@double��setter���ƣ���������buy = 1; sell = -1;
        offsetFlag = 1; % ��@double��setter���ƣ���ƽ����, open = 1; close = -1;
                
        entrustNo;            % ί�б��
        entrustType;          % ί������, market, limit, stop, fok etc.
        entrustStatus = 0;    % ί��״̬, 0��ʾ�¶���
                               % 1��ʾ����˵��µ���TODO�������Ч����
                               % 2��ʾ���µ������entrsutNo��
                               % 3��4��...δ�˽ᣬÿ��һ�μ�1
                               % -1��ʾ�˽��ˡ�
        %ΪCTPʹ������������
        entrustId = 0;        %��̨�ڲ�ί�б��
        assetType = 'Futures'; %������ͣ�'ETF'/'Option'/'Futures'
        
        %����
        date@double = today;  % ���ڣ� matlab ��ʽ�� ��735773
        time@double = now;    % ʱ�䣬matlab��ʽ����735773.324
        
        % �ɽ�
        dealVolume@double = 0; % �ɽ���Ŀ
        dealAmount@double = 0; % �ɽ����
        dealPrice;             % �ɽ�����
        dealNum@double = 0;    % �ɽ�����


        % ������Ϣ
        cancelVolume@double = 0;   % ��������
        cancelTime;                % ����ʱ��
        cancelNo;                  % ������
        
        recvTime;   % ��̨ϵͳ����ʱ��
        updateTime; % ����޸�ʱ��
        
        
        % �����Ϣ
        tick;       % ʱ���Ӧ��tick��
        strategyNo; % ���Ա�ţ�����
        orderRef;   % �������
        combNo;     % ��ϱ��
        roundNo;    % �غϱ��
        
        % ������Ϣ
        fee@double = 0; % ������
        % ��֤��
        
        % ��Լ����
        multiplier = 1;
        
        % �ҵ����򣨹���ֵ���� ���ڸ�Ƶ����
        rankBE = -1;  % best estimation
        rankWE = -1;  % worst estimation
      
    end
    
    properties (SetAccess = 'private',Hidden = true)
        isCompleted;
    end
    
    properties
        % ����ί�С��ҳ����ɽ�ʱ���
        issue_time_;
        accept_time_;
        complete_time_;
        
        % ������ϵ�ID�� Ĭ�ϼ򵥵��˴�ֵΪ-1��
        combi_no_ = -1;
        
        
    end
    
    properties (GetAccess = public, SetAccess = private, Dependent)
        date2;                % ���ڣ�double��char������'20140623'
        time2;                % double��char�� ʱ�� 'HHMMSSFFF'
    end
    
    methods
        function date2 = get.date2(obj)
            date2 = datestr(obj.date,'yyyymmdd');
        end
        
        function time2 = get.time2(obj)
            time2 = datestr(obj.time,'yyyymmdd HH:MM:SS:FFF');
        end
        
    end
    
    methods
        function fillEntrust(obj,varargin)
            %fillEntrust(obj,Name,Value)
            p = inputParser;
            p.CaseSensitive = false;p.KeepUnmatched = true;
            p.addParameter('MarketNo','1',@ischar);
            p.addParameter('InstrumentCode','000000',@ischar);
            p.addParameter('Direction',[],@(x) validateattributes(x,{'numeric','char'},{},'','Direction'));
            p.addParameter('Price',[],@isnumeric);
            p.addParameter('Volume',[],@isnumeric);
            p.addParameter('OffsetFlag',[],@(x) validateattributes(x,{'numeric','char'},{},'','OffsetFlag'));
            p.addParameter('InstrumentName','Untitled',@ischar);
            p.parse(varargin{:});
            
            obj.marketNo = p.Results.MarketNo;
            obj.instrumentCode = p.Results.InstrumentCode;
            
            directionIn = p.Results.Direction;
            if ischar(directionIn)
                switch directionIn
                    case {'1','buy','b'}   %��
                        obj.direction = 1;
                    case {'2','sell','s'}   
                        obj.direction = -1;
                    otherwise
                        obj.direction = 0;
                end
            elseif isnumeric(directionIn)
                obj.direction = directionIn;
            end
            
            priceIn = p.Results.Price;
            if priceIn <= 0
                error('cEntrust:fillEntrust with negative price')
            end
            obj.price = priceIn;
            
            volumeIn = p.Results.Volume;
            if volumeIn <= 0
                error('cEntrust:fillEntrust with negative volue')
            end
            obj.volume = volumeIn;
            
            
            offsetflag = p.Results.OffsetFlag;
            if ischar(offsetflag)
                switch offsetflag
                    case {'1','open','o'}   %����
                        obj.offsetFlag = 1;
                    case {'2','close','c'}  %ƽ��
                        obj.offsetFlag = -1;
                    otherwise
                        obj.offsetFlag = 0;
                end
            elseif isnumeric(offsetflag)
                obj.offsetFlag = offsetflag;
            end
            
            obj.date = today;
            obj.time = now;
            
             
        end
        
    end
    
    
end