!DEC$ FREEFORM 
! STDIO.FOR- STANDARD I/O FOR FILMAN, SPECTR & MANOVA; 
! PC POWERSTATION FORTRAN VERSION
SUBROUTINE GETOPN
	INCLUDE 'MAX.INC'
	CHARACTER*64 INFIL,INBUF,OUTFIL
	COMMON/STDFIL/INFIL,OUTFIL
	COMMON/CNTR1/ COUNT,CNTFLG,DUMMY,JREC
	INTEGER*4 COUNT,DUMMY(IPREC),CNTFLG
	logical lastin,lastout
	COMMON /MULTRD/ ITURN,NTRNS,NEWFIL,ISVNOW,ISVREC,ISVPOS
	COMMON /FULLFNM/ FULLINFIL,FULLOUTFIL
	CHARACTER*1024 FULLINFIL,FULLOUTFIL

10	call DoBrowseInputFileDialog(INBUF,lastin,lastout)
	if(lastout)infil=outfil
	if(.not.lastin)infil=INBUF
15	OPEN(UNIT=21,FILE=FULLINFIL,STATUS='OLD',ERR=20, &
	    ACCESS='DIRECT',RECL=IPREC,BLOCKSIZE=IPREC*4)
	NEWFIL=1     
	GO TO 50
20	WRITE(*,901)
901	FORMAT(' ERROR: UNABLE TO OPEN FILE; TRY AGAIN')
	GO TO 10
50	COUNT=0
	RETURN
END

! ***********************************************************

SUBROUTINE GETSTD(BUF)
	INCLUDE 'MAX.INC'
	COMMON/CNTR1/ COUNT,CNTFLG,DUMMY,JREC
	INTEGER*4 BUF(1),COUNT,CNTFLG,DUMMY(IPREC)
    INTEGER*4, SAVE :: NW, NL

	IF(COUNT-1)1,2,3

! read 1st header 

1	COUNT=COUNT+1
	JREC=1
	READ(21,REC=JREC)DUMMY
	DO 10 J1=1,116
10	    BUF(J1)=DUMMY(J1)
	NG=BUF(1)
	NC=BUF(3)
	NW=6*(NG+NC) !Total length of GV and Channel labels
	NL=BUF(6) !Total length of each normal record
	CNTFLG=117
	return

! read 2nd header, NW 32 bit words of labels

2	COUNT=COUNT+1
	CALL FILBUF(BUF,NW)
	return

! read DATA RECORD OF NL 32 bit words

3	CALL FILBUF(BUF,NL) !Read normal record
	return
end

! *************************************************

SUBROUTINE FILBUF(BUF,NW)
	INCLUDE 'MAX.INC'
	COMMON/CNTR1/ COUNT,CNTFLG,DUMMY,JREC
	INTEGER*4 COUNT,DUMMY(IPREC),CNTFLG,BUF(1) !IPREC = 1024 in MAX.INC
	COMMON /MULTRD/ ITURN,NTRNS,NEWFIL,ISVNOW,ISVREC,ISVPOS
	
	if(isvnow)then  ! saved position of the first data record
	ISVREC=JREC
	ISVPOS=CNTFLG
	ISVNOW=0
	endif	  

	DO 100 J1=1,NW
	    BUF(J1)=DUMMY(CNTFLG)
	    CNTFLG=CNTFLG+1
	    IF (CNTFLG.LE.IPREC) GOTO 100
	    CNTFLG=1
	    JREC=JREC+1
	    READ(21,REC=JREC) DUMMY
100	CONTINUE
200	RETURN
END

! **********************************************

SUBROUTINE GETEND
	INCLUDE 'MAX.INC'
	COMMON/CNTR1/ COUNT
	INTEGER*4 COUNT,DUMMY(IPREC),CNTFLG,BUF(1)

	COUNT=0
	CLOSE(UNIT=21)
	RETURN
	END

! SUBROUTINE TO SUPPORT DIRECT ACCESS TO RECSET N      

	SUBROUTINE GETREC(N)
	INCLUDE 'MAX.INC'
	INTEGER*4 COUNT,CNTFLG,DUMMY(IPREC),JREC
	INTEGER*8 FIRSTWRD,NN
	COMMON/CNTR1/COUNT,CNTFLG,DUMMY,JREC
	COMMON/FLDES/NG,NA,NC,ND,NF,NP,NR,IS,IBUF(IOMAX)
	
	NN = N-1
	FIRSTWRD=NN*NP*NC+6*(NG+NC)+117  !FIRST WORD OF NTH RECORDSET
	JREC0=FIRSTWRD/IPREC
	CNTFLG=FIRSTWRD-JREC0*IPREC    !OFFSET FOR NEXT GETSTD()
	JREC=JREC0+1                  !INDEX TO THE RECORD
	READ(21,REC=JREC)DUMMY        !READ THAT RECORD INTO BUFFER
	RETURN
END

! *******************************************

SUBROUTINE PUTSTD(BUFO)
	INCLUDE 'MAX.INC'
	COMMON/FLDESO/IDO(8)
	COMMON/CNTR2/COUNT,CNTFLG,DUMMY,JREC      
	INTEGER*4 COUNT,CNTFLG,DUMMY(IPREC),BUFO(1)
	INTEGER*4, SAVE :: NW, NL

	IF(COUNT-1)1,2,3

! write 1st header

1	COUNT=COUNT+1
	JREC=1
	DO 10 J1=1,116
10	    DUMMY(J1)=BUFO(J1)
	NG=BUFO(1)
	NC=BUFO(3)
	NW=6*(NG+NC)
	NL=BUFO(6)
	CNTFLG=117
	RETURN

! write 2nd header

2	COUNT=COUNT+1
	CALL STOBUF(BUFO,NW)
	RETURN

! store NL words

3	CALL STOBUF(BUFO,NL)

! update count of data records written

	IDO(7)=IDO(7)+1
	return
end

! ********************************************

SUBROUTINE STOBUF(BUFO,NW)
	INCLUDE 'MAX.INC'
	COMMON/CNTR2/COUNT,CNTFLG,DUMMY,JREC 
	INTEGER*4 COUNT,DUMMY(IPREC),CNTFLG,BUFO(1)

	DO 100 J1=1,NW
	    DUMMY(CNTFLG)=BUFO(J1)
	    CNTFLG=CNTFLG+1
	    IF (CNTFLG.LE.IPREC)GOTO 100   
	    CNTFLG=1
	    WRITE(22,rec=JREC,ERR=5,IOSTAT=IOCHECK)DUMMY
	    JREC=JREC+1
100	CONTINUE
	RETURN
5	WRITE(*,501)COUNT,CNTFLG,JREC,IOCHECK
501	FORMAT('COUNT,CNTFLG,JREC,IOCHECK=',4I6)
	STOP ' STOBUF ERROR'
END

! **********************************************

SUBROUTINE PUTEND
	INCLUDE 'MAX.INC'
	COMMON/FLDESO/IDO(8)
	COMMON/CNTR2/COUNT,CNTFLG,DUMMY,JREC
	INTEGER*4 COUNT,DUMMY(IPREC),CNTFLG  
	COMMON/STDFIL2/ OOK,GIVEN
	LOGICAL OOK,GIVEN
    
    COUNT=0
	IF(GIVEN)THEN
	    GIVEN=.FALSE.
	    RETURN
	ENDIF

! store last block of data if neccessary

	IF (CNTFLG.EQ.1)GO TO 1
	DO 100 I=CNTFLG,IPREC
100	    DUMMY(I)=0  !Zero out remainder of record
	WRITE(22,REC=JREC)DUMMY

! store total # data records in NRO field of header 1

1	READ(22,REC=1)DUMMY
	DUMMY(7)=IDO(7)
	WRITE(22,REC=1)DUMMY
2	CLOSE(UNIT=22)
	RETURN
END

! **********************************************

SUBROUTINE PUTOPN
	INCLUDE 'MAX.INC'
	CHARACTER*64 INFIL,OUTFIL
	CHARACTER*1 ARESP
	COMMON/STDFIL/INFIL,OUTFIL
	COMMON/STDFIL2/ OOK,GIVEN
	LOGICAL OOK,GIVEN
	COMMON/CNTR2/COUNT,CNTFLG,DUMMY,JREC
	INTEGER*4 COUNT,DUMMY(IPREC),CNTFLG  
	COMMON /FULLFNM/ FULLINFIL,FULLOUTFIL
	CHARACTER*1024 FULLINFIL,FULLOUTFIL

	COUNT=0
	IF(OOK) GOTO 3
	IF(GIVEN) RETURN
	CALL SelectOutputFile
3	OPEN (UNIT=22,FILE=FULLOUTFIL,BLOCKSIZE=IPREC*4, &
	        ACCESS='DIRECT',RECL=IPREC)
	JREC=1
	RETURN
END

! NEW SUBROUTINES TO TRANSLATE BETWEEN 2-BYTE & 4-BYTE INTEGER FORMS
! NB: PACK ASSUMES THE DATA TO LIE IN [-32768, +32767]; SEE TEST.FOR

SUBROUTINE PACK(I1,I2,IX)
    INTEGER*2 J(2),J1,J2
    INTEGER*4 I1,I2,I3,IX
    EQUIVALENCE (J,I3),(J(1),J1),(J(2),J2)

    J1=INT2(I1)
    J2=INT2(I2)
    IX=I3
    RETURN
END
	
!------------------------------------------------------------------------

SUBROUTINE UNPACK(IX,I1,I2)
    INTEGER*2 J(2),J1,J2
    INTEGER*4 I1,I2,I3,IX
    EQUIVALENCE (J,I3),(J(1),J1),(J(2),J2)

    I3=IX
    I1=INT4(J1)
    I2=INT4(J2)
    RETURN
END

!------------------------------------------------------------------------

SUBROUTINE REWFILE
    INCLUDE 'MAX.INC'
    COMMON/CNTR1/ COUNT,CNTFLG,DUMMY,JREC
    INTEGER*4 COUNT,DUMMY(IPREC),CNTFLG,BUF(1)
    COMMON /MULTRD/ ITURN,NTRNS,NEWFIL,ISVNOW,ISVREC,ISVPOS
	
        CNTFLG=ISVPOS
        JREC=ISVREC
    READ(21,REC=JREC)DUMMY
END
