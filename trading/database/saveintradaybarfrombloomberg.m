function saveintradaybarfrombloomberg(bbg,code_ctp,override)

if ~isa(bbg,'cBloomberg')
    error('saveintradaybarfrombloomberg;invalid bloomberg instance input')
end

if ~ischar(code_ctp)
    error('saveintradaybarfrombloomberg;invalid CTP code input')
end

if nargin < 3
    override = false;
end

dir_ = getenv('DATAPATH');
dir_info_ = [dir_,'info_futures\'];
dir_data_ = [dir_,'intradaybar\',code_ctp,'\'];
try
    cd(dir_data_);
catch
    mkdir(dir_data_);
end


%first try to load information from local drive
f = cFutures(code_ctp);
fn_info_ = [dir_info_,code_ctp,'_info.txt'];
f.loadinfo(fn_info_);
if isempty(f.contract_size)
    %not loaded
    f.init(bbg.ds_);
    f.saveinfo(fn_info_);
end

files = dir(dir_data_);
nfiles = size(files,1);


coldefs = {'datetime','open','high','low','close'};
permission = 'w';
usedatestr = true;
startdate = f.first_trade_date1;
lbd = getlastbusinessdate;
enddate = min(lbd,f.last_trade_date1);
bds = gendates('fromdate',startdate,'todate',enddate);

for i = 1:size(bds,1)
    bd = datestr(bds(i),'yyyy-mm-dd');
    fn_ = [f.code_ctp,'_',datestr(bd,'yyyymmdd'),'_1m.txt'];
    %first check whether fn_ exists
    flag = false;
    for j = 1:nfiles
        if strcmpi(fn_,files(j).name)
            flag = true;
            break
        end
    end
    if ~flag || (flag && override)
        fn_ = [dir_data_,f.code_ctp,'_',datestr(bd,'yyyymmdd'),'_1m.txt'];
        data = bbg.intradaybar(f,bd,bd,1,'trade');
        cDataFileIO.saveDataToTxtFile(fn_,data,coldefs,permission,usedatestr);
    end
    
end

fprintf('done with %s\n',code_ctp);

end

