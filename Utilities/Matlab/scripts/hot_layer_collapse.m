% McDermott
% 10-7-14
% hot_layer_collapse.m
%
% H. Baum. "Collapse of a Hot Layer in a Micro-Gravity Environment", Sep 2, 2014 (personal notes)

close all
clear all

datadir='../../Verification/Flowfields/';
plotdir='../../Manuals/FDS_Verification_Guide/SCRIPT_FIGURES/';

if ~exist([datadir,'hot_layer_360_devc.csv'])
   display(['Error: File ',[datadir,'hot_layer_360_devc.csv'],' does not exist. Skipping case.'])
   return
end

plot_style

error_tolerance = 0.01;

L = 2;                 % height of domain 2*d where d is the layer depth at t=0
N = 360;               % number of cells in vertical direction
T_0 = 293.15;          % cold wall temperature (K)
T_h = 1172.6;          % hot layer initial temperature (K)
k_0 = 1;               % W/m/K
rho_0 = 1;             % kg/m^3
Cp = 1000;             % J/kg/K
d  = 1;                % m
v0 = k_0/(rho_0*Cp*d); % m/s

dz = L/N;

t = [.2,.4,.6,.8,1,2,4,6,8,10];
tau = t*1e-3;
marker_style = {'ko','mo','ro','go','bo'};
exact_soln_style = {'k-','m-','r-','g-','b-'};
legend_entries = {'\tau = 2 \times 10^{-4}','\tau = 4 \times 10^{-4}','\tau = 6 \times 10^{-4}','\tau = 8 \times 10^{-4}','\tau = 10 \times 10^{-4}'};

% analytical solution

f = @(lambda_in,tau_in,a_in) -2*sqrt(tau_in/pi)*exp(-(a_in-lambda_in).^2/(4*tau_in)) + ...
    (a_in+lambda_in).*erfc((a_in+lambda_in)/(2*sqrt(tau_in)));
F = @(lambda_in,tau_in,a_in) f(lambda_in,tau_in,a_in) - f(0,tau_in,a_in);
Y = @(lambda_in,tau_in,T_h_in,T_0_in) lambda_in + (T_h_in-T_0_in)/T_0_in*( -F(lambda_in,tau_in,0) + ...
    0.5*( F(lambda_in,tau_in,T_0_in/T_h_in) + F(lambda_in,tau_in,-T_0_in/T_h_in) ) );
U = @(lambda_in,tau_in,T_h_in,T_0_in) -erfc(lambda_in/(2*sqrt(tau_in))) + ...
    0.5*( erfc( (lambda_in - T_0_in/T_h_in)/(2*sqrt(tau_in)) ) + erfc( (lambda_in + T_0_in/T_h_in)/(2*sqrt(tau_in)) ) );
Theta = @(lambda_in,tau_in,T_h_in,T_0_in) 1. + ( (T_h_in - T_0_in)/T_0_in )*U(lambda_in,tau_in,T_h_in,T_0_in);
G = @(lambda_in,tau_in,a_in) 1/sqrt(pi*tau_in)*( -exp(-(a_in+lambda_in).^2/(4*tau_in)) + exp(-a_in^2/(4*tau_in)) );
V = @(lambda_in,tau_in,T_h_in,T_0_in) (T_h_in-T_0_in)/T_0_in*( -G(lambda_in,tau_in,0) + ...
    0.5*(G(lambda_in,tau_in,T_0_in/T_h_in) + G(lambda_in,tau_in,-T_0_in/T_h_in)) );

lambda = linspace(0,10*T_0/T_h,1000);

% % test
% plot(Theta(lambda,tau(1),T_h,T_0),lambda/(T_0/T_h))
% return

% get FDS data

M = importdata([datadir,'hot_layer_360_devc.csv'],',',2);

for j=1:length(tau)
    J(j) = find(M.data(:,1)>=t(j),1);
end

T_range = 2:41;
W_range = 42:81;
dz_40 = L/40; % devices are based on N=40 resolution
dz_360 = L/360; % but N=360 is used for verification (3^3*40)

z_T = dz_40/2:dz_40:L-dz_40/2; % exact T location is the same as for the N=40 case
z_W = dz_40/2+dz_360/2:dz_40:L-dz_40/2+dz_360/2; % capture exact staggered z location of W component of velocity

for j=1:5

    T = (M.data(J(j),T_range)+273.15)/T_0;
    W = M.data(J(j),W_range)/v0;
    figure(1)
    H(j)=plot(T,z_T,marker_style{j}); hold on
    plot(Theta(lambda,tau(j),T_h,T_0),Y(lambda,tau(j),T_h,T_0),exact_soln_style{j})
    figure(2)
    H2(j)=plot(W,z_W,marker_style{j}); hold on
    plot(V(lambda,tau(j),T_h,T_0),Y(lambda,tau(j),T_h,T_0),exact_soln_style{j})

end

figure(1)

xlabel('{\it T/T_0}','fontsize',Label_Font_Size,'FontName',Font_Name)
ylabel('{\it y/d}','fontsize',Label_Font_Size,'FontName',Font_Name)
axis([1 4 0 1.2])
legend(H,legend_entries,'location','southwest')
legend boxoff

Git_Filename = [datadir,'hot_layer_360_git.txt'];
addverstr(gca,Git_Filename,'linear')

set(gca,'FontName',Font_Name)
set(gca,'FontSize',Label_Font_Size)
set(gcf,'Visible',Figure_Visibility);
set(gcf,'PaperUnits',Paper_Units);
set(gcf,'PaperSize',[Paper_Width Paper_Height]);
set(gcf,'PaperPosition',[0 0 Paper_Width Paper_Height]);
print(gcf,'-dpdf',[plotdir,'hot_layer_temp_1'])

% compute temperature error at tau(5)

% map nondimensional position
for i=1:length(z_T)
    I(i) = find(Y(lambda,tau(5),T_h,T_0)>=z_T(i),1);
end
% % test
% figure
% plot(T,z_T,'ko'); hold on
% plot(Theta(lambda(I),tau(5),T_h,T_0),Y(lambda(I),tau(5),T_h,T_0),'k+')
% return

Error = norm(T-Theta(lambda(I),tau(5),T_h,T_0))/max(T)/length(T);
if Error>error_tolerance
    display(['Matlab Warning: hot_layer_360.fds Temp_1 Error = ',num2str(Error)])
end

figure(2)

xlabel('{\it v/v_0}','fontsize',Label_Font_Size,'FontName',Font_Name)
ylabel('{\it y/d}','fontsize',Label_Font_Size,'FontName',Font_Name)
axis([-200 0 0 1.2])
legend(H2,legend_entries,'location','southwest')
legend boxoff

% add SVN if file is available

Git_Filename = [datadir,'hot_layer_360_git.txt'];
addverstr(gca,Git_Filename,'linear')

set(gca,'FontName',Font_Name)
set(gca,'FontSize',Label_Font_Size)
set(gcf,'Visible',Figure_Visibility);
set(gcf,'PaperUnits',Paper_Units);
set(gcf,'PaperSize',[Paper_Width Paper_Height]);
set(gcf,'PaperPosition',[0 0 Paper_Width Paper_Height]);
print(gcf,'-dpdf',[plotdir,'hot_layer_vel_1'])

% compute velocity error at tau(5)

% map nondimensional position
for i=1:length(z_W)
    I(i) = find(Y(lambda,tau(5),T_h,T_0)>=z_W(i),1);
end
% % test
% figure
% plot(W,z_W,'ko'); hold on
% plot(V(lambda(I),tau(5),T_h,T_0),Y(lambda(I),tau(5),T_h,T_0),'k+')
% return

Error = norm(W-V(lambda(I),tau(5),T_h,T_0))/max(abs(W))/length(W);
if Error>error_tolerance
    display(['Matlab Warning: hot_layer_360.fds Vel_1 Error = ',num2str(Error)])
end

% second set of Howard's plots

legend_entries_2 = {'\tau = 2 \times 10^{-3}','\tau = 4 \times 10^{-3}','\tau = 6 \times 10^{-3}','\tau = 8 \times 10^{-3}','\tau = 10 \times 10^{-3}'};

for j=6:10
    jj=j-5;

    T = (M.data(J(j),T_range)+273.15)/T_0;
    W = M.data(J(j),W_range)/v0;
    figure(3)
    H3(jj)=plot(T,z_T,marker_style{jj}); hold on
    plot(Theta(lambda,tau(j),T_h,T_0),Y(lambda,tau(j),T_h,T_0),exact_soln_style{jj})
    figure(4)
    H4(jj)=plot(W,z_W,marker_style{jj}); hold on
    plot(V(lambda,tau(j),T_h,T_0),Y(lambda,tau(j),T_h,T_0),exact_soln_style{jj})

end

figure(3)

xlabel('{\it T/T_0}','fontsize',Label_Font_Size,'FontName',Font_Name)
ylabel('{\it y/d}','fontsize',Label_Font_Size,'FontName',Font_Name)
axis([1 4 0 1.2])
legend(H3,legend_entries_2,'location','northeast')
legend boxoff

% add SVN if file is available

Git_Filename = [datadir,'hot_layer_360_git.txt'];
addverstr(gca,Git_Filename,'linear')

set(gca,'FontName',Font_Name)
set(gca,'FontSize',Label_Font_Size)
set(gcf,'Visible',Figure_Visibility);
set(gcf,'PaperUnits',Paper_Units);
set(gcf,'PaperSize',[Paper_Width Paper_Height]);
set(gcf,'PaperPosition',[0 0 Paper_Width Paper_Height]);
print(gcf,'-dpdf',[plotdir,'hot_layer_temp_2'])

% compute temperature error at tau(10)

% map nondimensional position
for i=1:length(z_T)
    I(i) = find(Y(lambda,tau(10),T_h,T_0)>=z_T(i),1);
end
% % test
% figure
% plot(T,z_T,'ko'); hold on
% plot(Theta(lambda(I),tau(10),T_h,T_0),Y(lambda(I),tau(10),T_h,T_0),'k+')
% return

Error = norm(T-Theta(lambda(I),tau(10),T_h,T_0))/max(T)/length(T);
if Error>error_tolerance
    display(['Matlab Warning: hot_layer_360.fds Temp_2 Error = ',num2str(Error)])
end

figure(4)

xlabel('{\it v/v_0}','fontsize',Label_Font_Size,'FontName',Font_Name)
ylabel('{\it y/d}','fontsize',Label_Font_Size,'FontName',Font_Name)
axis([-60 0 0 1.6])
legend(H4,legend_entries_2,'location','northwest')
legend boxoff

% add SVN if file is available

Git_Filename = [datadir,'hot_layer_360_git.txt'];
addverstr(gca,Git_Filename,'linear')

set(gca,'FontName',Font_Name)
set(gca,'FontSize',Label_Font_Size)
set(gcf,'Visible',Figure_Visibility);
set(gcf,'PaperUnits',Paper_Units);
set(gcf,'PaperSize',[Paper_Width Paper_Height]);
set(gcf,'PaperPosition',[0 0 Paper_Width Paper_Height]);
print(gcf,'-dpdf',[plotdir,'hot_layer_vel_2'])

% compute velocity error at tau(10)

% map nondimensional position
for i=1:length(z_W)
    I(i) = find(Y(lambda,tau(10),T_h,T_0)>=z_W(i),1);
end
% % test
% figure
% plot(W,z_W,'ko'); hold on
% plot(V(lambda(I),tau(10),T_h,T_0),Y(lambda(I),tau(10),T_h,T_0),'k+')
% return

Error = norm(W-V(lambda(I),tau(10),T_h,T_0))/max(abs(W))/length(W);
if Error>error_tolerance
    display(['Matlab Warning: hot_layer_360.fds Vel_2 Error = ',num2str(Error)])
end






