!DEC$ FREEFORM 
! GRPLOT.FOR- SPECIAL ROUTINE TO PLOT SUMMARY DATA FOR ALL LEVELS OF A
! GROUP VARIABLE, IN PARTICULAR DATA WRITTEN BY AVRGRP OR XHIST2. DATA
! FILE MUST CONSIST OF JUST 1 RECORD-SET WITH 1 OR MORE CHANNELS. EACH
! CHANNEL IS PLOTTED SEPARATELY, AND CONTAINS FOR EACH LEVEL OF THE GROUP
! VARIABLE 1 OR MORE VECTORS OF DATA-POINTS, ALL SUCH VECTORS BEING OF 
! THE SAME LENGTH [EXAMPLES: AVRGRP WRITES A VECTOR OF MEANS AND A VECTOR
! OF S.D.'S FOR THE SELECTED DATA VARIABLES, FOR EACH LEVEL OF THE
! CHOSEN GROUP-VARIABLE; XHIST2 WRITES SETS OF CROSS-HISTOGRAMS FOR
! SPECIFIED XHIST VARIABLES, ONE SET FOR EACH LEVEL OF THE CHOSEN
! GROUP-VAR.] GRPLOT PLOTS SPECIFIED DATA-VECTORS (OR SUB-VECTORS), FOR
! ALL LEVELS OF THE GROUP-VARIABLE, EITHER SEPARATELY OR SUPERIMPOSED,
! IDENTIFYING THE LEVELS BY NUMBER IN THE PLOTS. SCALING IS PROVIDED
! AUTOMATICALLY BUT CAN BE OVERRIDDEN. DATA XFORM ALSO ADDED MARCH 79.
    SUBROUTINE GRPLOT
    USE IFQWIN                ! Maciek
    INCLUDE 'MAX.INC'
    RECORD/RCCOORD/S
    CHARACTER*45 TITLE
    CHARACTER*12 CLAB
    CHARACTER*15 INPFIL
    COMMON IFLAG1,IFLAG2,IFLAG3,KNT,ISZ,ICHAN(ICHMAX)
    COMMON /FLDES/NG,NA,NC,ND,NF,NP,NR,IS,IBUF(IOMAX)
    COMMON/FLDESO/NGO,NAO,NCO,NDO,NPO,NRO,ISO,IBUFO(IOMAX)
    COMMON/STDFIL/INPFIL
    EQUIVALENCE (WORK(1),IBUFO(1)),(ILAB,CLAB)
    DIMENSION LIST(25),ICLABS(6,256),WORK(2048),ILAB(6)
    DATA ISL,IYES,INO/'/','Y','N'/
    character*255 aline
    save ispec,ic,nvec,lvecl,x1,nlevl,iblkf,maxx,maxy,ix0
    COMMON/DEV/ITI,ILP,IGRAPH
    LOGICAL TGSC,TLMC
    LOGICAL LPEV,NPTI,WCDX,WMVS
	save TGSC,TLMC,LPEV,NPTI,WCDX,WMVS

	IF(IFLAG1)1,30,80

! MAKE SURE FILE CONTAINS JUST 1 RECORD-SET

1     IFLAG3=0
	IF(NR/NC-1)12,12,11
11    CONTINUE
      CALL ShowInfoText('Error','FILE MUST CONSIST OF 1 RECORD-SET; RETURNING')
        KNT=-1
	RETURN
12    ISZ=0
! IDENTIFY DATA TYPE & INITIALIZE ABSCISSA LABELING PARAMETERS
	X1=0.
      ISPEC=0	
1818  CALL DoGRPLOTDialog(IPL,NLEVL,NVEC1,LVECL,LIST)
	GO TO(1002,1003,1003,1004)IPL

1002  DX=1.0/FLOAT(IS)
	X1=DX
	GO TO 5

1003  ISPEC=1     ! FLAG TO RESET DX WHEN # POINTS KNOWN
	GO TO 5

1004  DX=1.
	X1=1.   

! STORE CHANNEL LABELS, ETC, FOR LATER USE IN PLOT HEADERS

5   DO 15 J=1,NCO
	    J1=6*(NG+ICHAN(J))-5
	    DO 15 I=1,6
	        ICLABS(I,J)=IBUF(J1)
15          J1=J1+1

! GET STRUCTURE OF INPUT FILE

18  CONTINUE  

   ! CHECK THAT STRUCTURE ENTERED ADDS UP TO NDO

    IF(NLEVL*NVEC1*LVECL-NDO)16,17,16
16  CONTINUE  
    WRITE(*,204)NDO
204 FORMAT('PARAMETERS DON''T ACCOUNT FOR THE ',I4,' INPUT PTS')
    WRITE(ALINE,204)NDO
    Call ShowInfoText('Error',ALINE)
    GO TO 1818

! GET LIST OF VAR-VECTORS TO BE PLOTTED

17  IF(NVEC1-1)10,10,170
10  NVEC=1
    LIST(1)=1
    GO TO 19

170 CONTINUE  
173 NVEC=0
	DO 25 I=1,NVEC1
	    IF(LIST(I))25,25,20
20      IF(LIST(I)-NVEC1)21,21,25
21      NVEC=NVEC+1
	    LIST(NVEC)=LIST(I)
25      CONTINUE

19  IBLKF=LVECL*NVEC1   !OFFSET TO CORRESPONDING DATA, NEXT LEVEL
    IC=0
    NXEQ=0
    IF(ISPEC.EQ.1)DX=FLOAT(IS)/(LVECL-1)
    ISF=1     !SUPERIMPOSE LEVELS
    NFLAG=-1  !DON'T NUMBER THEM
    IXF=0     !USE RAW DATA TO START
    IT=1      !NO DATA XFORM  
    RETURN

30  IC=IC+1

! ENTER PROCESSING PHASE- FIRST GET CHANNEL LABEL 

    DO 31 I=1,6
31      ILAB(I)=ICLABS(I,IC)
    TITLE=''
    DO 75 K=1,NVEC        ! MAIN LOOP, OVER VECTORS
        IXF=0
! GET INDEX TO FIRST POINT OF THIS VECTOR, LEVEL ONE, IN THE INPUT LIST
32      I0=(LIST(K)-1)*LVECL+1
        NPT=LVECL
	    I1=1
	    XFIRST=X1
        WRITE(*,206)LIST(K),ICHAN(IC)
206     FORMAT(/' BEGIN SETUP FOR VAR-VECTOR ',I2,', CHANNEL ',I2)

! CHECK FOR POSSIBLE SUBVECTORING
      
        NPT=LVECL
        I1=I0   !FIRST INPUT POINT TO BE USED FOR NEXT PLOT
	    CALL XVAL(I1,XR,XI)
	    AMAX=XR
	    AMIN=AMAX
	    DO 4001 I=1,NLEVL
	        I2=I1
	        DO 3801 J=1,NPT
                CALL XVAL(I2,X,XI)
	            IF(X-AMIN)4101,3801,3901
4101            AMIN=X
	            GO TO 3801
3901            IF(AMAX-X)4201,3801,3801
4201            AMAX=X
3801            I2=I2+1
4001        I1=I1+IBLKF
	    YMIN=AMIN
	    YMAX=AMAX
	    I1=1
	    IT=0
	    IARES=1
33      CONTINUE
        CALL DoGRPLOTADJUSTDialog(LVECL,I1,NPT,TITLE,IT,LIST(K),ICHAN(IC),AMIN,AMAX,YMIN,YMAX,TGSC,TLMC,LPEV,NPTI,WCDX,WMVS)
        IF(LPEV) GOTO 36
35      CONTINUE  
	    XFIRST=X1+FLOAT(I1-1)*DX
36      II=I0+I1-1   ! KEY INDEX; FIRST POINT TO BE USED 
        IF(WCDX)IXF=1
370     IF(IXF)373,373,371
371     CONTINUE  
        if(.not.wcdx)goto 44

373     CONTINUE  
	    IT=IT+1
	    IXF=1
	    GO TO 38
      
! OBTAIN VERTICAL SCALING IF DESIRED OR NECESSARY

44      IF(NXEQ)38,38,43
43      CONTINUE  
        if(.not.wmvs)goto 47

! SCALING FOR GRPLOT USES ALL LEVELS TO DETERMINE MAX & MIN

38      I1=II   !FIRST INPUT POINT TO BE USED FOR NEXT PLOT
	    CALL XVAL(I1,XR,XI)
	    AMAX=RECODE(XR,IT)
	    AMIN=AMAX
	    DO 40 I=1,NLEVL
	        I2=I1
	        DO 380 J=1,NPT
            CALL XVAL(I2,XR,XI)
	        X=RECODE(XR,IT)
	        IF(X-AMIN)41,380,39
41          AMIN=X
            GO TO 380
39          IF(AMAX-X)42,380,380
42          AMAX=X
380         I2=I2+1
40          I1=I1+IBLKF
	    YMIN=AMIN
	    YMAX=AMAX
46      CONTINUE  

! CHECK SUPERIMPOSITION FLAG

47      CONTINUE  
        if(.not.tgsc)goto 501
49      ISF=-ISF
501     CONTINUE  
        if(.not.tlmc)goto 50
502     NFLAG=-NFLAG

! BEGIN PLOT LOOP FOR THIS VAR-VECTOR

50      I1=II
	    NXEQ=0
	    call graphmode_on(MAXX,MAXY,NROW,NCOL,NBITS,NCOLORS,0)
	    ISTAT=SETVIDEOMODEROWS($MAXRESMODE,$MAXTEXTROWS)
	    CALL SETTEXTWINDOW(1,1,3,80)
	    ISTAT=REGISTERFONTS('C:\FORTRAN\LIB\TMSRB.FON')
	    ISTAT=SETFONT("t'tms rmn'h12w6")
	    CALL CLEARSCREEN(0)
	    DO 70 IL=1,NLEVL
	        I2=I1
	        DO 60 J=1,NPT
                CALL XVAL(I2,XR,XI)
	            WORK(J)=RECODE(XR,IT)
60              I2=I2+1
	        CALL PLOTGR(WORK,NPT,IPL,XFIRST,DX,ISF,NXEQ,YMAX,YMIN,IL,NFLAG)
	        NXEQ=NXEQ+1
      
! ONE PLOT FINISHED; LABEL IT & DETERMINE WHAT TO DO NEXT

	        CALL SETTEXTPOSITION(2,3,S)
	        CALL OUTTEXT(INPFIL)
	        CALL SETTEXTPOSITION(2,20,S)
	        CALL OUTTEXT(CLAB)
	        CALL SETTEXTPOSITION(2,34,S)
	        CALL OUTTEXT(TITLE)
	        CALL SETTEXTPOSITION(1,3,S)
69          CALL DoGRPlotAdvanceDialog(IARES)
            IF(IARES.EQ.2)THEN
                read(IGRAPH,'(A)')KEY
                IARES=0 ! Next
                GOTO 69
            ENDIF
            if(iares.eq.0)goto 70 ! Next
            CALL CLEARSCREEN(0)
            if(iares.eq.1)goto 80 ! Quit
            if(iares.eq.3)goto 33 ! Change
70          I1=I1+IBLKF

! ALL PLOTS FOR THIS SUBVECTORING OF THIS VAR-VECTOR DONE
! DETERMINE WHAT TO DO NEXT

73      CONTINUE  
	    NXEQ=0
75      CONTINUE   ! END OF MAIN LOOP
80  CONTINUE
    call graphmode_off  
    RETURN
    END



! PLOTGR.FOR- SUBROUTINE TO PLOT ONE RECORD FOR GRPLOT; ADAPTED FROM 

! PLOT1.FOR 6/92

    SUBROUTINE PLOTGR(WORK,NPT,IPL,X1,DX,IKP,NXEQ,YMAX,YMIN,IL,NFLAG)
    INCLUDE 'FGRAPH.FD'
    RECORD/XYCOORD/XY
    DIMENSION WORK(NPT)
    CHARACTER*4 XLAB
    CHARACTER*2 NUM

    integer*2 jpl,ix0,ix1,iy0,iytop
    COMMON/DEV/ITI,ILP,IGRAPH
    save ix0,iy0,ixdim,iydim,xdim,ydim,iytop,iylab,scale,n1
    save xscale,yscale,jpl
      
    IF(IKP.EQ.-1)CALL CLEARSCREEN(0)
    IF(IKP*NXEQ)2,2,22

2   N1=1   ! ALWAYS, IN GRPLOT

! EFFECTIVE DIMENSIONS/STARTPOINTS OF PLOTTER TO PERMIT LASDMP

    IXDIM=600
    IYDIM=414
    XDIM=IXDIM
    YDIM=IYDIM
	IX0=20
    IY0=453
	IYTOP=40
    IYLAB=IY0+15

! DETERMINE SCALING FACTORS

5   XSCALE=XDIM/FLOAT(NPT-1) ! PIXELS/DX, EXACT
    GO TO(50,40,50,40)IPL
50  SCALE=YDIM/2.0
    JPL=IY0-SCALE
    YMIN=0.
    GO TO 55
40  JPL=IY0
    SCALE=YDIM
55  YSCALE=SCALE/(YMAX-YMIN)
21  CONTINUE

! FIRST DRAW AXES

    CALL MOVETO(IX0,JPL,XY)
    ISTAT=LINETO(int2(IX0+IXDIM),int2(JPL))
    CALL MOVETO(IX0,IY0,XY)
    ISTAT=LINETO(IX0,IYTOP)

! LABEL X-AXIS

    GO TO(2101,2102,2103,2102)IPL

2101 STEP=.0625
    XINT=.5
    GO TO 2110
2103 CALL MOVETO(IX0,IY0,XY)
    ISTAT=LINETO(int2(IX0+IXDIM),int2(IY0))
2102 CALL MOVETO(IX0,IYTOP,XY)
    ISTAT=LINETO(int2(IX0+IXDIM),int2(IYTOP))
    STEP=1.0
    XINT=10.0
    IF(IPL.EQ.4)XINT=1.0  ! HISTOGRAM BINS
2110 XV1=X1+FLOAT(N1-1)*DX ! VALUE AT FIRST PLOT POINT
    XVN=XV1+FLOAT(NPT-1)*DX ! VALUE AT LAST PLOT POINT
    FTCK=(XVN-XV1)/STEP   ! EXACT # STEPS
    XSCAL2=XDIM/(FTCK)    ! PIXELS/STEP, EXACT

! IF NECESSARY, ADJUST POSITION OF FIRST TICK TO A STEP BOUNDARY

    IOFF=0
    FRACT=STEP-AMOD(XV1,STEP)
    IF(FRACT.EQ.STEP)GO TO 75 ! ALREADY ON A BOUNDARY
    XV1=XV1+FRACT  ! VALUE AT FIRST TICK
    IOFF=IFIX((FRACT/STEP)*XSCAL2+.5)    ! PIXEL OFFSET TO FIRST TICK

! OFFSET CORRECTION IS (STEP FRACTION)*(PIXELS/STEP)

75  IX1=IX0+IOFF
    XI=IX1
    NTCK=INT(FTCK)+1
    XDAT=XV1
    DO 90 I=1,NTCK
	    CALL MOVETO(IX1,JPL-2,XY)
	    ISTAT=LINETO(int2(IX1),int2(JPL+3))
	    CALL MOVETO(IX1,IYTOP+2,XY)
	    ISTAT=LINETO(int2(IX1),int2(IYTOP-3))
	    IF(MOD(IPL,2).EQ.0)GO TO 7999
	    CALL MOVETO(IX1,IY0-2,XY)
	    ISTAT=LINETO(int2(IX1),int2(IY0+3))
7999    IF(AMOD(XDAT,XINT))85,80,85
          
80      CALL MOVETO(IX1,JPL+3,XY)
	    ISTAT=LINETO(int2(IX1),int2(JPL+11))
	    CALL MOVETO(IX1,IYTOP-3,XY)
	    ISTAT=LINETO(int2(IX1),int2(IYTOP-11))
	    IF(MOD(IPL,2).EQ.0)GO TO 8000
	    CALL MOVETO(IX1,IY0-3,XY)
	    ISTAT=LINETO(int2(IX1),int2(IY0-11))
8000    GOTO(8001,8002,8002,8002)IPL
8001    WRITE(XLAB,8010)XDAT
8010    FORMAT(F4.1)
	    GOTO 803
8002    IXDAT=XDAT
	    WRITE(XLAB,81)IXDAT
81      FORMAT(I4)
803     IXL=IX1-20  !START POSITION FOR LABEL
	    CALL MOVETO(IXL,IYLAB,XY)
	    CALL OUTGTEXT(XLAB)
85      XI=XI+XSCAL2
	    IX1=XI+.5
	    XDAT=XDAT+STEP
90      CONTINUE

! DRAW NEXT PLOT

22  IX1=IX0
    Y=(WORK(N1)-YMIN)*YSCALE
    IF(ABS(Y).GT.SCALE) Y=SIGN(SCALE,Y)
    IY1=MAX0((JPL-IFIX(Y)),IYTOP)
    XI=IX1

! ALWAYS WRITE LEVEL NUMBER FOR FIRST POINT

    WRITE(NUM,91)IL
91  FORMAT(I2)
    CALL MOVETO(IX1,IY1,XY)
    CALL OUTGTEXT(NUM)
    CALL MOVETO(IX1,IY1,XY)
    DO 70 I=N1+1,N1+NPT-1
	    XI=XI+XSCALE
        IX2=XI+.5
	    Y=(WORK(I)-YMIN)*YSCALE
	    IF(ABS(Y).GT.SCALE) Y=SIGN(SCALE,Y)
	    IY2=MAX0((JPL-IFIX(Y)),IYTOP)     ! LIMIT PLOT HEIGHT,
	    CALL MOVETO(IX1,IY1,XY)           ! WITH OFFSET POSSIBLE  
	    ISTAT=LINETO(int2(IX2),int2(IY2))
	    IF(NFLAG.EQ.1)CALL OUTGTEXT(NUM)
	    IX1=IX2
	    IY1=IY2
70      CONTINUE
    RETURN
    END
