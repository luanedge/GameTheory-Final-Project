% Best Response Dynamics with Fictitious Play
% 1 cluster, B&W
% needs get_payoff.m
% end condition: num cycles

close all;
clear all;
clc;

%% Parameters
img_name = 'tosa.jpg'; % name of the image
t = 1;  % initial number of individuals in the population
sigma = 1000;    % standard deviation
% delta = 0.001;   % maximum distance between two probs vectors to stop the loop
num_cycles = 1000;   % number of iterations per cluster (should be automatically found!)
thr = 90;  % percentage of the highest probabilities to keep

%% Main body

img_col = imread(img_name); % acquire the image...
img = rgb2gray(img_col);    % ...and bring it in b&w

% img = [ 200, 200, 200, 130;
%         200, 200, 200, 65
%         200, 200, 200, 65;
%         65, 65, 65, 65];
% img = uint8(img);

[img_height, img_width] = size(img);
n = img_width * img_height; % number of pixels

% Show the original image
figure; imshow(img); title('Original');

A = get_payoff(img, sigma); % compute the payoff matrix

% Probability vector. Initially set to a uniform distribution
x = ones(n, 1) / n;
prev_x = zeros(n, 1);   % previous x vector

num_cycl = 0;

norms = zeros(1, num_cycles);

can_do_better = 1;  % loop condition
for cycle = 1 : num_cycles
% while can_do_better
    
    num_cycl = num_cycl + 1;
    
    [~, index_max] = max(A * x);    % position of the pure strategy which is a best response
    r = zeros(n, 1);    % pure strategy r
    r(index_max) = 1;
    y = x + (r - x) / (t + 1);  % new population strategy
    
    t = t + 1;  % increment population
    prev_x = x; % update the "previous" population strategy
    x = y;      % update the population strategy
    
    norms(cycle) = norm(x - prev_x);
    
%     update the loop condition

% 1) norm of diff between prob vectors
%     if norm(x - prev_x) > delta     % probabilities are still strongly changing
%         can_do_better = 1;
%     else
%         can_do_better = 0;
%     end
    
    % 2) diff of highest prob
%     max_diff = max(abs(x - prev_x));
%     if max_diff > delta     % probabilities are still strongly changing
%         can_do_better = 1;
%     else
%         can_do_better = 0;
%     end
end

% for cycle = 1 : num_cycles
%     [~, index_max] = max(A * x);
%     r = zeros(n, 1);
%     r(index_max) = 1;
%     y = x + (r - x) / (t + 1);
%     
%     t = t + 1;
%     x = y;
% end
    
%% Normalize the probabilities
min_prob = min(x);  % smallest probability. This will become zero
x = x - min_prob;
max_prob = max(x);  % highest probanility. This will become one
x = x ./ max_prob;
    
%% Display cluster
img_cluster = zeros(img_height, img_width); % in this image we show the cluster
for i = 1 : n   % for each probability
    if x(i) > 1 - thr/100    % "high" prob of playing this choice
        % Track back the image pixel
        yy = ceil(i / img_width);
        xx = rem(i, img_width);
        if xx == 0
            xx = img_width;
        end
        img_cluster(yy, xx) = 255;  % set the pixel to WHITE
    end
end

figure; plot(1 : num_cycles, norms);

figure; imshow(img_cluster); title('Cluster');