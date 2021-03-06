!      SUBROUTINE SAVEASFILMAN(IUNIT,IRECL,IRECN)
!	CHARACTER*24 CLABEL(MCHANS)
!	CHARACTER*64 INPFIL
!	DIMENSION ICLABS(6,MCHANS),MLABS(6,6),MLABS1(36),HDR(15)
!	COMMON IFLAG1,IFLAG2,IFLAG3,KNT,ISZ,ICHAN(MCHANS)
!	COMMON/COHPAR/WHICH,RMINF,RMXF      ! LAST 2 DOUBLE PRECISION
!	COMMON/DEV/ITI
!	COMMON/STDFIL/INPFIL
!	COMMON/FLDES/ NG,NA,NC,ND,NF,NL,NR,IS,IBUF(108)
!	COMMON/FLDESO/ NGO,NAO,NCO,NDO,NFO,NLO,NRO,ISO,IBUFO(1)
!	EQUIVALENCE (ICLABS,CLABEL),(X,IX),(WHICH,HDR),(MLABS,MLABS1)
!	EQUIVALENCE (gvlabs,IGVLABS)
!	integer*4 GVLABS
!	parameter (IMGW=5,FUNPOS=2)
!	DIMENSION GVLABS(6,IMGW),IGVLABS(6*IMGW)
!	DATA IGVLABS/'DEST','INAT','ION ','CHAN','NEL ','    ',
!     2             'FUNC','TION',' TYP','E OU','T OF','    ',
!     3             'MODE','L  O','RDER','    ','    ','    ',
!     4             'FREQ','UENC','Y RA','NGE ','STAR','T   ',
!     5             'FREQ','UENC','Y RA','NGE ','END ','    '/
!	INTEGER*4 IGVNAME(6)
!	character*24 GVNAME
!	character*20 FUNCNM
!	EQUIVALENCE (IGVNAME,GVNAME),(FUNCNM,GVLABS(1,FUNPOS))!FUNCTION TYPE' for searching
!      CHARACTER*4 CKN
!      equivalence (CKN,GVLABS(6,FUNPOS)) ! 'FUNCTION TYPE' will contain number
!      REAL*4 ARMINF,ARMXF
!      INTEGER*4 IRMINF,IRMXF
!      EQUIVALENCE (ARMINF,IRMINF),(ARMXF,IRMXF)
!      INTEGER*4 IMUID(5),IINPNM(16)
!	DATA IMUID/'MULT','AR O','UTPU','T FO','R   '/
!	EQUIVALENCE (IINPNM,INPFIL)
!	save ITRLN,ITRMX
!	CHARACTER*7 CCN
!	COMMON /MULTRD/ ITURN,NTRNS
!      
!      
!      
      SUBROUTINE WRITWYN(IBUFO,IMGW,
     $                   IORD,IRMINF,IRMXF,IDS,ITWN,NGO,SLEV,
     $                   WYN,NPTS,NCHANS,KN,NLS,NLE,IFADD,
     $                   WRITFUN,NLX)
      INCLUDE 'MAX.INC'
      REAL WYN(NPTS,NCHANS,NCHANS,KN)
      REAL X
      INTEGER*4 IX
      EQUIVALENCE (X,IX)
      DIMENSION IBUFO(IOMAX)
      INTEGER*4 IBUFO
      EXTERNAL WRITFUN
      COMMON /BUFSIZ/ IO
	COMMON/FLDES/ NG,NA,NC,ND,NF,NL,NR,IS,IBUF(108)
	common /vss/ usevss   ! for rescaling spectral matrix
	LOGICAL USEVSS
    
      DO 80,IFUN=1,KN
      DO 80,IDCH=1,NCHANS
      DO 80,ISCH=1,NCHANS
      IBUFO(1)=ISCH           ! Source channel
      DO 90,IOGV=2,NG
90    IBUFO(IOGV)=IBUF(IOGV)  ! Old group variables
      IBUFO(NG+1)=IDCH        ! Destination channel
      IBUFO(NG+2)=IFUN+IFADD  ! Function number
      IBUFO(NG+3)=IORD        ! Model order
      IF(usevss)IBUFO(NG+3)=IBUFO(NG+3)+100
      IBUFO(NG+4)=IRMINF      ! Frequency band start
      IBUFO(NG+5)=IRMXF       ! Frequency band end
      IBUFO(NG+6)=ITWN        ! Trial/window number
      IF(IMGW.GT.6)THEN
        X=SLEV
        IBUFO(NG+7)=IX        ! Significance level
      ENDIF
C      IO=IDS
      IO=NG+IMGW+1
      DO 81,IFPT=NLS,NLE
	X=WYN(IFPT,ISCH,IDCH,IFUN)
	IBUFO(IO)=IX
81    IO=IO+1
      NLX=IO-1
80    CALL WRITFUN(IBUFO)
      RETURN
      END
      
      SUBROUTINE ZBWRIT(IBUF)
	INTEGER*4 IBUF(*)
	COMMON /CZBWRIT/ IUNIT,IREC
      COMMON /BUFSIZ/ IO

	DO 1,I=1,IO-1
	WRITE(IUNIT,REC=IREC)IBUF(I)
1     IREC=IREC+1      
	END
      
      SUBROUTINE INITZB(INPFIL,IBUFO1,IBUFO2,ILEN)
      CHARACTER*(*) INPFIL
      INTEGER*4 IBUFO1(*),IBUFO2(*)
	COMMON /CZBWRIT/ IUNIT,IREC
      COMMON /BUFSIZ/ IO
      CHARACTER*1024 FNAME

      IUNIT=201
      FNAME='C:\EEGDATA\'//INPFIL(1:LEN_TRIM(INPFIL))//'.ZERLEV.DAT'
      OPEN(UNIT=IUNIT,STATUS='REPLACE',FORM='UNFORMATTED',
     $     ACCESS='DIRECT',RECL=1,ERR=10,IOSTAT=iostat,
     $     FILE=FNAME)
      IREC=1
      IO=8+1
      CALL ZBWRIT(IBUFO1)
      IO=ILEN+1
      CALL ZBWRIT(IBUFO2)
      RETURN
10    IERRCN=iostat
      WRITE(*,*)'File ',FNAME(1:LEN_TRIM(FNAME)),' open error ',IERRCN
      RETURN
	END
 
      SUBROUTINE CLSEZB
	COMMON /CZBWRIT/ IUNIT,IREC
      CLOSE(UNIT=IUNIT)
      RETURN
      END      
      
      
      SUBROUTINE SWRITWYN(IBUFO,IMGW,
     $                   IORD,IRMINF,IRMXF,IDS,
     $                   ITWN,IFUN,NGO,V9,
     $                   SWYN,NPTS,NCHANS,INKN,IWNMAX,
     $                   NLS,NLE,
     $                   WRITFUN,NLX)
      INCLUDE 'MAX.INC'
      REAL SWYN(NPTS,NCHANS,NCHANS,IWNMAX,*)
      REAL X
      INTEGER*4 IX
      EQUIVALENCE (X,IX)
      DIMENSION IBUFO(IOMAX)
      INTEGER*4 IBUFO
      EXTERNAL WRITFUN
      COMMON /BUFSIZ/ IO
	COMMON/FLDES/ NG,NA,NC,ND,NF,NL,NR,IS,IBUF(108)
	common /vss/ usevss   ! for rescaling spectral matrix
	LOGICAL USEVSS
    
      DO 80,IKHN=1,INKN
      DO 80,IDCH=1,NCHANS
      DO 80,ISCH=1,NCHANS
      IBUFO(1)=ISCH
      DO 90,IOGV=2,NG
90    IBUFO(IOGV)=IBUF(IOGV)  ! Old group variables
C      IBUFO(NG+1)=IV2
      IBUFO(NG+1)=IDCH
      IBUFO(NG+2)=IFUN+(IKHN-1)+100  ! FLAG THAT WE HAVE "S"-DTF HERE
      IBUFO(NG+3)=IORD
      IF(usevss)IBUFO(NG+3)=IBUFO(NG+3)+100
      IBUFO(NG+4)=IRMINF
      IBUFO(NG+5)=IRMXF
      IBUFO(NG+6)=ITWN
      IF(IMGW.GT.6)THEN
        X=V9
        IBUFO(NG+7)=IX
      ENDIF
C      IO=IDS
      IO=NG+IMGW+1
      DO 81,IWNN=1,IWNMAX
      DO 81,IFPT=NLS,NLE
C	X=SWYN(IFPT,ISCH,IDCH,ITWN,IKHN)
	X=SWYN(IFPT,ISCH,IDCH,IWNN,IKHN)
	IBUFO(IO)=IX
81    IO=IO+1
      NLX=IO-1
80    CALL WRITFUN(IBUFO)
      RETURN
      END
      
!      SUBROUTINE INITSD(IBUFO1,IBUFO2,ILEN)
      SUBROUTINE INITSD
!      INTEGER*4 IBUFO1(*),IBUFO2(*)
	COMMON /SDTWRIT/ IUNIT,IREC
      COMMON /BUFSIZ/ IO
      CHARACTER*1024 FNAME
	CHARACTER*64 INFIL,OUTFIL
	COMMON/STDFIL/INFIL,OUTFIL

      IUNIT=202
C      FNAME='C:\EEGDATA\'//OUTFIL(1:LEN_TRIM(OUTFIL))//'.BOOTST.DAT'
      FNAME='C:\EEGDATA\'//OUTFIL(1:LEN_TRIM(OUTFIL))
      OPEN(UNIT=IUNIT,STATUS='REPLACE',FORM='UNFORMATTED',
     $     ACCESS='DIRECT',RECL=1,ERR=10,IOSTAT=iostat,
     $     FILE=FNAME)
      IREC=1
!      IO=8+1
!      CALL SDWRIT(IBUFO1)
!      IO=ILEN+1
!      CALL SDWRIT(IBUFO2)
      RETURN
10    IERRCN=iostat
      WRITE(*,*)'File ',FNAME(1:LEN_TRIM(FNAME)),' open error ',IERRCN
      RETURN
	END

      SUBROUTINE SDWRIT(IBUF)
	INTEGER*4 IBUF(*)
	COMMON /SDTWRIT/ IUNIT,IREC
      COMMON /BUFSIZ/ IO

	DO 1,I=1,IO-1
	WRITE(IUNIT,REC=IREC)IBUF(I)
1     IREC=IREC+1      
	END
      
      SUBROUTINE SDWRITL(IBUF,ILEN)
	INTEGER*4 IBUF(*)
	COMMON /SDTWRIT/ IUNIT,IREC
	DO 1,I=1,ILEN
	WRITE(IUNIT,REC=IREC)IBUF(I)
1     IREC=IREC+1      
	END


      SUBROUTINE CLSESD
	COMMON /SDTWRIT/ IUNIT,IREC
      CLOSE(UNIT=IUNIT)
      RETURN
      END      

      SUBROUTINE INITAV(INPFIL,IBUFO1,IBUFO2,ILEN)
      CHARACTER*(*) INPFIL
      INTEGER*4 IBUFO1(*),IBUFO2(*)
	COMMON /CAVWRIT/ IUNIT,IREC
      COMMON /BUFSIZ/ IO
      CHARACTER*1024 FNAME
      IUNIT=209
      FNAME='C:\EEGDATA\'//INPFIL(1:LEN_TRIM(INPFIL))//'.AVGDTF.DAT'
      OPEN(UNIT=IUNIT,STATUS='REPLACE',FORM='UNFORMATTED',
     $     ACCESS='DIRECT',RECL=1,ERR=10,IOSTAT=iostat,
     $     FILE=FNAME)
      IREC=1
      IO=8+1
      CALL AVWRIT(IBUFO1)
      IO=ILEN+1
      CALL AVWRIT(IBUFO2)
      RETURN
10    IERRCN=iostat
      WRITE(*,*)'File ',FNAME(1:LEN_TRIM(FNAME)),' open error ',IERRCN
      RETURN
	END
      
      SUBROUTINE CLSEAV
	COMMON /CAVWRIT/ IUNIT,IREC
      CLOSE(UNIT=IUNIT)
      RETURN
      END      
      
      SUBROUTINE AVWRIT(IBUF)
	INTEGER*4 IBUF(*)
	COMMON /CAVWRIT/ IUNIT,IREC
      COMMON /BUFSIZ/ IO
	DO 1,I=1,IO-1
	WRITE(IUNIT,REC=IREC)IBUF(I)
1     IREC=IREC+1      
	END
      
      SUBROUTINE AVWRITL(IBUF,ILEN)
	INTEGER*4 IBUF(*)
	COMMON /CAVWRIT/ IUNIT,IREC
	DO 1,I=1,ILEN
	WRITE(IUNIT,REC=IREC)IBUF(I)
1     IREC=IREC+1      
	END
      