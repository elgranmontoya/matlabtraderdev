%rolling 6m historical volatility
nPeriod=63;
ret = rollinfo.DailyReturn(:,2);

close all;
%replicate the index
index = rollinfo.ContinousFutures(:,1:2);
index(1,2) = 100;
for i = 2:size(index,1)
    index(i,2) = index(i-1,2)*exp(ret(i-1));
end
timeseries_plot(index,'dateformat','mmm-yy',...
    'title','�޻�ָ��(����֣����һ���޻�������Լ��');

%calculat the 6m period relative change of the index
periodChange = zeros(size(index,1)-nPeriod+1,2);
for i = nPeriod:size(index,1)
    periodChange(i-nPeriod+1,1) = index(i,1);
    periodChange(i-nPeriod+1,2) = index(i,2)/index(i-nPeriod+1,2)-1;
end
timeseries_plot(periodChange,'dateformat','mmm-yy',...
    'title','�޻�ָ��������֣����һ���޻�������Լ��6������Բ���');

subplot(2,1,1);

subplot(2,1,2);
boxplot(periodChange(:,2),month(periodChange(:,1)));
xlabel('�·�');
ylabel('6������Բ���');
title('�޻�ָ��������֣����һ���޻�������Լ��6������Բ���');


%calculate the 6m volatility
variance = ret.^2;
hv = zeros(length(ret)-nPeriod+1,2);
for i = nPeriod:length(ret)
    hv(i-nPeriod+1,1) = rollinfo.DailyReturn(i,1);
    hv(i-nPeriod+1,2) = sum(variance(i-nPeriod+1:i));
    t = rollinfo.DailyReturn(i,1) - rollinfo.DailyReturn(i-nPeriod+1,1);
    t = t/365;
    hv(i-nPeriod+1,2) = sqrt(hv(i-nPeriod+1,2)/t);
end
timeseries_plot(hv,'dateformat','mmm-yy',...
    'title','֣����һ���޻�������Լ�껯��ʷ�����ʣ�����ʱ������6���£�');

clear variance ret i

