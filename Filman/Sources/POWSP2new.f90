! POWSP2.FOR- EXTRACTS 2 EQUAL-LENGTH TIME SERIES FROM EACH CHANNEL
! RECORD (E.G., BEFORE-TRIAL & DURING-TRIAL SEGMENTS), 
! COMPUTES THEIR POWER SPECTRA, AND OUTPUTS RATIO OF SECOND-SEGMENT
! TO FIRST-SEGMENT INTENSITIES IN DB. TAPERING AND TRUNCATION INCLUDED.
! AUTOMATIC DETRENDING OF INPUT DATA ADDED 3/95.

SUBROUTINE POWSP2new
    USE MKL_DFTI
    INCLUDE 'MAX.INC'
	DIMENSION WORK(IOMAX-120),WK1((IOMAX-120)/2),WK2((IOMAX-120)/2)
	COMMON IFLAG1,IFLAG2,IFLAG3,KNT,ISZ,ICHAN(ICHMAX)
	COMMON /FLDES/NG,NA,NC,ND,NF,NL,NR,IS,IBUF(IOMAX)
	COMMON/FLDESO/NGO,NAO,NCO,NDO,NFO,NLO,NRO,ISO,IBUFO(IOMAX)
	INTEGER*4, SAVE :: NXFM,IT,NID,J1,IFF,IL,IOUT,IO1
	REAL*4, SAVE :: ANPO
    INTEGER*4 :: Status,I,I1,J,K,L
    REAL*4 :: XV,XI,WORK,WK1,WK2,X,Y
    REAL*8 :: FNYQ,DF,FMAX
	EQUIVALENCE (WORK,IBUFO(121)),(WK1,WORK),(WK2,WORK((IOMAX-120)/2+1))
    type(DFTI_DESCRIPTOR), POINTER, SAVE :: FFTDescriptor_Handle
    COMMON /CPN/ CURPROCNAME
    CHARACTER*10 CURPROCNAME
    external R

! EQUIVALENCE ALLOWS 120 WORDS FOR NGO+NAO- WE DON'T CHECK

IF(IFLAG1)1,20,60

1   NFO=3
    CURPROCNAME='POWSP2'
    WRITE(*,*) CURPROCNAME
	NID=NGO+NAO
	IO1=121-NID  ! POINTS TO FIRST WORD OF OUTPUT RECORD
! MOVE CHANNEL LABELS
	J=6*NGO+109
	DO 12 I=1,NCO
	    L=J+5
	    K=6*(NG+ICHAN(I))-5
	    DO 10 I1=J,L
	        IBUFO(I1)=IBUF(K)
10          K=K+1
12      J=J+6

! PARTITION INPUT TIME SERIES

	NPO=NDO
	FNYQ=float(IS)*0.5
	IFF=1
	IL=NPO

13  CALL DoPOWSP2Dialog(NPO,IFF,IL,IOUT,IT,FMAX,FNYQ)
	IF(2*IL-NPO)5,5,4
4   Call ShowInfoText('Error','TOO MANY PTS REQUESTED; REENTER SPECS')
	GO TO 13

5   NXFM=IL
	ISZ=120+2*(NXFM+2)
	IT=IT+1
	FNYQ=FLOAT(IS)/2.0
	IF(FMAX.EQ.0.0)FMAX=FNYQ
	DF=FLOAT(IS)/FLOAT(NXFM)
	ISO=FMAX
	NDO=FMAX/DF + 1
	ANPO=NDO-1
    WRITE(*,'(A,I4,A,I4,A,F6.2,A)') " First point = ", IFF, "; number points = ", IL, &
        "; maximum frequency = " ,FMAX, "Hz"
    IF(IT.EQ.2) WRITE(*,*) "With Hann filtering"
    ! Create FFT descriptor
    Status = DftiCreateDescriptor(FFTDescriptor_Handle, DFTI_SINGLE, DFTI_REAL, 1, NXFM)

    Status = DftiCommitDescriptor(FFTDescriptor_Handle)
    RETURN

! RUNNING SECTION; FIRST COPY INPUT SEGMENTS TO WORK AREAS

20  J=1
	DO 25 I=IFF,IFF+IL-1
	    CALL XVAL(I,XV,XI)
	    WK1(J)=XV
	    CALL XVAL(I+IL,XV,XI)
	    WK2(J)=XV
25      J=J+1

! DO TRANSFORMS AFTER REMOVING OFFSET AND TREND FROM EACH SEGMENT

	CALL DETRND(WK1,NXFM,2)
	CALL DETRND(WK2,NXFM,2)
    Status = DftiComputeForward(FFTDescriptor_Handle, WK1)
    Status = DftiComputeForward(FFTDescriptor_Handle, WK2)

! CALCULATE SPECTRA

    K=1
	DO 30 I=1,NDO
	    WK1(I)=WK1(K)**2 + WK1(K+1)**2
	    WK2(I)=WK2(K)**2 + WK2(K+1)**2
30      K=K+2

! SMOOTH IF REQUESTED( THIS IS AWKWARD & SHOULD BE INTEGRATED
! WITH FOLLOWING LOOP TO AVOID ALL THE IN-PLACE SHUFFLING)

	GO TO (40,31) IT

31  TMP1=WK1(1)
	TMP2=WK2(1)
	DO 35 I=2,NDO-1
	    X=0.5*WK1(I) + 0.25*(TMP1 + WK1(I+1))
	    TMP1=WK1(I)
	    WK1(I)=X
	    Y=0.5*WK2(I) + 0.25*(TMP2 + WK2(I+1))
	    TMP2=WK2(I)
35      WK2(I)=Y

! COMPUTE CHANGES, STORING THEIR AVERAGE IN DC TERM

40  XTOT=0.0
	DO 45 I=2,NDO
	    GO TO (41,42) IOUT
41      X=WK2(I) - WK1(I)
	    GO TO 43
42      X = R(WK1(I)) - R(WK2(I))
43      WK1(I)=X
45      XTOT=XTOT + X
	WK1(1)=XTOT/ANPO

! COPY ID INFO & WRITE RECORD

	J=IO1
	DO 50 I=1,NID
	    IBUFO(J)=IBUFO(I)
50      J=J+1
	CALL PUTSTD(IBUFO(IO1))
    RETURN

60  Status = DftiFreeDescriptor(FFTDescriptor_Handle)
    RETURN
	END

REAL*4 FUNCTION R(X)
    REAL*4, INTENT(IN) :: X
	IF(X.LE.0.0) GOTO 10
    R = LOG10(X)
	RETURN
10  R = -100.0
    RETURN
END
