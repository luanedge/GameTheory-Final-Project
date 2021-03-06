% MY Best Response Dynamics with Fictitious Play
% Simple example with number matrix

close all;
clear all;
clc;

n = 5;  % number of choices
t = 1;  % number of individuals

% Similarity matrix, payoff matrix
A = [   0, 70, 60, 23, 15; ...
        70, 0, 90, 25, 20; ...
        60, 90, 0, 5, 25; ...
        23, 25, 5, 0, 70; ...
        15, 20, 25, 70, 0];
    
% A = -A + max(max(A));
    
x = ones(n, 1) / n;

% f = - A * x;
% Aineq = zeros(1, n);
% bineq = 0;
% Aeq = ones(1, n);
% beq = 1;
% lb = zeros(n, 1);
% ub = ones(n, 1);
% y = linprog(f, Aineq, bineq, Aeq, beq, lb, ub);

num_cycles = 1000;

double_vec = zeros(n, 2);

for cycle = 1 : num_cycles
    opponent_payoff = A * x;
    
%     In this way I wll never play the same pixel!
%     I am changing every time! Not suitable!
    max_val = max(opponent_payoff);
    opponent_BR = zeros(n, 1);
    opponent_BR(opponent_payoff == max_val) = 1;
    opponent_BR = opponent_BR ./ sum(opponent_BR);  % BR sums to one in case of multiple best responses
    
%     new_BR = new_payoff ./ sum(new_payoff);

    my_payoff = A' * opponent_BR;
%     sum_old_payoff = sum(old_payoff);
    
    my_avg_payoff = my_payoff' * x;
    my_avg_gain = my_payoff - my_avg_payoff;
    
    % In order not to fixing choosing the same exact pixel, the diagonal of
    % the payoff matrix is set to zero. Thus, if I play the same pixel of
    % my opponent, we both get zero, even though it belongs to the same
    % cluster. I don't want it to be my best response, but I want it to be
    % a feasible choice! Since the matrix is non zero and the only zero
    % values are in the diagonal, the only way I can get a zero payoff is
    % playing the same pixel. Therefore playing the same pixel leads me to
    % the lower gain. I make it positive in order to count it as a good
    % pixel.
    %
    % This case is lucky! But what if the max positive is lower than the
    % min negative?? The same pixel becomes the best response.
    %
    % SOLUTION: I don't increse its probabilty! It is likely already quite
    % high
    
    min_gain_pos = find(my_avg_gain == -my_avg_payoff);
    my_avg_gain(min_gain_pos) = 0;
    
    pos_gains_ind = find(my_avg_gain > 0);
    neg_gains_ind = find(my_avg_gain < 0);
    
    sum_pos = sum(my_avg_gain(pos_gains_ind));
    sum_neg = -sum(my_avg_gain(neg_gains_ind));
    
    ffac = 10;
    
    pos_increments = my_avg_gain(pos_gains_ind) ./ (ffac * sum_pos);
    neg_increments = my_avg_gain(neg_gains_ind) ./ (ffac * sum_neg);
    
%     sum(pos_increments) + sum(neg_increments)
    
    new_x = x;
    new_x(pos_gains_ind) = new_x(pos_gains_ind) + pos_increments;
    new_x(neg_gains_ind) = new_x(neg_gains_ind) + neg_increments;
    
    min_new_x = min(new_x);
    if min_new_x < 0
        new_x = new_x - min_new_x;
        new_x = new_x ./ sum(new_x);
    end
    
    x =  new_x;
    sum(x)
end

% sum(x)