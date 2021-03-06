%%
list_entrust_opt = EntrustArray;

%%
code1 = 'm1801-C-2700';
code2 = 'm1801-P-2700';
code3 = 'm1801-C-2750';
code4 = 'm1801-P-2750';
code5 = 'm1801-C-2650';
code6 = 'm1801-P-2650';
code7 = 'm1801-C-2800';
code8 = 'm1801-P-2800';
wopt.addsingle(code1);
wopt.addsingle(code2);
wopt.addsingle(code3);
wopt.addsingle(code4);
wopt.addsingle(code5);
wopt.addsingle(code6);
wopt.addsingle(code7);
wopt.addsingle(code8);

%%
wopt.refresh;
q = wopt.qs;
strike1 = q{1}.opt_strike;
strike2 = q{3}.opt_strike;
strike3 = q{5}.opt_strike;
strike4 = q{7}.opt_strike;

fprintf('\nIV:');
for i = 1:size(q,1)-1
    fprintf('%4.1f%%,',q{i}.impvol*100);
end
fprintf('\n');

last_trade = q{end}.last_trade;
if (strike1-last_trade)*(strike2-last_trade)<=0
    k1 = strike1;
    k2 = strike2;
    idx1 = 1;
    idx2 = 3;
elseif (strike3-last_trade)*(strike1-last_trade)<=0
    k1 = strike3;
    k2 = strike1;
    idx1 = 5;
    idx2 = 1;
elseif (strike2-last_trade)*(strike4-last_trade)<=0
    k1 = strike2;
    k2 = strike4;
    idx1 = 7;
    idx2 = 3;
end

v2_opt = (last_trade-k1)/(k2-k1);
v1_opt = 1 - v2_opt;

v1_opt = round(v1_opt*10);
v2_opt = round(v2_opt*10);
fprintf('strikes:%d,%d\n',k1,k2);
fprintf('lots:%d,%d\n',v1_opt,v2_opt);

mult = 10;
vega = v1_opt*(q{idx1}.vega+q{idx1+1}.vega)+v2_opt*(q{idx2}.vega+q{idx2+1}.vega)*mult;
delta = v1_opt*(q{idx1}.delta+q{idx1+1}.delta)+v2_opt*(q{idx2}.delta+q{idx2+1}.delta)*mult*last_trade;
theta = v1_opt*(q{idx1}.theta+q{idx1+1}.theta)+v2_opt*(q{idx2}.theta+q{idx2+1}.theta)*mult;
delta_fut = last_trade*mult;

direction = -1;
fprintf('theta:%4.2f, vega:%4.2f, delta opt:%4.2f, delta fut:%4.2f\n',direction*theta,direction*vega, direction*delta,direction*delta_fut);

%%
%direction indicates long or short straddle
wopt.refresh;
direction = -1;
offset = 1;
n = 1;
e1 = Entrust;
e2 = Entrust;
e3 = Entrust;
e4 = Entrust;

if direction == 1
    if v1_opt ~= 0 
        e1.fillEntrust(1,wopt.singles{idx1},direction,q{idx1}.ask1,n*v1_opt,offset,wopt.singles{idx1});
        e2.fillEntrust(1,wopt.singles{idx1+1},direction,q{idx1+1}.ask1,n*v1_opt,offset,wopt.singles{idx1+1});
    end
    if v2_opt ~= 0
        e3.fillEntrust(1,wopt.singles{idx2},direction,q{idx2}.ask1,n*v2_opt,offset,wopt.singles{idx2});
        e4.fillEntrust(1,woopt.singles{idx2+1},direction,q{idx2+1}.ask1,n*v2_opt,offset,wopt.singles{idx2+1}); 
    end
else
    if v1_opt ~= 0
        e1.fillEntrust(1,wopt.singles{idx1},direction,q{idx1}.bid1,n*v1_opt,offset,wopt.singles{idx1});
        e2.fillEntrust(1,wopt.singles{idx1+1},direction,q{idx1+1}.bid1,n*v1_opt,offset,wopt.singles{idx1+1});
    end
    if v2_opt ~= 0
        e3.fillEntrust(1,wopt.singles{idx2},direction,q{idx2}.bid1,n*v2_opt,offset,wopt.singles{idx2});
        e4.fillEntrust(1,wopt.singles{idx2+1},direction,q{idx2+1}.bid1,n*v2_opt,offset,wopt.singles{idx2+1}); 
    end
end

c_ly.placeEntrust(e1);
c_ly.placeEntrust(e2);
c_ly.placeEntrust(e3);
c_ly.placeEntrust(e4);

list_entrust_opt.push(e1);
list_entrust_opt.push(e2);
list_entrust_opt.push(e3);
list_entrust_opt.push(e4);

%%
% ��ѯ�ֲ�
wopt.refresh;
n = wopt.countsingles;
opt_delta = 0;
opt_gamma = 0;
opt_vega = 0;
opt_theta = 0;

fprintf('\n');
for i = 1:n
    code_i = wopt.singles_ctp{i};
    q_i = wopt.getquote(code_i);
    pos_i = c_ly.queryPositions(code_i);
    delta_i = pos_i.direction*pos_i.total_position*q_i.delta*q_i.last_trade_underlier*mult;
    gamma_i = pos_i.direction*pos_i.total_position*q_i.gamma*mult;
    vega_i = pos_i.direction*pos_i.total_position*q_i.vega*mult;
    theta_i = pos_i.direction*pos_i.total_position*q_i.theta*mult;
    fprintf('option:%s; ',code_i)
    fprintf('iv:%4.1f%%; ',q_i.impvol*100);
    fprintf('delta:%8.0f; ',delta_i);
    fprintf('gamma:%5.0f; ',gamma_i);
    fprintf('theta:%5.0f; ',theta_i);
    fprintf('vega:%8.0f; ',vega_i);
    fprintf('pos:%d ',pos_i(1).direction*pos_i(1).total_position);
    opt_delta = opt_delta + delta_i; 
    opt_gamma = opt_gamma + gamma_i;
    opt_vega = opt_vega + vega_i;
    opt_theta = opt_theta + theta_i;
    fprintf('\n');
end

pos_fut = c_ly.queryPositions('m1801');
fut_delta = q_i.last_trade_underlier*pos_fut(1).total_position*10*pos_fut(1).direction;

fprintf('spot:%4.0f; ',q_i.last_trade_underlier);
fprintf('theta:%4.0f; ',opt_theta);
fprintf('gamma:%4.0f; ',opt_gamma);
fprintf('vega:%4.0f; ',opt_vega);
fprintf('delta opt:%4.0f; ',opt_delta);
fprintf('delta fut:%4.0f; ',fut_delta);
fprintf('lots:%d; ',round(-(opt_delta+fut_delta)./q_i.last_trade_underlier/mult));
fprintf('\n');

%%
% wings
% q_rw = wo.getquote('m1801-C-2750')

 

