function [res,errorL2]=OS_SART_CBCT(proj,geo,alpha,niter,block_size,lambda)

%% Deal with input parameters
if nargin<6
    lambda=1;
end
errorL2=[];

%% Create weigthing matrices

% Projection weigth, W
% Projection weigth, W
W=1./Ax(ones(geo.nVoxel'),geo,alpha);  %

% Back-Projection weigth, V
[x,y]=meshgrid(geo.sVoxel(1)/2-geo.dVoxel(1)/2+geo.offOrigin(1):-geo.dVoxel(1):-geo.sVoxel(1)/2+geo.dVoxel(1)/2+geo.offOrigin(1),...
    -geo.sVoxel(2)/2+geo.dVoxel(2)/2+geo.offOrigin(2): geo.dVoxel(2): geo.sVoxel(2)/2-geo.dVoxel(2)/2+geo.offOrigin(2));
A = permute(alpha, [1 3 2]);
V = (geo.DSO ./ (geo.DSO + bsxfun(@times, y, sin(-A)) - bsxfun(@times, x, cos(-A)))).^2;
V=sum(V,3);
clear A x y dx dz;


%% initialize image With FDK

% TODO : this should be optional
% TODO : Actually call FDK here
% geo.filter='ram-lak';
% proj_filt = filtering(proj,geo,alpha);
% geo=rmfield(geo,'filter');
% res=Atb(proj_filt,geo,alpha);
res=zeros(geo.nVoxel');


%% Iterate

% TODO : Add options for Stopping criteria
for ii=1:niter
    if ii==1;tic;end
    
    for jj=1:block_size:length(alpha);
        % idex of the Oriented subsets
        range=(jj-1)*block_size+1:block_size*jj;
        range(range>length(alpha))=[]; % for the last subset
        
        proj_err=proj(:,:,range)-Ax(res,geo,alpha(range));      %                                 (b-Ax)
        weighted_err=W(:,:,range).*proj_err;                    %                          W^-1 * (b-Ax)
        backprj=Atb(weighted_err,geo,alpha(range));             %                     At * W^-1 * (b-Ax)
        weigth_backprj=bsxfun(@times,1./V,backprj);             %                 V * At * W^-1 * (b-Ax)
        res=res+lambda*weigth_backprj;                          % x= x + lambda * V * At * W^-1 * (b-Ax)
        
        
        
    end
    errornow=norm(proj_err(:));                           % Compute error norm2 of b-Ax
    % If the error is not minimized (Armijo rules)
    if ii>1 && (errornow>errorL2(end))
        return;
    end
    errorL2=[errorL2 errornow];
    if ii==1;disp(['Expected time: ', num2str(toc*niter), ' seconds' ]);end
end





end