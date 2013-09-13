!DEC$ FREEFORM 
! AVRALL.f90- AVERAGES POINTS ACROSS RECSETS, WITHIN CHANNELS.
! +/- AVERAGING AND 9-POINT SMOOTHING FOR SEP DATA ADDED 10/12/91.
! NEW FILMAN VERSION 11/92 USES ALLOCATABLE ARRAY FOR PROCESSING.
! AUTOMATIC DETRENDING OF TIME DATA ADDED 3/95.
! GENERALIZATION TO COMPLEX DATA STILL PENDING.

SUBROUTINE AVRALL
    INCLUDE 'MAX.INC'
    REAL, ALLOCATABLE, SAVE :: WORK(:,:),WORK1(:)
    COMMON IFLAG1,IFLAG2,IFLAG3,KNT,ISZ,ICHAN(ICHMAX)
    COMMON/FLDES/ NG,NA,NC,ND,NF,NL,NR,IS,IBUF(IOMAX)
    COMMON/FLDESO/ NGO,NAO,NCO,NDO,NFO,NLO,NRO,ISO,IBUFO(IOMAX)
    EQUIVALENCE (IP,X)
    INTEGER, SAVE :: IC,ISIGN,IABBA,ITYPE,IFILT,NTOT,IDTRND
    COMMON /CPN/ CURPROCNAME
    CHARACTER*10 CURPROCNAME

    IF(IFLAG1) 10,20,30
10	NFO=3
    CURPROCNAME='AVRALL'
    WRITE(*,*) CURPROCNAME
    ALLOCATE(WORK(NDO,NCO),STAT=IERR)
    ALLOCATE(WORK1(NDO),STAT=IERR)
    IF(IERR.EQ.0) GO TO 15
    CALL ShowInfoText('Error','Allocation failure; try again')
15  J=6*NGO+109
    DO 12 I=1,NCO
        L=J+5
        K=6*(NG+ICHAN(I))-5
        DO 40 I1=J,L
            IBUFO(I1)=IBUF(K)
40	        K=K+1
12	    J=J+6
    ISZ=NDO     ! FOR ALL BUT COMPLEX DATA
    IC=1        ! CHANNEL INDEX
    ISIGN=1     ! SWITCH FOR +/- AVERAGES
    IABBA=0     ! FLAG FOR ABBA AVERAGING
    IT=0        ! ASSUME NO DATA TRANSFORM    
    NTOT=0
    CALL DoAVRALLDialog(IDTRND,IT,ITYPE,IFILT)
    ITYPE = ITYPE + 1
    DO 5 J=1,NDO  ! Zero
        DO 5 I=1,NCO
5           WORK(J,I)=0.0
    IF(IDTRND.EQ.1) WRITE(*,*) "Detrend data"
    SELECT CASE(IT)
    CASE(1)
        WRITE(*,*) "Square root transform"
    CASE(2)
        WRITE(*,*) "Natural log transform"
    CASE(3)
        WRITE(*,*) "Arcsine transform"
    CASE(4)
        WRITE(*,*) "Absolute value transform"
    END SELECT
    SELECT CASE(ITYPE)
    CASE(1)
        WRITE(*,*) "Normal averaging"
    CASE(2)
        WRITE(*,*) "Plus/minus averaging"
    CASE(3)
        WRITE(*,*) "ABBA averaging"
    END SELECT
    IF(IFILT.EQ.1) WRITE(*,*) "Nine-point smoothing"
    RETURN

! EXECUTION PHASE; FIRST GET THIS CHANNEL'S DATA

20	DO 70 I=1,NDO ! read all the data for this channel
        CALL XVAL(I,XV,XI)
70      WORK1(I)=RECODE(XV,IT)
    IF(IDTRND.EQ.1) CALL DETRND(WORK1,NDO,2) ! detrend it if requested
! NOW DO THE AVERAGING PER SELECTED REGIME
    DO 80 I=1,NDO   
        X=WORK(I,IC)    ! CURRENT SUM
        Y=WORK1(I)      ! NEW VALUE
        IF(ISIGN)61,62,62 !alternate adding a subtracting current values from sum
61	    X=X-Y
        GO TO 65
62	    X=X+Y
65      WORK(I,IC)=X
80      CONTINUE
    IC=IC+1 ! move on to next channel
    IF(IC-NCO) 21,21,22
22  IC=1
    GO TO (25,24,23) ITYPE
23  IABBA=IABBA+1
    IF(IABBA.EQ.2 .OR. IABBA.EQ.6) GO TO 25
    IF(IABBA.EQ.8) IABBA=0
24  ISIGN = -ISIGN  ! CHANGE SIGN FOR +/- AVERAGES
25  NTOT=NTOT+1
21	RETURN

! TERMINATION PHASE- WRITE DATA RECORDS

30	TOT=NTOT
    DO 31 K=1,NCO
        IF(IFILT.EQ.1) CALL NINEPT(WORK(1,K),NDO) ! do 9-point smoothing
        J=NGO+NAO+1
        DO 34 I=1,NDO
            X=WORK(I,K)/TOT
            IBUFO(J)=IP
34	        J=J+1
        IBUFO(1)=K
31	    CALL PUTSTD(IBUFO)
	DEALLOCATE(WORK,STAT=IERR)
	DEALLOCATE(WORK1,STAT=IERR)
	IF(IERR.NE.0)CALL ShowInfoText('Error','DEALLOCATION FAILURE')
	RETURN
END

! NINE-POINT SMOOTHING SUBROUTINE FOR SEP DATA; SEE SAVITSKY AND GOLAY,
! ANAL. CHEM. 36:1627 FF, 1964 FOR DETAILS.
!------------------------------------------------------------

SUBROUTINE NINEPT(X,N)
	DIMENSION X(*),COEFF(4),HIST(4)
    DATA COEFF /54.,39.,14.,-21./

! INITIALIZE HISTORY; NEED TO KEEP CIRCULAR BUFFER OF UNTRANSFORMED DATA

	DO 5 J=1,4
5       HIST(J)=X(1)
	DO 30 I=1,N
	    TEMP=X(I)
	    SUM=0.
	    DO 20 J=1,4
	        I2=I+J
! AFTER STARTUP CHECK FOR RIGHT EDGE
	        IF(I2-N)20,20,15
15	        I2=N
20	        SUM=SUM+COEFF(J)*(HIST(J)+X(I2))
	    X(I)=(59.*X(I)+SUM)/231.
! UPDATE HISTORY
	    DO 25 J=3,1,-1
25	        HIST(J+1)=HIST(J)
	    HIST(1)=TEMP
30	    CONTINUE
	RETURN
END