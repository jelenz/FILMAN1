! XSPEC.f90- PROGRAM TO READ INPUT FILE OF K CHANNELS OF COMPLEX FOURIER
! COEFFICIENTS AND WRITE OUTPUT FILE OF UP TO K(K-1)/2 CHANNELS OF
! CROSS-SPECTRAL INFORMATION. EACH OUTPUT CHANNEL CONTAINS EITHER
! TRANSFER RATIOS, COHERENCES(0-1), AND/OR PHASES(IN RADIANS), OR COMPLEX-
! VALUED CROSS-SPECTRAL ESTIMATES, ALL COMPUTED FOR A USER-SPECIFIED
! RANGE OF THE RAW (PERIODOGRAM) FREQUENCY SPECTRUM, SMOOTHED IN THE
! FREQUENCY DOMAIN BY AVERAGING OVER BLOCKS OF USER-SPECIFIED SIZE.
! NOTE THAT BLOCKSIZE MUST BE AT LEAST 2 FOR MEANINGFUL COHERENCE
! ESTIMATES, & PREFERABLY MUCH LARGER (SEE BENDAT&PIERSOL, P193FF)

SUBROUTINE XSPECnew
    INCLUDE 'MAX.INC'
	COMMON IFLAG1,IFLAG2,IFLAG3,KNT,ISZ,ICHAN(ICHMAX)
	COMMON/FLDES/NG,NA,NC,ND,NF,NP,NR,IS,IBUF(IOMAX)
	COMMON/FLDESO/NGO,NAO,NCO,NDO,NFO,NPO,NRO,ISO,IBUFO(IOMAX)
	COMPLEX CXY,TXY,CX
	DIMENSION XY(2),LBLS(2,ICHMAX),XC(2),YC(2)
	INTEGER*4, SAVE :: IC,NSO,JR,NBLK,NPB,K,NCO1,NCO2,NSO1
	INTEGER*4, SAVE :: ICHOFF,IMAG,ICPX
	INTEGER*1, SAVE :: IJGO(ICHMAX,ICHMAX),ICOMP(4)
    REAL*4, SAVE :: AN
    CHARACTER*24 CHANNELCHARS
    CHARACTER*1 CHANNELCHAR(24)
    INTEGER*4 CHANNELINTS(6)
    EQUIVALENCE (CHANNELCHARS,CHANNELCHAR(1),CHANNELINTS(1))
    CHARACTER*8 WORKCHARS
    CHARACTER*1 WORKCHAR(8)
    INTEGER*4 WORKINT(2)
    EQUIVALENCE (WORKCHARS,WORKCHAR(1),WORKINT(1))
	CHARACTER*1 ANS
	EQUIVALENCE (CX,XC),(XC(1),IXR),(XC(2),IXI)
	EQUIVALENCE (XR,IXR),(XI,IXI),(YR,IYR),(YI,IYI)
	EQUIVALENCE (CXY,XY),(XYR,XY(1)),(XYI,XY(2))
	DATA IBL /'    '/
	CHARACTER*128 ALINE
    COMMON /CPN/ CURPROCNAME
    CHARACTER*10 CURPROCNAME
	
	IF(IFLAG1)10,50,80

10  CURPROCNAME='XSPEC'
    WRITE(*,*) CURPROCNAME
	NCO1=NCO
	NCO2=NCO-1
	NPC=NDO/2
	NPC1=NPC-1
! DISPLAY SELECTED CHANNELS, GET SHORT LABELS, AND IDENTIFY NEEDED PAIRS

! Set defaults: assume "upper right" triangle
    Do 1610,I=1,NCO1
    Do 1610,J=1,NCO1
        IF(J.GT.I)THEN
            IJGO(I,J)=1
        ELSE
            IJGO(I,J)=0
        ENDIF
1610    CONTINUE
    ICOMP(1)=1 !Magnitude of transform: on
    ICOMP(2)=1 !Coherence: on
    ICOMP(3)=0 !Phase of the transform: off
    ICOMP(4)=0 !Complex transform: off
    JR=2
    NBLK=NPC1
    NPB=1
	DO 1611 I=1,NCO1
	    J2=6*(NG+ICHAN(I))
	    J1=J2-5
	    DO 1611,I2=1,2
1611	    LBLS(I2,ICHAN(I))=IBUF(J1+I2-1)
            
30          CALL DoXSPECDialog(IJGO,NCO1,NPC1,JR,NBLK,NPB,ICOMP,LBLS)
            ! IJGO is channel pair indicator array
            ! JR = first point for blocking
            ! NBLK = number of blocks
            ! NPB = number of points per block
            ! ICOMP is array indicating what is to be computed (see above)
            ! LBLS is array of shortened channel labels, to be used in creating new labels
    
    IMAG = ICOMP(1) + ICOMP(2) + ICOMP(3)
    IF(IMAG .GT. 0) THEN
        IF(ICOMP(4) .GT. 0) THEN
            CALL ShowInfoText('Error','Must have only real or only complex outputs')
            GOTO 30 !Must have only real or complex results
        ENDIF
        NFO = 3 !Real format
    ELSE
        IF(ICOMP(4) .EQ. 0) THEN
            CALL ShowInfoText('Error','No output selected')
            GOTO 30 !Must have at least one result
        ENDIF
        NFO = 4 !Complex only format
    ENDIF

! GET and check COMPUTATION PARAMETERS

	IF(IMAG .EQ. 0 .AND. (ICOMP(2)*NPB) .NE. 1) GO TO 35
    IMAG = IMAG - 1
	ICOMP(2)=0
	IF(IMAG .EQ. 0) THEN
        CALL ShowInfotext('Error', &
            'COHERENCES FOR RAW SPECTRA ARE 1.0; REQUEST SUPPRESSED; NO OUTPUTS REMAIN')
        GOTO 30
    ELSE
        CALL ShowInfotext('Warning', &
            'COHERENCES FOR RAW SPECTRA ARE 1.0; REQUEST SUPPRESSED')
    ENDIF
    
! Count number of channels needed in output file

35	NCO3=0
	DO 17 I=1,NCO2
	    J1=I+1
	    DO 17 J=J1,NCO1
17  NCO3=NCO3+IJGO(I,J)

    IF(NCO3 .EQ. 0) GOTO 30 !Must have at least one channel pair
    
! NOW RUN THROUGH IJGO & CONSTRUCT OUTPUT CHANNEL LABELS: "Chan1<->Chan2"

	L=109+6*NGO
	DO 20 I=1,NCO2
	    J1=I+1
	    DO 20 J=J1,NCO1
	        IF(IJGO(ICHAN(I),ICHAN(J)) .EQ. 0) GOTO 20
            DO 22 K=1,6
22              CHANNELINTS(K) = IBL
            CHANNELINTS(1) = LBLS(1,ICHAN(I))
            CHANNELINTS(2) = LBLS(2,ICHAN(I))
            L1 = LEN_TRIM(CHANNELCHARS) + 1
            CHANNELCHAR(L1) = '<'
            CHANNELCHAR(L1+1) = '-'
            CHANNELCHAR(L1+2) = '>'
            L1 = L1+3
            WORKINT(1) = LBLS(1,ICHAN(J))
            WORKINT(2) = LBLS(2,ICHAN(J))
            L2 = LEN_TRIM(WORKCHARS)
            CHANNELCHAR(L1:L1+L2) = WORKCHAR(1:L2)
            DO 23 K=1,6
                IBUFO(L) = CHANNELINTS(K)
23              L=L+1
20          CONTINUE

! ALL SPECS IN; SET UP STORAGE & OUTPUT SCHEMES
	IF(NFO .EQ. 3) THEN
        NDO = IMAG * NBLK
    ELSE
        NDO = 2 * NBLK
    ENDIF
37	NPC=NBLK*NPB
	ICHOFF=2*NPC
	AN=FLOAT(NPB)
	ISZ=ICHOFF*NCO1
	IMAX=IOMAX-NGO-NAO
	IF(ISZ-IMAX)39,39,38
38  WRITE(ALINE,2111)IMAX,ISZ
2111    FORMAT('AVAILABLE SPACE ONLY ',I4,' WORDS; REQUESTED ',I5,'.')
    CALL ShowInfoText('Error',ALINE)
    GOTO 30
39	NSO1=NGO+NAO
	NSO=NSO1+1
	NCO=NCO3
	IC=0
	K=NSO
    IF(IMAG.GT.0) THEN
        IF(ICOMP(1).EQ.1) WRITE(*,*) "Compute transfer magnitude"
        IF(ICOMP(2).EQ.1) WRITE(*,*) "Compute coherence"
        IF(ICOMP(3).EQ.1) WRITE(*,*) "Compute phase difference"
    ELSE
        WRITE(*,*) "Compute complex cross spectra"
    ENDIF
    WRITE(*,'(A,I3,A,I3,A,I3)') " First point = ", JR, "; number blocks = ", NBLK, &
        "; number points/block = " , NPB
    RETURN

! PROCESSING PHASE- FIRST MOVE RAW COMPLEX COEFFICIENTS INTO IBUFO
! CHANNELS SELECTED IN FILMAN BUT NOT USED IN XSPEC ARE CURRENTLY STORED
! ANYWAY; ELIMINATE IN FINAL VERSION

50	L=JR
	DO 55 J=1,NBLK
	    DO 55 I=1,NPB
            CALL XVAL(L,XR,XI)
	        L=L+1
	        IBUFO(K)=IXR
	        IBUFO(K+1)=IXI
55	        K=K+2

! CHECK IF LAST CHANNEL; IF SO RESET IC AND START COMPUTATIONS
! NOTE THAT THIS ALGORITHM WASTEFUL IN THAT IT REPEATEDLY COMPUTES
! AUTOSPECTRA AS PART OF COHERENCE COMPUTATIONS FOR ANY CHANNELS
! INVOLVED IN MULTIPLE PAIRS; FINAL VERSION CAN STORE THEM IN IBUF

	IC=IC+1
	IF(IC.LT.NCO1) GO TO 80
    
56	IC=0
	K=NSO
! COPY GROUP VAR STUFF INTO IBUF; ASSUMES ALL BUT CHAN # CONSTANT
	DO 57 I=2,NSO1
57	    IBUF(I)=IBUFO(I)
	IBUF(1)=0
    
! MAIN LOOP

	DO 75 I=1,NCO2
	    I1=I+1
	    ICX0=NSO+(I-1)*ICHOFF !determine offset to first channel location
	    DO 75 J=I1,NCO1
! CHECK IF THIS PAIR TO BE ANALYZED; IF NOT, CONTINUE
	        IF(IJGO(ICHAN(I),ICHAN(J)).EQ.0) GO TO 75
	        IBUF(1)=IBUF(1)+1 !update channel number
	        ICX=ICX0
	        ICY=NSO+(J-1)*ICHOFF !determine offset to second channel location
	        K1=NSO
	        DO 70 L=1,NBLK !for each block
	            K2=K1
	            TXY=0.0
	            GXY=0.0
	            GX=0.0
	            GY=0.0
	            DO 63 M=1,NPB !for each point in this block
! COMPUTE X-SPECTRUM AT EACH FREQUENCY BAND, AVERAGING NEEDED QUANTITIES
! ACROSS BANDS WITHIN EACH BLOCK
	                IXR=IBUFO(ICX) !complex point for first channel
	                IXI=IBUFO(ICX+1)
	                ICX=ICX+2
	                IYR=IBUFO(ICY) !complex point for second channel
	                IYI=IBUFO(ICY+1)
	                ICY=ICY+2
	                XYR=XR*YR+XI*YI ! SXY=(X)(Y*) => POSITIVE PHASE MEANS X LEADS Y
	                XYI=XI*YR-XR*YI
	                IF(IMAG .EQ. 0) GOTO 63
                    GXY=GXY+SQRT(XYR*XYR+XYI*XYI)
	                GX=GX + XR*XR + XI*XI
	                IF(ICOMP(2) .EQ. 0) GOTO 63 !only need magnitude of Y for coherence
	                GY=GY + YR*YR + YI*YI
63                  TXY=TXY+CXY
    
! NOW COMPUTE & STORE NEEDED QUANTITIES FOR THIS BLOCK

	            IF(IMAG .EQ. 0) GOTO 65 !Complex only
	            IF(ICOMP(1) .EQ. 0) GOTO 642
	            XR=GXY/GX
	            IBUF(K2)=IXR
	            K2=K2+NBLK
642	            IF(ICOMP(2) .EQ. 0) GOTO 643
	            XI=GXY/SQRT(GX*GY)
	            IBUF(K2)=IXI
	            K2=K2+NBLK
643	            IF(ICOMP(3) .EQ. 0) GOTO 70
	            XI=ATAN2(XYI,XYR)
	            IBUF(K2)=IXI
                GOTO 70

65	            CX=TXY/AN
	            IBUF(K2)=IXR
	            IBUF(K2+1)=IXI
                K1=K1+1
70	            K1=K1+1
	        CALL PUTSTD(IBUF) !write out this channel
75          CONTINUE !find next channel pair

80	RETURN
END
      