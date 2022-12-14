function [lengths] = min_z(list_properties,threshold,rejection_options) % Second Input added by KP 08/10/20
if (~exist('threshold','var')); threshold = 3; end % Third Input added by KP 08/10/20
if (~exist('rejection_options','var'))
    rejection_options.measure=ones(1,size(list_properties,2));
    rejection_options.z=threshold*ones(1,size(list_properties,2));
end

rejection_options.measure=logical(rejection_options.measure);
zs=list_properties-repmat(mean(list_properties,1),size(list_properties,1),1);
zs=zs./repmat(std(zs,[],1),size(list_properties,1),1);
zs(isnan(zs))=0;
all_l = abs(zs) > repmat(rejection_options.z,size(list_properties,1),1);
lengths = any(all_l(:,rejection_options.measure),2);