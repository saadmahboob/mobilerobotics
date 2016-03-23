clear;clc;
%% Depiction of the map
% Draw a real map
M = 52; % Height of the map
N = 52; % Width of the map
map_real = create_a_map(M,N); % Create a random map with obstacles

% Generate the belief map
map_bel = 0.5 * ones(M,N); % Give 0.5 probability to uncertain cells
map_bel_logodds = log(map_bel./(1-map_bel)); % Transform the belief map into log-odds form

%% Robot Motion
% Time of simulation
T = 80; % 120[sec] simulation time

% Robot State Initialization
x0= [ round(40 +2*randn(1)), round(40 + 2*randn(1)), 0]; % Initial states of robot
X = zeros(3,length(1:T));

% Produce Robot Motions
X = robot_motion(map_real, X, x0, T);

%% Sensor Parameters
meas_phi = -0.4:0.05:0.4; % Laser headings
rmax = 20; % Maximum range of laser
alpha = 1; % Distance about measurement to fill in
beta = 0.01; % Angle beyond which to exclude 

%% Inverse measurement model based on Bresenham ray-tracing algorithm

% Initialization of inverse measurement model
inv_mm = zeros(M,N); 
for i = 1 : length(X) % Each robot motion step
    
   % Actual range of measurement
   meas_r = getranges(map_real,X(:,i),meas_phi,rmax);
   
   for j = 1 : length(meas_r) 
      % Compute inverse measurement model
      inv_meas_mod = inversescannerbres(M, N, X(1,i), X(2,i), X(3,i) + meas_phi(j), meas_r(j), rmax);
      
      for k = 1 : length(inv_meas_mod(:,1)) 
          x_pos = inv_meas_mod(k,1); % x coordinate of the cell
          y_pos = inv_meas_mod(k,2); % y coordinate of the cell
          cell_prob = inv_meas_mod(k,3); % Probability of an obstacle of the cell
          
          % Updates of inverse measurement model    
          inv_mm(x_pos, y_pos) = inv_mm(x_pos, y_pos) + log(cell_prob ./ (1-cell_prob)) - map_bel_logodds(x_pos,y_pos);       
      end
   end
   
   % Transform inverse measurement model from log-odds form to pobability
     inv_mm = exp(inv_mm) ./ (1+exp(inv_mm));
         
   % Plot Inverse Measurement Model
     figure(1);clf;hold on;
     image(100 * (1-inv_mm));
     colormap('gray');
     title('Inverse measurement model');
     axis ([0 M 0 N]);
     
   % plot areas of have high possibility of obstacles (end points of laser beam)
     for j=1:length(meas_r) 
        plot( X(2,i) + meas_r(j) * sin (meas_phi(j) + X(3,i)) , X(1,i) + meas_r(j) * cos (meas_phi(j) + X(3,i)) ,'ko','MarkerSize',5);
     end  

   % Plot real map and robot position
     figure(2);clf;hold on;
     image(100 * (1-map_real));
     colormap('gray');
     plot(X(2,i),X(1,i),'x','Markersize',10);
     plot(X(2,1:i),X(1,1:i),'-','Linewidth',2);
     title('Real map & Robot positions');
 
end