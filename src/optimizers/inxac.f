C  THIS VERSION: 14/08/1991 AT 12:00:11 PM.
C
C  ** FOR THE CRAY 2, LINES STARTING CDIR$ IVDEP TELL THE COMPILER TO
C     IGNORE POTENTIAL VECTOR DEPENDENCIES AS THEY ARE KNOWN TO BE O.K.
C
CS    SUBROUTINE SINXAC( N, X0, XT, G, BND, INDEX, F, EPSTOL, TMAX, RMU,
CD    SUBROUTINE DINXAC( N, X0, XT, G, BND, INDEX, F, EPSTOL, TMAX, RMU,
     *                   BOUNDX, PXSQR, QXT, P, Q, IVAR, NFREE,
     *                   NVAR1, NVAR2, NNONNZ, INONNZ, BREAKP, GRAD,
     *                   IOUT, JUMPTO, IDEBUG )
C
C  ********************************************************************
C
C  THIS SUBROUTINE CALCULATES A SUITABLE CAUCHY POINT. A CAUCHY POINT IS
C  AN APPROXIMATION TO THE MINIMIZER OF THE QUADRATIC FUNCTION QUAD( X )
C
C    0.5 (X - X0) (TRANSPOSE) B (X - X0) + G (TRANSPOSE) (X - X0) + F
C
C  FOR POINTS LYING ON THE 'CAUCHY ARC' X(T). THE CAUCHY ARC X(T) IS
C  THE PROJECTION OF THE LINE X0 + T*P (0 <= T <= TMAX) INTO THE
C  BOX REGION BND(*,1) <= X(*) <= BND(*,2). A SUITABLE CAUCHY POINT IS
C  DETERMINED AS FOLLOWS:
C
C  1) IF THE MINIMIZER OF QUAD( X ) ALONG X0 + T*P LIES ON THE CAUCHY
C     ARC, THIS IS THE REQUIRED POINT. OTHERWISE,
C
C  2) STARTING FROM SOME SPECIFIED T0, CONSTRUCT A DECREASING SEQUENCE
C     OF VALUES T1, T2, T3, .... . GIVEN 0 < MU < 1, PICK THE FIRST
C     TI (I = 0, 1, ...) FOR WHICH THE ARMIJO CONDITION
C
C        QUAD( X(TI) ) <= LINEAR( X(TI), MU ) =
C                         F + MU * G (TRANSPOSE) ( X(TI) - X0 )
C
C     IS SATISFIED. X0 + TI*P IS THEN THE REQUIRED POINT.
C
C  PROGRESS THROUGH THE ROUTINE IS CONTROLLED BY THE PARAMETER
C  JUMPTO.
C
C  IF JUMPTO = 0, THE GENERALIZED CAUCHY POINT HAS BEEN FOUND.
C  IF JUMPTO = 1, AN INITIAL ENTRY HAS BEEN MADE.
C  IF JUMPTO = 2, 3, 4 THE VECTOR Q = B * P IS REQUIRED.
C
C  THE STATUS OF THE ARRAY INDEX GIVES THE STATUS OF THE VARIABLES.
C
C  IF INDEX( I ) = 0, THE I-TH VARIABLE IS FREE.
C  IF INDEX( I ) = 1, THE I-TH VARIABLE IS ON ITS LOWER BOUND.
C  IF INDEX( I ) = 2, THE I-TH VARIABLE IS ON ITS UPPER BOUND.
C  IF INDEX( I ) = 3, THE I-TH VARIABLE IS FIXED.
C  IF INDEX( I ) = 4, THE I-TH VARIABLE IS TEMPORARILY FIXED.
C
C  THE ADDRESSES OF THE FREE VARIABLES ARE GIVEN IN THE FIRST
C  NVAR2 ENTRIES OF THE ARRAY IVAR.
C  IF THE PRODUCT OF B * P IS REQUIRED (JUMPTO = 2, 3), THE
C  NONZERO COMPONENTS OF P OCCUR IN POSITIONS IVAR(I) FOR
C  I LYING BETWEEN NVAR1 AND NVAR2.
C
C  AT THE INITIAL POINT, VARIABLES WITHIN EPSTOL OF THEIR BOUNDS AND
C  FOR WHICH THE SEARCH DIRECTION POINTS OUT OF THE BOX WILL BE FIXED.
C
C  NICK GOULD, 29TH OF JANUARY 1990.
C  FOR CGT PRODUCTIONS.
C
C  --------------------------------------------------------------------
C
C  VERSIONS AVAILABLE :
C  --------------------
C
C  THERE IS A SINGLE AND A DOUBLE PRECISION VERSION. TO USE THE
C  SINGLE PRECISION VERSION, REPLACE THE CHARACTERS 'CS' WITH '  ' IN
C  THE FIRST TWO COLUMNS OF ALL LINES. TO USE THE DOUBLE PRECISION
C  VERSION, REPLACE THE CHARACTERS 'CD' WITH '  ' IN THE FIRST TWO
C  COLUMNS OF EVERY LINE.
C
C  PARAMETERS : (REAL MEANS DOUBLE PRECISION IN THE DOUBLE VERSION)
C  ------------
C
C  N      (INTEGER) THE NUMBER OF INDEPENDENT VARIABLES.
C          ** THIS VARIABLE IS NOT ALTERED BY THE SUBROUTINE.
C  X0     (REAL ARRAY OF LENGTH AT LEAST N) THE POINT X0 FROM
C          WHICH THE 'CAUCHY ARC' COMMENCES.
C          ** THIS VARIABLE IS NOT ALTERED BY THE SUBROUTINE.
C  XT     (REAL ARRAY OF LENGTH AT LEAST N) THE CURRENT ESTIMATE
C          OF THE GENERALIZED CAUCHY POINT.
C  G      (REAL ARRAY OF LENGTH AT LEAST N) THE COEFFICIENTS OF
C          THE LINEAR TERM IN THE QUADRATIC FUNCTION.
C          ** THIS VARIABLE IS NOT ALTERED BY THE SUBROUTINE.
C  BND    (TWO DIMENSIONAL REAL ARRAY WITH LEADING DIMENSION N AND
C          SECOND DIMENSION 2) THE LOWER (BND(*,1)) AND
C          UPPER (BND(*,2)) BOUNDS ON THE VARIABLES.
C          ** THIS VARIABLE IS NOT ALTERED BY THE SUBROUTINE.
C  INDEX  (INTEGER ARRAY OF LENGTH AT LEAST N) GIVES THE STATUS OF
C          THE VARIABLES AT THE CURRENT ESTIMATE OF THE GENERALIZED
C          CAUCHY POINT AS FOLLOWS:
C          IF INDEX( I ) = 0, THE I-TH VARIABLE IS FREE.
C          IF INDEX( I ) = 1, THE I-TH VARIABLE IS ON ITS LOWER BOUND.
C          IF INDEX( I ) = 2, THE I-TH VARIABLE IS ON ITS UPPER BOUND.
C          IF INDEX( I ) = 3, THE I-TH VARIABLE IS FIXED.
C          IF INDEX( I ) = 4, THE I-TH VARIABLE IS TEMPORARILY FIXED.
C  F      (REAL) THE VALUE OF THE QUADRATIC AT X0, SEE ABOVE.
C          ** THIS VARIABLE IS NOT ALTERED BY THE SUBROUTINE.
C  EPSTOL (REAL) A TOLERANCE ON FEASIBILITY OF X0, SEE ABOVE.
C          ** THIS VARIABLE IS NOT ALTERED BY THE SUBROUTINE.
C  BOUNDX (LOGICAL) THE SEARCH FOR THE GENERALIZED CAUCHY POINT
C          WILL BE TERMINATED ON THE BOUNDARY OF THE SPHERICAL
C          REGION ||X-X0|| <= R IF AND ONLY IF BOUNDX IS SET TO
C          .TRUE. ON INITIAL (JUMPTO=1) ENTRY.
C          ** THIS VARIABLE IS NOT ALTERED BY THE SUBROUTINE.
C  PXSQR  (REAL) THE SQUARE OF THE TWO NORM OF THE DISTANCE BETWEEN
C          THE CURRENT ESTIMATE OF THE GENERALIZED CAUCHY POINT AND
C          X0. PXSQR WILL ONLY BE SET IF BOUNDX IS .TRUE.
C  QXT    (REAL) THE VALUE OF THE PIECEWISE QUADRATIC FUNCTION
C          AT THE CURRENT ESTIMATE OF THE GENERALIZED CAUCHY POINT.
C  P      (REAL ARRAY OF LENGTH AT LEAST N) CONTAINS THE VALUES OF THE
C          COMPONENTS OF THE VECTOR P. ON INITIAL (JUMPTO=1) ENTRY,
C          P MUST CONTAIN THE INITIAL DIRECTION
C          OF THE 'CAUCHY ARC'. ON A NON OPTIMAL EXIT,
C          (JUMPTO=2,3), P IS THE VECTOR FOR WHICH THE PRODUCT B*P
C          IS REQUIRED BEFORE THE NEXT RE-ENTRY. ON A TERMINAL EXIT
C          (JUMPTO=0), P CONTAINS THE STEP XT - X0. THE COMPONENTS
C          IVAR(I) = NVAR1, ... , NVAR2 OF P CONTAIN THE VALUES OF THE
C          NONZERO COMPONENTS OF P (SEE, IVAR, NVAR1, NVAR2).
C  Q      (REAL ARRAY OF LENGTH AT LEAST N) ON A NON INITIAL ENTRY
C         (JUMPTO=2,3), Q MUST CONTAIN THE VECTOR B * P. ONLY THE
C          COMPONENTS IVAR(I), I=1,...,NFREE, OF Q NEED BE SET (THE
C          OTHER COMPONENTS ARE NOT USED).
C  IVAR   (INTEGER ARRAY OF LENGTH AT LEAST N) ON ALL NORMAL EXITS
C         (JUMPTO=0,2,3), IVAR(I), I=NVAR1,...,NVAR2, GIVES THE INDICES
C          OF THE NONZERO COMPONENTS OF P.
C  NFREE  (INTEGER) THE NUMBER OF FREE VARIABLES AT THE INITIAL POINT.
C  NVAR1  (INTEGER) SEE IVAR, ABOVE.
C  NVAR2  (INTEGER) SEE IVAR, ABOVE.
C  INONNZ (INTEGER ARRAY OF LENGTH AT LEAST NNONNZ) ON JUMPTO = 3
C         ENTRIES, INONN(I), I = 1,....,NNONNZ, MUST GIVE THE
C         INDICES OF THE NONZERO COMPONENTS OF Q. ON OTHER ENTRIES,
C         INNONNZ NEED NOT BE SET.
C  NNONNZ (INTEGER) THE NUMBER OF NONZERO COMPONENTS OF Q ON A
C         JUMPTO=3 ENTRY. NNONNZ NEED NOT BE SET ON OTHER ENTRIES.
C  BREAKP (REAL ARRAY OF LENGTH AT LEAST N) USED AS WORKSPACE.
C  GRAD   (REAL ARRAY OF LENGTH AT LEAST N) USED AS WORKSPACE.
C  TMAX   (REAL) THE LARGEST ALLOWABLE VALUE OF T.
C  RMU    (REAL) THE SLOPE OF THE MAJORIZING LINEAR MODEL L(X,MU).
C  IOUT   (INTEGER) THE FORTRAN OUTPUT CHANNEL NUMBER TO BE USED.
C  JUMPTO (INTEGER) CONTROLS FLOW THROUGH THE SUBROUTINE.
C          IF JUMPTO = 0, THE GENERALIZED CAUCHY POINT HAS BEEN FOUND.
C          IF JUMPTO = 1, AN INITIAL ENTRY HAS BEEN MADE.
C          IF JUMPTO = 2, 3, 4, THE VECTOR Q = B * P IS REQUIRED.
C  IDEBUG (INTEGER) ALLOWS DETAILED PRINTING. IF IDEBUG IS LARGER
C          THAN 4, DETAILED OUTPUT FROM THE ROUTINE WILL BE GIVEN.
C          OTHERWISE, NO OUTPUT OCCURS.
C
C  COMMON BLOCKS.
C  --------------
C
C  THE COMMON BLOCK SCOMSB/DCOMSB IS USED TO PASS FURTHER INFORMATION.
C  THE BLOCK CONTAINS THE VARIABLES
C
C    ACCCG, RATIO, RADIUS, RADMAX, FINDMX, CMA31, ITERCG, ITCGMX, 
C    NGEVAL, ISKIP, IFIXED, NBANDW
C
C  IN THAT ORDER.  VARIABLES ITERCG, ITCGMX, NGEVAL, ISKIP, IFIXED AND
C  NBANDW ARE INTEGER AND ACCCG, RATIO, RADIUS, RADMAX, FINDMX
C  AND CMA31 ARE REAL. ONLY RADIUS AND FINDMX NEED BE SET AS FOLLOWS:
C
C  RADIUS (REAL) THE RADIUS, R, OF THE SPHERICAL REGION. RADIUS
C          NEED NOT BE SET IF BOUNDX IS .FALSE. ON INITIAL ENTRY.
C          ** THIS VARIABLE IS NOT ALTERED BY THE SUBROUTINE.
C
C  FINDMX (REAL) WHEN PRINTING THE VALUE OF THE OBJECTIVE FUNCTION,
C          THE VALUE CALCULATED IN FMODEL WILL BE MULTIPLIED BY THE
C          SCALE FACTOR FINDMX. THIS ALLOWS THE USER, FOR INSTANCE,
C          TO FIND THE MAXIMUM OF A QUADRATIC FUNCTION F, BY MINIMIZING
C          THE FUNCTION - F, WHILE MONITORING THE PROGRESS AS
C          IF A MAXIMIZATION WERE ACTUALLY TAKING PLACE, BY SETTING
C          FINDMX TO - 1.0. NORMALLY FINDMX SHOULD BE SET TO 1.0.
C
C  THE COMMON BLOCK SMACHN/DMACHN IS USED TO PASS MACHINE DEPENDENT 
C  CONSTANTS. THE BLOCK CONTAINS THE REAL VARIABLES
C
C  EPSMCH, EPSNEG, TINY, BIG
C
C  IN THAT ORDER. EPSMCH AND EPSNEG ARE, RESPECTIVELY, THE SMALLEST
C  POSITIVE NUMBERS SUCH THAT 1.0 + EPSMCH > 1.0 AND 1.0 - EPSNEG < 1.0.
C  TINY IS THE SMALLEST POSITIVE FULL-PRECISION NUMBER AND BIG IS THE
C  LARGEST REPRESENTABLE NUMBER. ** THESE VALUES MUST BE SET BY THE USER.
C                                   ------------------------------------      
C  INITIALIZATION.
C  ---------------
C
C  ON THE INITIAL CALL TO THE SUBROUTINE THE FOLLOWING VARIABLES MUST
C  BE SET BY THE USER: -
C
C      N, X0, G, D, BND, F, EPSTOL, TMAX, RMU, BOUNDX, IOUT,
C      JUMPTO, IDEBUG.
C
C  JUMPTO MUST HAVE THE VALUE 1.
C  IN ADDITION, IF THE I-TH VARIABLE IS REQUIRED TO BE FIXED AT
C  ITS INITIAL VALUE, X0(I), INDEX(I) MUST BE SET TO 3.
C  RADIUS MUST BE SPECIFIED IF BOUNDX IS .TRUE. ON INITIAL ENTRY.
C
C  RE-ENTRY.
C  ---------
C
C  IF THE VARIABLE JUMPTO HAS THE VALUE 2 OR 3 ON EXIT, THE
C  SUBROUTINE MUST BE RE-ENTERED WITH THE VECTOR Q CONTAINING
C  THE PRODUCT OF THE SECOND DERIVATIVE MATRIX B AND THE OUTPUT
C  VECTOR P. ALL OTHER PARAMETERS MUST NOT BE ALTERED.
C                                 -------------------
C
C  ****************************************************************
C
      INTEGER          JUMPTO, N, NFREE, NVAR1, NVAR2, NNONNZ
      INTEGER          IOUT, IDEBUG
CS    REAL             PXSQR, EPSTOL, F, QXT, TMAX, RMU
CD    DOUBLE PRECISION PXSQR, EPSTOL, F, QXT, TMAX, RMU
      LOGICAL          BOUNDX
      INTEGER          INDEX( N ), IVAR( N ), INONNZ( N )
CS    REAL             X0( N ), XT( N ), BND( N, 2 ), G( N ), P( N ),
CD    DOUBLE PRECISION X0( N ), XT( N ), BND( N, 2 ), G( N ), P( N ),
     *                 Q( N ), GRAD( N ), BREAKP( N )
C
C  LOCAL VARIABLES.
C
      INTEGER          I, ITERCA, ITMAX, J, NFREED, NZERO, NBREAK, N3
CS    REAL             BETA, HALF, ZERO, TBREAK, ALPHA, TAMAX, PTP,
CD    DOUBLE PRECISION BETA, HALF, ZERO, TBREAK, ALPHA, TAMAX, PTP,
     *                 GTP, PTBP, FLXT, TNEW, G0TP, T, TBMAX, TSPHER
      LOGICAL          PRNTER, PRONEL, XLOWER, XUPPER
      INTRINSIC        ABS, MIN, MAX
C
C  COMMON VARIABLES.
C
      INTEGER           ITERCG, ITCGMX, NGEVAL, ISKIP , IFIXED, NBANDW
CS    REAL              ACCCG , RATIO , RADIUS, RADMAX, FINDMX, CMA31
CD    DOUBLE PRECISION  ACCCG , RATIO , RADIUS, RADMAX, FINDMX, CMA31
CS    COMMON / SCOMSB / ACCCG , RATIO , RADIUS, RADMAX, FINDMX, CMA31,
CD    COMMON / DCOMSB / ACCCG , RATIO , RADIUS, RADMAX, FINDMX, CMA31,
     *                  ITERCG, ITCGMX, NGEVAL, ISKIP , IFIXED, NBANDW
CS    REAL              EPSMCH, EPSNEG, TINY, BIG
CD    DOUBLE PRECISION  EPSMCH, EPSNEG, TINY, BIG
CS    COMMON / SMACHN / EPSMCH, EPSNEG, TINY, BIG
CD    COMMON / DMACHN / EPSMCH, EPSNEG, TINY, BIG
      SAVE
C
C  SET CONSTANT REAL PARAMETERS.
C
CS    PARAMETER ( ZERO   = 0.0E+0, HALF   = 5.0E-1 )
CD    PARAMETER ( ZERO   = 0.0D+0, HALF   = 5.0D-1 )
C
C  BETA IS THE AMOUNT BY WHICH THE STEP IS REDUCED WHEN BACKTRACKING.
C  THE INITIAL STEP FOR BACKTRACKING IS ALPHA TIMES THE STEP TO THE
C  FIRST LINE MINIMUM.
C
CS    PARAMETER ( BETA   = 5.0E-1, ALPHA  = 1.0E+0 )
CD    PARAMETER ( BETA   = 5.0D-1, ALPHA  = 1.0D+0 )
      GO TO ( 10, 100, 200, 300 ), JUMPTO
C
C  ON INITIAL ENTRY, SET CONSTANTS.
C
   10 CONTINUE
      ITERCA = 0
      ITMAX  = 100
      NFREED = 0
      NBREAK = 0
      NZERO  = N + 1
      T      = ZERO
      IF ( BOUNDX ) PTP = ZERO
      PRNTER = IDEBUG .GE. 4 .AND. IOUT .GT. 0
      PRONEL = IDEBUG .EQ. 2 .AND. IOUT .GT. 0
C
C  FIND THE STATUS OF THE VARIABLES.
C
CDIR$ IVDEP
      DO 30 I = 1, N
C
C  CHECK TO SEE WHETHER THE VARIABLE IS FIXED.
C
         IF ( INDEX( I ) .LE. 2 ) THEN
            INDEX( I ) = 0
            XUPPER     = BND( I, 2 ) - X0( I ) .LE. EPSTOL
            XLOWER     = X0( I ) - BND( I, 1 ) .LE. EPSTOL
            IF ( .NOT. ( XUPPER .OR. XLOWER ) ) THEN
C
C  THE VARIABLE LIES BETWEEN ITS BOUNDS. CHECK TO SEE IF THE SEARCH
C  DIRECTION IS ZERO.
C
               IF ( ABS( P( I ) ) .GT. EPSMCH ) GO TO 20
               NZERO         = NZERO - 1
               IVAR( NZERO ) = I
            ELSE
               IF ( XLOWER ) THEN
C
C  THE VARIABLE LIES CLOSE TO ITS LOWER BOUND.
C
                  IF ( P( I ) .GT. EPSMCH ) THEN
                     NFREED = NFREED + 1
                     GO TO 20
                  END IF
                  INDEX( I ) = 1
               ELSE
C
C  THE VARIABLE LIES CLOSE TO ITS UPPER BOUND.
C
                  IF ( P( I ) .LT. - EPSMCH ) THEN
                     NFREED = NFREED + 1
                     GO TO 20
                  END IF
                  INDEX( I ) = 2
               END IF
            END IF
         END IF
C
C  SET THE SEARCH DIRECTION TO ZERO.
C
         P( I )  = ZERO
         XT( I ) = X0( I )
         GO TO 30
   20    CONTINUE
C
C  IF THE VARIABLE IS FREE, SET UP THE POINTERS TO THE NONZEROS IN
C  THE VECTOR P READY FOR CALCULATING Q = B * P. THE VECTOR XT IS
C  USED TEMPORARILY TO STORE THE ORIGINAL INPUT DIRECTION P.
C
         NBREAK            = NBREAK + 1
         IVAR( NBREAK )    = I
         XT( I )           = P( I )
         IF ( BOUNDX ) PTP = PTP + P( I ) * P( I )
   30 CONTINUE
C
C  IF ALL OF THE VARIABLES ARE FIXED, EXIT.
C
      IF ( PRNTER ) WRITE( IOUT, 2020 ) NFREED, N - NBREAK
      IF ( PRONEL .OR. PRNTER ) WRITE( IOUT, 2000 )
     *                             ITERCA, ZERO, F * FINDMX
      ITERCA = ITERCA + 1
      IF ( NBREAK .EQ. 0 ) GO TO 600
C
C  RETURN TO THE CALLING PROGRAM TO CALCULATE Q = B P.
C
      NVAR1  = 1
      NVAR2  = NBREAK
      NFREE  = NBREAK
      JUMPTO = 2
      RETURN
  100 CONTINUE
C
C  COMPUTE THE SLOPE AND CURVATURE OF THE QUAD( X ) IN THE DIRECTION P.
C
      GTP    = ZERO
      PTBP   = ZERO
      TBREAK = BIG
      TBMAX  = ZERO
CDIR$ IVDEP
      DO 110 J = 1, NFREE
         I     = IVAR( J )
         GTP   = GTP  + P( I ) * G( I )
         PTBP  = PTBP + P( I ) * Q( I )
C
C  FIND THE BREAKPOINTS FOR THE PIECEWISE LINEAR ARC (THE DISTANCES
C  TO THE BOUNDARY). 
C
         IF ( P( I ) .GT. ZERO ) THEN
            BREAKP( I ) = ( BND( I, 2 ) - X0( I ) ) / P( I )
         ELSE
            BREAKP( I ) = ( BND( I, 1 ) - X0( I ) ) / P( I )
         END IF
C
C  COMPUTE THE MAXIMUM FEASIBLE DISTANCE, TBREAK, ALLOWABLE IN
C  THE DIRECTION P. ALSO COMPUTE TBMAX, THE LARGEST BREAKPOINT.
C
         TBREAK = MIN( TBREAK, BREAKP( I ) )
         TBMAX  = MAX( TBMAX,  BREAKP( I ) )
  110 CONTINUE
C
C  --------------------------------------------------------------------
C  SPECIAL CASE: THE FIRST INTERVAL.
C  --------------------------------------------------------------------
C
C  IF REQUIRED, CALCULATE THE DISTANCE TO THE SPHERICAL TRUST-REGION.
C
      IF ( BOUNDX ) THEN
         TSPHER = RADIUS / SQRT( PTP )
      END IF
C
C  CHECK THAT THE CURVATURE IS POSITIVE.
C
      IF ( PTBP .GT. ZERO ) THEN
C
C  COMPUTE THE MINIMIZER, T, OF QUAD( X(T) ) IN THE DIRECTION P.
C
         T = - GTP / PTBP
C
C  IF THE SPHERICAL TRUST REGION CUTS OFF THIS POINT, PREPARE 
C  TO EXIT.
C
         IF ( BOUNDX ) T = MIN( T, TSPHER )
C
C  COMPARE THE VALUES OF T AND TBREAK.
C  IF THE CALCULATED MINIMIZER OR THE BOUNDARY OF THE SPHERICAL 
C  TRUST REGION IS THE CAUCHY POINT, EXIT.
C
         IF ( T .LE. TBREAK ) THEN
            GO TO 500
         ELSE
            IF ( PRONEL .OR. PRNTER ) WRITE( IOUT, 2040 ) ITERCA, T
C
C  ENSURE THAT THE INITIAL VALUE OF T FOR BACKTRACKING IS NO
C  LARGER THAN ALPHA TIMES THE STEP TO THE FIRST LINE MINIMUM.
C
            TAMAX = MIN( TMAX, ALPHA * T )
         END IF
      ELSE
C
C  IF THE BOUNDARY OF THE SPHERICAL TRUST REGION IS THE CAUCHY 
C  POINT, EXIT.
C
         IF ( BOUNDX ) THEN
            IF ( TSPHER .LE. TBREAK ) THEN
               T = TSPHER
               GO TO 500
            END IF
         END IF
      END IF
C
C  --------------------------------------------------------------------
C  THE REMAINING INTERVALS.
C  --------------------------------------------------------------------
C
C  THE CALCULATED MINIMIZER IS INFEASIBLE; PREPARE TO BACKTRACK FROM
C  T UNTIL A CAUCHY POINT IS FOUND.
C
      T = MIN( TAMAX, TBMAX )
C
C  CALCULATE P, THE DIFFERENCE BETWEEN THE PROJECTION OF THE POINT
C  X(T) AND X0 AND PTP, THE SQUARE OF THE NORM OF THIS DISTANCE.
C
  150 CONTINUE
      IF ( BOUNDX ) PTP = ZERO
CDIR$ IVDEP
      DO 160 J  = 1, NFREE
         I      = IVAR( J )
         P( I ) = MAX( MIN( X0( I ) + T * P( I ), BND( I, 2 ) ),
     *                 BND( I, 1 ) ) - X0( I )
         IF ( BOUNDX ) PTP = PTP + P( I ) * P( I )
  160 CONTINUE
C
C  IF REQUIRED, ENSURE THAT X(T) LIES WITHIN THE SPHERICAL TRUST REGION.
C  IF X(T) LIES OUTSIDE THE REGION, REDUCE T.
C
      IF ( BOUNDX ) THEN 
         IF (PTP .GT. RADIUS * RADIUS ) THEN
            T = BETA * T
            GO TO 150
         END IF
      END IF
C
C  RETURN TO THE CALLING PROGRAM TO CALCULATE Q = B P.
C
      JUMPTO = 3
      RETURN
  200 CONTINUE
C
C  COMPUTE THE SLOPE AND CURVATURE OF THE QUAD( X ) IN THE DIRECTION P.
C
      GTP  = ZERO
      PTBP = ZERO
CDIR$ IVDEP
      DO 210 J = 1, NFREE
         I     = IVAR( J )
         GTP   = GTP  + P( I ) * G( I )
         PTBP  = PTBP + P( I ) * Q( I )
C
C  FORM THE GRADIENT AT THE POINT X(T).
C
         GRAD( I ) = Q( I ) + G( I )
  210 CONTINUE
C
C  EVALUATE Q( X(T) ) AND LINEAR( X(T), MU ).
C
      QXT  = F + GTP + HALF * PTBP
      FLXT = F + RMU * GTP
C
C  --------------------------------------------------------------------
C  START OF THE MAIN ITERATION LOOP.
C  --------------------------------------------------------------------
C
  250 CONTINUE
      ITERCA = ITERCA + 1
C
C  WRITE DETAILS OF THE CURRENT POINT.
C
      IF ( PRONEL .OR. PRNTER ) WRITE( IOUT, 2010 ) ITERCA, T,
     *          QXT * FINDMX, FLXT * FINDMX
C
C  COMPARE Q( X(T) ) WITH LINEAR( X(T), MU ). IF X(T) SATISFIES
C  THE ARMIJO CONDITION AND THUS QUALIFIES AS A CAUCHY POINT, EXIT.
C
      IF ( ITERCA .GT. ITMAX .OR. QXT .LE. FLXT ) THEN
CDIR$ IVDEP
         DO 260 J   = 1, NFREE
            I       = IVAR( J )
            XT( I ) = X0( I ) + MIN( T, BREAKP( I ) ) * XT( I )
  260    CONTINUE
         GO TO 600
      END IF
C
C  X(T) IS NOT ACCEPTABLE. REDUCE T.
C
      TNEW = BETA * T
C
C  COMPUTE P = X( TNEW ) - X( T ).
C
CDIR$ IVDEP
      DO 270 J  = 1, NFREE
         I      = IVAR( J )
         P( I ) = ( MIN( TNEW, BREAKP( I ) ) - MIN( T, BREAKP( I ) ) )
     *            * XT( I )
  270 CONTINUE
C
C  RETURN TO THE CALLING PROGRAM TO CALCULATE Q = B P.
C
      JUMPTO = 4
      RETURN
  300 CONTINUE
C
C  COMPUTE THE SLOPE AND CURVATURE OF THE QUAD( X ) IN THE DIRECTION P.
C
      G0TP = ZERO
      GTP  = ZERO
      PTBP = ZERO
CDIR$ IVDEP
      DO 310 J = 1, NFREE
         I     = IVAR( J )
         G0TP  = G0TP + P( I ) * G( I )
         GTP   = GTP  + P( I ) * GRAD( I )
         PTBP  = PTBP + P( I ) * Q( I )
C
C  UPDATE THE EXISTING GRADIENT TO FIND THAT AT THE POINT X(TNEW).
C
         GRAD( I ) = GRAD( I ) + Q( I )
  310 CONTINUE
C
C  EVALUATE Q( X(T) ) AND LINEAR( X(T), MU ).
C
      QXT  = QXT + GTP + HALF * PTBP
      FLXT = FLXT + RMU * G0TP
      T    = TNEW
      GO TO 250
C
C  --------------------------------------------------------------------
C  END OF THE MAIN ITERATION LOOP.
C  --------------------------------------------------------------------
C
  500 CONTINUE
C
C  THE CAUCHY POINT OCCURED IN THE FIRST INTERVAL. RECORD THE POINT
C  AND THE VALUE OF THE QUADRATIC AT THE POINT.
C
      QXT = F + T * ( GTP + HALF * T * PTBP )
CDIR$ IVDEP
      DO 510 J   = 1, NFREE
         I       = IVAR( J )
         XT( I ) = X0( I ) + T * P( I )
  510 CONTINUE
C
C  WRITE DETAILS OF THE CAUCHY POINT.
C
      IF ( PRONEL .OR. PRNTER ) WRITE( IOUT, 2030 )
     *          ITERCA, T, QXT * FINDMX
C
C  THE GENERALIZED CAUCHY POINT HAS BEEN FOUND. SET THE ARRAY P
C  TO THE STEP FROM THE INITIAL POINT TO THE CAUCHY POINT.
C
  600 CONTINUE
      N3 = 0
CDIR$ IVDEP
      DO 610 J  = 1, NFREE
         I      = IVAR( J )
         P( I ) = XT( I ) - X0( I )
C
C  FIND WHICH VARIABLES ARE FREE AT X(T).
C
         IF ( T .LE. BREAKP( I ) ) THEN
            N3 = N3 + 1
         ELSE
            IF ( P( I ) .LT. ZERO ) INDEX( I ) = 1
            IF ( P( I ) .GT. ZERO ) INDEX( I ) = 2
C
C  MOVE THE FIXED VARIABLES TO THEIR BOUNDS.
C
            IF ( P( I ) .NE. ZERO ) XT( I ) = BND( I, INDEX( I ) )
         END IF
  610 CONTINUE
      IF ( PRONEL ) WRITE( IOUT, 2050 ) NZERO - N3 - 1
C
C  RECORD THAT VARIABLES WHOSE GRADIENTS WERE ZERO AT THE INITIAL
C  POINT ARE FREE VARIABLES.
C
      DO 620 J         = NZERO, N
         NFREE         = NFREE + 1
         IVAR( NFREE ) = IVAR( J )
  620 CONTINUE
C
C  SET RETURN CONDITIONS.
C
      NVAR1  = 1
      NVAR2  = NFREE
      JUMPTO = 0
      RETURN
C
C  NON-EXECUTABLE STATEMENTS.
C
 2000 FORMAT( /, 3X,
     *' ** INXAC  entered  iter     step       Q(step)   L(step,mu)',
     *        /, 21X, I6, 1P, 2D12.4 )
 2010 FORMAT( 21X, I6, 1P, 3D12.4 )
 2020 FORMAT( /, ' -------------- INXACT entered ----------------',
     *        //, I8, ' variables freed from their bounds ',
     *         /, I8, ' variables remain fixed ', / )
 2030 FORMAT( 21X, I6, 1P, 2D12.4 )
 2040 FORMAT( 21X, I6, '  1st line mimimizer infeasible. Step = ',
     *        1P, D10.2 )
 2050 FORMAT( 27X, I6, ' variables are fixed ' )
C
C  END OF INXAC.
C
      END
