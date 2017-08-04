function [cf,C,lambda,mu1,mu2] = train_lda(X,labels,param)
% Trains a linear discriminant analysis with (optional) shrinkage
% regularisation of the covariance matrix.
%
% Usage:
% cf = train_lda(X,labels,<param>)
% cf = train_lda(X,labels,lambda)
% 
%Parameters:
% X              - [number of samples x number of features] matrix of
%                  training samples
% labels         - [number of samples] vector of class labels containing 
%                  1's (class 1) and -1's (class 2)
%
% param          - struct with hyperparameters:
% .lambda        - regularisation parameter between 0 and 1 (where 0 means
%                   no regularisation and 1 means full max regularisation).
%                   If 'auto' then the regularisation parameter is
%                   calculated automatically using the Ledoit-Wolf formula(
%                   function cov1para.m)
%
% Note that lambda can also be directly specified by setting params to the
% lambda value.
%
%Output:
% cf - struct specifying the classifier with the following fields:
% classifier   - 'lda', type of the classifier
% w            - projection vector (normal to the hyperplane)
% b            - bias term, setting the threshold 
%
% The following fields can be returned optionally:
% C            - covariance matrix (possibly regularised)
% mu1,mu2      - class means
%

% (c) Matthias Treder 2017

if ~exist('param','var') || isempty(param)
    param.lambda = 0;
elseif ~isstruct(param)
    % lambda was provided directly
    tmp = param;
    param=[];
    param.lambda= tmp;
end

idx1= (labels==1);   % logical indices for samples in class 1
idx2= (labels==-1);  % logical indices for samples in class 2

N1 = sum(idx1);
N2 = sum(idx2);
N= N1 + N2;

% Calculate common covariance matrix
% Should be weighted by the relative class proportions
C= N1/N * cov(X(idx1,:)) + N2/N * cov(X(idx2,:));

% Get class means
mu1= mean(X(idx1,:))';
mu2= mean(X(idx2,:))';

% Regularise covariance matrix using shrinkage
if (ischar(param.lambda)&&strcmp(param.lambda,'auto')) || param.lambda>0

    if ischar(param.lambda)&&strcmp(param.lambda,'auto') 
        % Here we use the Ledoit-Wolf method to estimate the regularisation
        % parameter analytically.
        % Get samples from each class separately and correct by the class
        % means mu1 and mu2 using bsxfun.
        [~,param.lambda]= cov1para([bsxfun(@minus,X(idx1,:),mu1');bsxfun(@minus,X(idx2,:),mu2')]);
    end
    I = eye(size(C,1));
    
    % We write the regularised covariance matrix as a convex combination of
    % the empirical covariance C and an identity matrix I scaled to have
    % the same trace as C
    C = (1-param.lambda)* C + param.lambda*I*trace(C)/size(X,2);
end

% Get the classifier projection vector (normal to the hyperplane)
w = C\(mu1-mu2);

% Bias term determining the classification threshold
b= w'*(mu1+mu2)/2;

%% Prepare output
cf= struct();
cf.classifier= 'LDA';
cf.w= w;
cf.b= b;

if nargout>2
    lambda= param.lambda;
end
