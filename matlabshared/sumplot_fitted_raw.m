function sumploth=sumplot_fitted_raw(datadir,fittedfile,rawfile,altlims)

sumploth=figure(688);
%set(gcf,'PaperPosition',[0,0,8.5,11]);
%% LOAD FLUID AND TIMING DATA
fittedFN = [datadir,'/',fittedfile];
display(['sumplot_fitted_raw: loading ',fittedFN])
load(fittedFN)

rawFN = [datadir,'/',rawfile];
display(['sumplot_fitted_raw: loading ',rawFN])
load(rawFN)
%% FONT AND LINEWIDTH SETTINGS
FS=8; LW=4;
%% CORRECT TIME VARIABLE FOR PLOTTING PURPOSES
maxtime=max(istime);
mintime=min(istime);
tspan=maxtime-mintime;
tinds=find(istime>=mintime & istime<=maxtime);
zinds=find(isz>=altlims(1) & isz<=altlims(2));
minz=min(isz(zinds)); maxz=max(isz(zinds)); zspan=maxz-minz;

tindsraw=find(istimeraw>=mintime & istimeraw<=maxtime);
zindsraw=find(iszraw>=altlims(1) & iszraw<=altlims(2));
minzraw=min(iszraw(zindsraw)); maxzraw=max(iszraw(zindsraw)); zspanraw=maxzraw-minzraw;
%% FIGURE OUT HOW TO BEST DISPLAY TIME AXIS
nlab=6;                                                 %nominal number of labels on time axis
xlims=[istime(tinds(1)), istime(tinds(length(tinds)))];
dx=(xlims(2)-xlims(1))/nlab;
if dx<1/60                                              %labels need seconds to be unambiguous
    fmt='hms';
else                                                    %including seconds is pointless
    fmt='hm';
end
xloc=xlims(1):dx:xlims(2);
xlab=time2str(xloc,'clock',fmt);
%% INTERPOLATE VARIABLES FOR IMAGESC PLOTTING PURPOSES
tplot=istime(tinds);
zplot=minz:24:maxz;             %24km range res.
for k=1:length(tinds);
    tiplot(:,k)=interpolateTRANSCAR(isti(zinds,tinds(k)),isz(zinds),zplot,'lin','lin');
    teplot(:,k)=interpolateTRANSCAR(iste(zinds,tinds(k)),isz(zinds),zplot,'lin','lin');
    neplot(:,k)=interpolateTRANSCAR(isne(zinds,tinds(k)),isz(zinds),zplot,'lin','lin') ;
    viplot(:,k)=interpolateTRANSCAR(isvi(zinds,tinds(k)),isz(zinds),zplot,'lin','lin');
end

tplotraw=istimeraw(tindsraw);
zplotraw=minzraw:1.5:maxzraw;
for k=1:length(tindsraw)
    neplotraw(:,k)=interpolateTRANSCAR(isneraw(zindsraw,tindsraw(k)),iszraw(zindsraw),zplotraw,'lin','lin') ;
end
%% IONOSPHERIC RESPONSE AS AN ISR WOULD SEE
FS=9;

h=subplot(5,1,3);  %pbaspect([8.5 11/6 1]);
imagesc(tplot,zplot,flipud(tiplot),[700 2800])
c=colorbar;
set(h,'FontSize',FS)
set(h,'Xtick',xloc); %FIXME: use datetick
set(h,'XtickLabel',xlab);
yloc0=get(h,'YTick');
dyloc=yloc0-round(minz);
newyloc=round(maxz)-dyloc;
set(h,'YTick',sort(newyloc))
set(h,'YTickLabel',fliplr(yloc0))
xlabel('UT')
ylabel('altitude (km)')
colormap('gray')
ax=axis;
text(ax(1)+.015,ax(3)+100,'(c)',....
    'FontSize',FS+10,'Color',[1 1 1],'FontWeight','bold')
ylabel(c,'T_i (K)')

h = subplot(5,1,4); %pbaspect([8.5 11/6 1]);
imagesc(tplot,zplot,flipud(teplot),[700 2800])
c=colorbar;
set(h,'FontSize',FS)
set(h,'Xtick',xloc)
set(h,'XtickLabel',xlab)
yloc0=get(h,'YTick');
dyloc=yloc0-round(minz);
newyloc=round(maxz)-dyloc;
set(h,'YTick',sort(newyloc))
set(h,'YTickLabel',fliplr(yloc0))
xlabel('UT')
ylabel('altitude (km)')
colormap('gray')
ax=axis;
text(ax(1)+.015,ax(3)+100,'(d)',...
    'FontSize',FS+10,'Color',[1 1 1],'FontWeight','bold')
ylabel(c,'T_e (K)')

h = subplot(5,1,1); %pbaspect([8.5 11/6 1]);
maxlogne=11.6;%max(neplot(:));
imagesc(tplot,zplot,flipud(neplot),[10 maxlogne])
c=colorbar;
set(h,'FontSize',FS)
set(h,'Xtick',xloc)
set(h,'XtickLabel',xlab)
yloc0=get(h,'YTick');
dyloc=yloc0-round(minz);
newyloc=round(maxz)-dyloc;
set(h,'YTick',sort(newyloc),'YTickLabel',fliplr(yloc0))
xlabel('UT')
ylabel('altitude (km)')
colormap('gray')
ax=axis;
text(ax(1)+.015,ax(3)+100,'(a)',...
    'FontSize',FS+10,'Color',[1 1 1],'FontWeight','bold')
ylabel(c,'log_{10}(n_e) (m^{-3})')

h = subplot(5,1,2);% pbaspect([8.5 11/6 1]);
imagesc(tplotraw,zplotraw,flipud(neplotraw),[10 maxlogne])
c=colorbar;
set(h,'FontSize',FS,'Xtick',xloc,'XtickLabel',xlab)
yloc0=get(h,'YTick');
dyloc=yloc0-round(minzraw);
newyloc=round(maxzraw)-dyloc;
set(h,'YTick',sort(newyloc),'YTickLabel',fliplr(yloc0))
xlabel('UT')
ylabel('altitude (km)')
colormap('gray')
ax=axis;
text(ax(1)+.015,ax(3)+25,'(b)',...
    'FontSize',FS+10,'Color',[1 1 1],'FontWeight','bold')
ylabel(c,'log_{10}(raw n_e) (m^{-3})')

h = subplot(5,1,5); %pbaspect([8.5 11/6 1]);
imagesc(tplot,zplot,flipud(viplot),[-100 400])
set(h,'FontSize',FS,'Xtick',xloc,'XtickLabel',xlab)
yloc0=get(h,'YTick');
dyloc=yloc0-round(minz);
newyloc=round(maxz)-dyloc;
set(h,'YTick',sort(newyloc),'YTickLabel',fliplr(yloc0));
c=colorbar('FontSize',FS);
xlabel('UT')
ylabel('altitude (km)')
colormap('gray')
ax=axis;
text(ax(1)+.015,ax(3)+100,'(e)',...
    'FontSize',FS+10,'Color',[1 1 1],'FontWeight','bold')
ylabel(c,'v_i (m/s)')

end %function
