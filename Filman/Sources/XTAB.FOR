C XTAB.FOR- EL CHEAPO CROSSTABS ROUTINE FOR FILMAN. RUNS UP TO 10

C 2-WAY TABLES, WITH MINIMAL OUTPUT & CHISQUARE STATS ONLY

	SUBROUTINE XTAB

      INCLUDE 'MAX.INC'

	CHARACTER*1 INPFIL(64)

	COMMON IFLAG1,IFLAG2,IFLAG3,KNT,ISZ

	COMMON/FLDES/NG,NA,NC,ND,NF,NP,NR,IS,IBUF(IOMAX)

	COMMON/FLDESO/NGO,NAO,NCO,NDO,NFO,NPO,NRO,ISO,IBUFO(IOMAX)

	COMMON/DEV/ ITI,ILP,IGRAPH,IOX

	COMMON/STDFIL/INPFIL

	INTEGER*4, SAVE :: IKNT,NTBL,NOBS

      INTEGER*4, SAVE :: IGL(20),ITAB(10,2),ISTRT(10),ITLABS(6,20)

      DIMENSION IGRP(20),IRTOT(10),ICTOT(10),LBLS(6,20),IV(2),IL(2)

	EQUIVALENCE (IBUF(1),LBLS(1,1)),(IV(1),IV1),(IV(2),IV2),

     1  (IL(1),IL1),(IL(2),IL2),(IR,IL1),(IC,IL2)
      COMMON /CPN/ CURPROCNAME
      CHARACTER*10 CURPROCNAME
      CHARACTER*1024 OUTNAME
      CHARACTER*1024 OUTFNM

	IF(IFLAG1)10,30,50

10    IFLAG3=0
      CURPROCNAME='XTAB'
      WRITE(*,*) CURPROCNAME
      OUTNAME=OUTFNM(CURPROCNAME)
	OPEN(UNIT=IOX,FILE=OUTNAME,ACTION='WRITE',STATUS='REPLACE')

	WRITE(IOX,299)(INPFIL(I),I=1,64),(IBUFO(I),I=1,108)

299   FORMAT('CROSSTABS FROM: ',64A1//(1X,18A4))

      CALL DoXTABDialog(IGL,ITAB,NTBL)

!	WRITE(*,200)(J,(LBLS(I,J),I=1,6),J=2,NG)
!
!200   FORMAT(' GROUP VAR ',I2,' ID=',6A4)
!
!	WRITE(*,201)
!
!201   FORMAT('$NUMBER OF 2-WAY TABLES TO BE FORMED? >'\)
!
!	READ(*,*)NTBL

	DO 5 I=1,NG

	DO 3 J=1,6

3     ITLABS(J,I)=LBLS(J,I)

5     IGRP(I)=0

	DO 8 K=1,NTBL

!	WRITE(*,202)K
!
!202   FORMAT(' SPECS FOR TABLE #',I2/'$ ENTER ROW VAR, COL VAR >'\)
!
!	READ(*,*)(ITAB(K,L),L=1,2)

	DO 8 L=1,2

8     IGRP(ITAB(K,L))=1

	DO 15 I=1,NG

	IF(IGRP(I))15,15,12

12    CONTINUE
!      WRITE(*,203)I
!
!203   FORMAT('$NUMBER OF LEVELS IN GROUP VAR ',I2,'? >'\)
!
!	READ(*,*)IGL(I)

15    CONTINUE

C GET START POSITIONS FOR TABLES IN IBUFO

	NSO=NGO + NAO

	ISTRT(1)=NSO

	NTBL1=NTBL+1

	DO 20 K=1,NTBL

20    ISTRT(K+1)=ISTRT(K)+IGL(ITAB(K,1)-1)*IGL(ITAB(K,2)-1)

	IKNT=0

	NOBS=0

	ISZ=ISTRT(NTBL1)-NSO

C CLEAR IBUFO REGION FOR TABLES

	IK=NSO

	DO 25 J=1,ISZ

	IK=IK+1

25    IBUFO(IK)=0

	RETURN

C PROCESSING SEGMENT

30    IF(IKNT-KNT)31,40,40

31    IKNT=KNT

	DO 38 K=1,NTBL

C CHECK INPUT GROUP VAR VALUES FOR EACH TABLE

	DO 35 I=1,2

	IV(I)=IBUF(ITAB(K,I))

	IL(I)=IGL(ITAB(K,I)-1)

	IF(IV(I))32,32,33

32    WRITE(*,300)KNT,(IBUF(J),J=2,NG)

300   FORMAT(' OUT-OF-SPEC VALUES IN RECORD-SET ',I5/

     1  ' GROUP-VARS=',15I4/' ANALYSIS ABORTED')

	KNT=-1

	GO TO 40

C FANCIER ABORT SHOULD HANDLE TABLES INDEPENDENTLY

33    IF(IV(I)-IL(I))35,35,32

35    CONTINUE

C ENTER NEW OBS IN ITS TABLE

	IK=ISTRT(K)+(IV1-1)*IL2+IV2

38    IBUFO(IK)=IBUFO(IK)+1

	NOBS=NOBS+1

40    RETURN

C IN POST=PROCESSING PHASE, COMPUTE STATS & WRITE TABLES

50    DO 75 K=1,NTBL

	WRITE(IOX,500)

500   FORMAT(//' CROSS-TABULATION RESULTS:')

	WRITE(IOX,501)K,(ITAB(K,I),I=1,2)

501   FORMAT(//5X,'TABLE #',I2,' USES (ROW) VAR ',I2,

     1  ' VERSUS (COLUMN) VAR ',I2)

	DO 55 I=1,2

	IL(I)=IGL(ITAB(K,I)-1)

	IV(I)=ITAB(K,I)

55    WRITE(IOX,502)IV(I),(ITLABS(J,IV(I)),J=1,6)

502   FORMAT(/5X,'VAR ',I2,' ID=',6A4)

C GET ROW & COLUMN TOTALS FOR THIS TABLE

	DO 56 J=1,IC

56    ICTOT(J)=0

	IK=ISTRT(K)

	DO 58 I=1,IR

	IRTOT(I)=0

	DO 58 J=1,IC

	IK=IK+1

	IRTOT(I)=IRTOT(I)+IBUFO(IK)

58    ICTOT(J)=ICTOT(J)+IBUFO(IK)

C NOW WRITE SUCCESSIVE ROWS AND ACCUMULATE STATS

	AN=NOBS

	CHISQ=0.0

	ICORR=0

	IF(IR*IC .EQ. 4)ICORR=1

	IK=ISTRT(K)

	IK1=IK

	IK2=IK

	WRITE(IOX,503)(J,J=1,IC)
	WRITE(*,503)(J,J=1,IC)

503   FORMAT(/15X,11I5)

	DO 65 I=1,IR

	IK1=IK2+1

	IK2=IK2+IC

	DO 60 J=1,IC

	IK=IK+1

	EXP=FLOAT(IRTOT(I))*FLOAT(ICTOT(J))/AN

	DEV=IBUFO(IK)-EXP

	IF(ICORR)60,60,59

59    DEV=DEV-SIGN(.5,DEV)

60    CHISQ=CHISQ+DEV*DEV/EXP

65    WRITE(IOX,504)I,(IBUFO(II),II=IK1,IK2),IRTOT(I)
      WRITE(*,504)I,(IBUFO(II),II=IK1,IK2),IRTOT(I)

504   FORMAT(10X,12I5)

	WRITE(IOX,503)(ICTOT(J),J=1,IC),NOBS

	IDF=(IR-1)*(IC-1)

	WRITE(IOX,505)CHISQ,IDF

505   FORMAT(/' CHISQUARE=',F8.2,' WITH ',I3,' DF')

75    CONTINUE

	WRITE(IOX,600)

600   FORMAT(//' END OF OUTPUT')

	CLOSE(UNIT=IOX)

	RETURN

	END



