function [output] = pnlriskbreakdown2(sec,quotes,cost,volume)
%function to break down the pnl attribution of the input option 
%given the market quote
%i.e.realtime pnl
if ischar(sec)
    flag = isoptchar(sec);
    if ~flag
        try
            sec = cFutures(sec);
            sec.loadinfo([sec.code_ctp,'_info.txt']);
        catch e
            fprintf(['error:',e.message,'\n']);
            return
        end
    else
        try
            sec = cOption(sec);
            sec.loadinfo([sec.code_ctp,'_info.txt']);
        catch e
            fprintf(['error:',e.message,'\n']);
            return
        end
    end
end

qidx = 0;
for i = 1:size(quotes,1)
    if strcmpi(sec.code_ctp,quotes{i}.code_ctp)
        qidx = i;
        break
    end
end
if qidx == 0, error('pnlriskbreakdown2:invalid quote(s) input'); end

if nargin < 3, error('pnlriskbreakdown2:missing cost input'); end

if nargin < 4, volume = 1; end

if isa(sec,'cFutures')
%     predate = businessdate(cobdate,-1);
    mult = sec.contract_size;
    if ~isempty(strfind(sec.code_bbg,'TFC')) || ~isempty(strfind(sec.code_bbg,'TFT'))
        mult = mult/100;
    end
    pv1_sec = cost;
    pv2_sec = quotes{qidx}.last_trade;
    pnl = pv2_sec-pv1_sec;
    output = struct('pnltotal',pnl*volume*mult,...
    'pnltheta',0,...
    'pnldelta',pnl*volume*mult,...
    'pnlgamma',0,...
    'pnlvega',0,...
    'pnlunexplained',0,...
    'date',quotes{qidx}.update_date2,...
    'time',quotes{qidx}.update_time2,...
    'iv1',0,...
    'iv2',0,...
    'spot1',pv1_sec,...
    'spit2',pv2_sec,...
    'premium1',pv1_sec,...
    'premium2',pv2_sec,...
    'volume',volume,...
    'deltacarry',pv2_sec*volume*mult,...
    'gammacarry',0,...
    'thetacarry',0,...
    'vegacarry',0,...
    'code',sec.code_ctp);
    return
end

%%
underlier = sec.code_ctp_underlier;
mult = sec.contract_size;
% data = cDataFileIO.loadDataFromTxtFile([underlier,'_daily.txt']);
cobdate = quotes{qidx}.update_date1;
% predate = businessdate(cobdate,-1);
nextdate = businessdate(cobdate,1);
price1_underlier = cost.price_underlier;
price2_underlier = quotes{qidx}.last_trade_underlier;
if isempty(price1_underlier) || isempty(price2_underlier)
    error(['underlier ',underlier,' historical price not saved!'])
end

% data = cDataFileIO.loadDataFromTxtFile([sec.code_ctp,'_daily.txt']);
pv1_sec = cost.price;
pv2_sec = quotes{qidx}.last_trade;
if isempty(pv1_sec) || isempty(pv2_sec)
    error(['option ',sec.code_ctp,' historical price not saved!'])
end

%%
k = sec.opt_strike;
optclass = 'call';
if strcmpi(sec.opt_type,'P'), optclass = 'put'; end
% tau1 = (sec.opt_expiry_date1 - datenum(predate))/365;
tau2 = (sec.opt_expiry_date1 - datenum(cobdate))/365;
tau3 = (sec.opt_expiry_date1 - datenum(nextdate))/365;
r = 0.035;
iv1 = cost.iv;
if sec.opt_american
    iv2 = bjsimpv(price2_underlier,k,r,datenum(cobdate),sec.opt_expiry_date2,pv2_sec,[],r,[],optclass);
else
    iv2 = blkimpv(price2_underlier,k,r,tau2,pv2_sec,[],[],{optclass});
end

%pvcarry: from previous business date
%pvcarry_:to next business date
if sec.opt_american
    if strcmpi(sec.opt_type,'C')
%         pvcarry = bjsprice(price1_underlier,k,r,datenum(cobdate),sec.opt_expiry_date1,iv1,r);
        pvcarry_ = bjsprice(price2_underlier,k,r,datenum(nextdate),sec.opt_expiry_date1,iv2,r);
        
    else
%         [~,pvcarry] = bjsprice(price1_underlier,k,r,datenum(cobdate),sec.opt_expiry_date1,iv1,r);
        [~,pvcarry_] = bjsprice(price2_underlier,k,r,datenum(nextdate),sec.opt_expiry_date1,iv2,r);
    end
else
    if strcmpi(sec.opt_type,'C')
%         pvcarry = blkprice(price1_underlier,k,r,tau2,iv1);
        pvcarry_ = blkprice(price2_underlier,k,r,tau3,iv2);
    else
%         [~,pvcarry] = blkprice(price1_underlier,k,r,tau2,iv1);
        [~,pvcarry_] = blkprice(price2_underlier,k,r,tau3,iv2);
    end
end
pnl_theta = cost.thetacarry;
thetacarry = pvcarry_ - pv2_sec;

%delta/gamma carry
bump = 0.005;
% priceup = price1_underlier*(1+bump);
% pricedn = price1_underlier*(1-bump);
priceup_ = price2_underlier*(1+bump);
pricedn_ = price2_underlier*(1-bump);
if sec.opt_american
    if strcmpi(sec.opt_type,'C')
%         pvup = bjsprice(priceup,k,r,datenum(cobdate),sec.opt_expiry_date1,iv1,r);
%         pvdn = bjsprice(pricedn,k,r,datenum(cobdate),sec.opt_expiry_date1,iv1,r);
        pvup_ = bjsprice(priceup_,k,r,datenum(nextdate),sec.opt_expiry_date1,iv2,r);
        pvdn_ = bjsprice(pricedn_,k,r,datenum(nextdate),sec.opt_expiry_date1,iv2,r);
    else
%         [~,pvup] = bjsprice(priceup,k,r,datenum(cobdate),sec.opt_expiry_date1,iv1,r);
%         [~,pvdn] = bjsprice(pricedn,k,r,datenum(cobdate),sec.opt_expiry_date1,iv1,r);
        [~,pvup_] = bjsprice(priceup_,k,r,datenum(nextdate),sec.opt_expiry_date1,iv2,r);
        [~,pvdn_] = bjsprice(pricedn_,k,r,datenum(nextdate),sec.opt_expiry_date1,iv2,r);
    end
else
    if strcmpi(sec.opt_type,'C')
%         pvup = blkprice(priceup,k,r,tau2,iv1);
%         pvdn = blkprice(pricedn,k,r,tau2,iv1);
        pvup_ = blkprice(priceup_,k,r,tau3,iv2);
        pvdn_ = blkprice(pricedn_,k,r,tau3,iv2);
    else
%         [~,pvup] = blkprice(priceup,k,r,tau2,iv1);
%         [~,pvdn] = blkprice(pricedn,k,r,tau2,iv1);
        [~,pvup_] = blkprice(priceup_,k,r,tau3,iv2);
        [~,pvdn_] = blkprice(pricedn_,k,r,tau3,iv2);
    end
end
% delta = (pvup-pvdn)/(priceup-pricedn);
% gamma = (pvup+pvdn-2*pvcarry)/(bump*price1_underlier)^2*price1_underlier/100;

delta = cost.deltacarry;
gamma = cost.gammacarry;

pnl_delta = delta*(price2_underlier-price1_underlier);
pnl_gamma = 0.5*gamma*(price2_underlier-price1_underlier)^2/price1_underlier/price1_underlier*100;
%
deltacarry = (pvup_-pvdn_)/(priceup_-pricedn_);
gammacarry = (pvup_+pvdn_-2*pvcarry_)/(bump*price2_underlier)^2*price2_underlier/100;

%vega
if sec.opt_american
    if strcmpi(sec.opt_type,'C')
%         pvvolup = bjsprice(price1_underlier,k,r,datenum(cobdate),sec.opt_expiry_date1,iv1+bump,r);
%         pvvoldn = bjsprice(price1_underlier,k,r,datenum(cobdate),sec.opt_expiry_date1,iv1-bump,r);
        pvvolup_ = bjsprice(price2_underlier,k,r,datenum(nextdate),sec.opt_expiry_date1,iv2+bump,r);
        pvvoldn_ = bjsprice(price2_underlier,k,r,datenum(nextdate),sec.opt_expiry_date1,iv2-bump,r);
    else
%         [~,pvvolup] = bjsprice(price1_underlier,k,r,datenum(cobdate),sec.opt_expiry_date1,iv1+bump,r);
%         [~,pvvoldn] = bjsprice(price1_underlier,k,r,datenum(cobdate),sec.opt_expiry_date1,iv1-bump,r);
        [~,pvvolup_] = bjsprice(price2_underlier,k,r,datenum(nextdate),sec.opt_expiry_date1,iv2+bump,r);
        [~,pvvoldn_] = bjsprice(price2_underlier,k,r,datenum(nextdate),sec.opt_expiry_date1,iv2-bump,r);
    end
else
    if strcmpi(sec.opt_type,'C')
%         pvvolup = blkprice(price1_underlier,k,r,tau2,iv1+bump);
%         pvvoldn = blkprice(price1_underlier,k,r,tau2,iv1-bump);
        pvvolup_ = blkprice(price2_underlier,k,r,tau3,iv2+bump);
        pvvoldn_ = blkprice(price2_underlier,k,r,tau3,iv2-bump);
    else
%         [~,pvvolup] = blkprice(price1_underlier,k,r,tau2,iv1+bump);
%         [~,pvvoldn] = blkprice(price1_underlier,k,r,tau2,iv1-bump);
        [~,pvvolup_] = blkprice(price2_underlier,k,r,tau3,iv2+bump);
        [~,pvvoldn_] = blkprice(price2_underlier,k,r,tau3,iv2-bump);
    end
end
% vega = pvvolup - pvvoldn;

vega = cost.vegacarry;
pnl_vega = vega*(iv2-iv1)/(2*bump);
vegacarry = pvvolup_ - pvvoldn_;
%
pnl = pv2_sec-pv1_sec;
pnl_explained = pnl_theta+pnl_delta+pnl_gamma+pnl_vega;
pnl_unexplained = pnl-pnl_explained;

output = struct('pnltotal',pnl*volume*mult,...
    'pnltheta',pnl_theta*volume*mult,...
    'pnldelta',pnl_delta*volume*mult,...
    'pnlgamma',pnl_gamma*volume*mult,...
    'pnlvega',pnl_vega*volume*mult,...
    'pnlunexplained',pnl_unexplained*volume*mult,...
    'date',quotes{qidx}.update_date2,...
    'time',quotes{qidx}.update_time2,...
    'iv1',iv1,...
    'iv2',iv2,...
    'spot1',price1_underlier,...
    'spot2',price2_underlier,...
    'premium1',pv1_sec,...
    'premium2',pv2_sec,...
    'volume',volume,...
    'deltacarry',deltacarry*volume*mult*price2_underlier,...
    'gammacarry',gammacarry*volume*mult*price2_underlier,...
    'thetacarry',thetacarry*volume*mult,...
    'vegacarry',vegacarry*volume*mult,...
    code,sec.code_ctp);
    
end