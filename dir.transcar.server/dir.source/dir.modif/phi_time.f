	subroutine phi_time(iyd,tu,phi_tmp,ndeg,mdeg,Lmin,Lmax,latequi)
	
c        implicit none
	
	integer ndegmax,mdegmax,nmdegmax
	integer ndeg,mdeg,nmdeg,k
	parameter(ndegmax=10,mdegmax=10,nmdegmax=(ndegmax+1)*(mdegmax+1))
        complex*16 phi(0:5,0:5,3),phi_tmp(1:nmdegmax)

	integer n,m,iyd,iyddeb,iydfin
	real tu,xkp,tempsdeb,tempsfin
        real*8 Lmin,Lmax,Linf,Lsup,latequi
	real temps,xr1,xi1,xr2,xi2
        logical flgini
	real*8 xt,xtd,xtf

        real lonma1,latma1,tmag,cofo,cofh,cofn,Fe0,Ee0,Fi0,Ei0
        real Bmag,dipangle,Enord1,Eest1
        real vperpnord,vperpest,vhorizon,vpara
        real orient,chi
        real B,dip,or,ddp,Jtop

        common/buff/lonma1,latma1,tmag,ikp,cofo,cofh,cofn,chi,
     &                  Fe0,Ee0,Fi0,Ei0,
     &                  Bmag,dipangle,Enord1,Eest1,
     &                  vperpnord,vperpest,vhorizon,vpara,ddp,Jtop





	data phi /
c       	Kp = 0 a 2-
     &	( 0.293,-0.073),(-0.810,1.432),(-0.144,1.318),( 0.051, 0.513),
     & 	( 0.029, 0.100),(-0.035,-0.014),
     &  (-0.226, 0.098),(1.103,-1.740),( 0.620,-0.723),(0.241,-0.579),
     &	(0.290,-0.046),(-0.025,0.017),
     &	(-0.097,-0.030),(-0.462,0.807),(-0.422,0.399),(-0.102,0.042),
     &	(-0.164,-0.006),(-0.211,-0.063),
     & 	(0.026,0.004),(-0.147,-0.068),(-0.109,-0.089),(-0.215,0.078),
     &	(-0.071,0.025),(0.034,0.118),
     &  (-0.014,0.005),(0.009,-0.075),(0.127,-0.095),(0.086,-0.020),
     &	(0.035,-0.068),(0.052,-0.006),
     &	(0.017,-0.005),(0.048,0.042),(0.003,0.050),(0.042,0.012),
     &	(0.014,0.026),(0.003,-0.036),
c       	Kp = 2 a 4-
     &	(0.366,-0.304),(-0.475,7.321),(-1.470,2.696),(-0.170,0.358),
     &	(0.072,0.239),(0.070,0.034),
     &	(-0.145,0.319),(4.626,-8.764),(2.234,-1.445),(0.010,0.262),
     & 	(0.387,0.330),(0.117,0.175),
     &	(-0.316,0.022),(-1.718,1.601),(0.248,-0.838),(-0.038,-0.467),
     &	(-0.430,-0.427),(-0.364,0.097),
     &	(-0.005,-0.048),(-0.009,0.531),(-0.618,0.809),(0.055,0.118),
     &	(0.210,-0.163),(0.279,-0.266),
     &	(0.086,0.008),(0.175,-0.272),(0.078,-0.220),(-0.122,0.069),
     & 	(0.063,0.108),(0.171,-0.010),
     &	(0.014,0.003),(-0.025,0.014),(0.021,0.022),(0.014,-0.083),
     &	(-0.047,-0.010),(-0.145,0.114),
c       	Kp = 4 a 6-
     &	(1.242,-0.308),(-1.137,17.243),(-3.430,2.003),(0.453,-0.254),
     &	(0.259,-0.101),(-0.081,-0.492),
     &	(-0.382,0.311),(10.731,-11.999),(4.326,0.486),(-1.069,1.401),
     &	(0.003,0.336),(0.296,-0.287),
     &	(-1.096,0.028),(-1.825,-0.792),(2.459,-1.157),(1.278,-0.034),
     &	(-0.286,0.315),(-0.426,0.611),
     &	(0.199,-0.062),(-0.769,1.431),(-1.488,0.317),(0.103,0.003),
     &	(0.346,0.240),(-0.011,-0.135),
     &	(0.159,0.016),(0.092,-0.130),(-0.100,-0.009),(-0.188,0.085),
     &	(0.004,-0.055),(-0.004,-0.265),
     &	(-0.122,0.015),(0.076,-0.281),(0.155,-0.096),(0.057,-0.134),
     &	(-0.096,0.020),(-0.059,0.152)/

       data Linf,Lsup /61.500,72.500/


	data iyddeb  ,tempsdeb,iydfin  ,tempsfin,flgini
     &	    /3000365.,24.     ,1980001.,0.      ,T/

        include '../dir.cine/TRANSPORT.INC'


	real e1,f1,coefchamp
        common /E930216/e1,f1,coefchamp

	if (flgini) then
	  ierr=1	
	  flgini=.false.
	  open(67,file=chemin//'dir.source/dir.convection/varpot.dat',
     &		form='formatted',status='old',iostat=ierr,err=999)
	endif

999	continue
	close(67)

	if (ierr.gt.0) then
c
c        xkp=kp(mod(tu+86400.,86400.))
	  xkp=1.
	  k=0
	  ndeg=5
	  mdeg=5
	  if(xkp.le.1.) then
	    do n=0,ndeg
	      do m=0,mdeg
	        k=k+1
	        phi_tmp(k)=phi(m,n,1)
	      enddo
	    enddo
	  else if(xkp.le.3.) then
	    indkpmin=1
	    indkpmax=2
	    kpmin=1.
	    kpmax=3.
	    do n=0,ndeg
	      do m=0,mdeg
	        k=k+1
	        phi_tmp(k)=phi(m,n,2)
	      enddo
	    enddo
	  else
	    do n=0,ndeg
	      do m=0,mdeg
	        k=k+1
	        phi_tmp(k)=phi(m,n,3)
	      enddo
	    enddo
	  endif
	  Lmin=Linf
	  Lmax=Lsup
	  latequi=60.
	else
	  open(67,file=chemin//'dir.source/dir.convection/varpot.dat',
     &		form='formatted',status='unknown',iostat=ierr)
	  temps=tu/3600.d0
	  xt=iyd+temps/100.d0
        if (iyd.lt.1900000) xt=xt+1900000.

	  xtd=iyddeb+tempsdeb/100.d0
	  xtf=iydfin+tempsfin/100.d0

	  dowhile (xtd.gt.xt.or.xtf.le.xt)

	    read(67,*) iyddeb,tempsdeb,iydfin,tempsfin,
     &		       ndeg,mdeg,Lmin,Lmax,latequi,ddp

	    nmdeg=(ndeg+1)*(mdeg+1)

	    xtd=iyddeb+tempsdeb/100.d0
	    xtf=iydfin+tempsfin/100.d0

c	    do j=0,5
c	      do i=0,5,2
c	        read(67,*) phi_tmp(i,j),phi_tmp(i+1,j)
c	      enddo
c	    enddo

	    read(67,*) (phi_tmp(k),k=1,nmdeg)

c	    k=0
c	    do j=0,5
c	      do i=0,5
c                if (tu.le.43200.)then
c                  coefchamp=2.5
c                elseif (tu.le.46800) then
c                  if (tu.lt.45600.) then
c                    coefchamp=3.
c                  else
c                    coefchamp=2.1
c                  endif
c                else
c                  coefchamp=2.5
c                endif
c		k=k+1
c	        phi_tmp(k)=coefchamp*phi_tmp(k)
c	      enddo
c	    enddo
	    enddo

	  close(67)
	endif

	return
	end
