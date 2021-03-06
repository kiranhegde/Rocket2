        !COMPILER-GENERATED INTERFACE MODULE: Fri Sep 25 13:47:10 2015
        MODULE SURFACE_3D__genmod
          INTERFACE 
            SUBROUTINE SURFACE_3D(TYPE1,TYPE2,TIMESTEP,F_POINT_NUM,     &
     &F_POINT,F_FACE_NUM,F_FACE,F_LOC,F_B_RATE,F_PRESSURE,F_BCFLAG,     &
     &P_POINT_NUM,P_POINT,P_FACE_NUM,P_FACE,P_LOC,P_VELOCITY,           &
     &P_DISPLACEMENT,P_FORCE,P_FACE_AREA,P_CORNER_INDEX,                &
     &P_RIDGE_GROUP_NUM,P_RIDGE_NUM,P_RIDGE,C_POINT_NUM,C_POINT,        &
     &C_FACE_NUM,C_FACE,C_VELOCITY,C_DISPLACEMENT,C_FORCE,FLAG,         &
     &FLAG_ARRAY,FILENUM,PATCHNUM)
              INTEGER(KIND=4) ,OPTIONAL :: TYPE1
              INTEGER(KIND=4) ,OPTIONAL :: TYPE2
              REAL(KIND=8) ,OPTIONAL :: TIMESTEP
              INTEGER(KIND=4) ,OPTIONAL :: F_POINT_NUM
              REAL(KIND=8) ,OPTIONAL ,ALLOCATABLE :: F_POINT(:,:)
              INTEGER(KIND=4) ,OPTIONAL :: F_FACE_NUM
              INTEGER(KIND=4) ,OPTIONAL ,ALLOCATABLE :: F_FACE(:,:)
              INTEGER(KIND=4) ,OPTIONAL ,ALLOCATABLE :: F_LOC(:)
              REAL(KIND=8) ,OPTIONAL :: F_B_RATE(:)
              REAL(KIND=8) ,OPTIONAL :: F_PRESSURE(:)
              INTEGER(KIND=4) ,OPTIONAL ,ALLOCATABLE :: F_BCFLAG(:)
              INTEGER(KIND=4) ,OPTIONAL :: P_POINT_NUM
              REAL(KIND=8) ,OPTIONAL ,ALLOCATABLE :: P_POINT(:,:)
              INTEGER(KIND=4) ,OPTIONAL :: P_FACE_NUM
              INTEGER(KIND=4) ,OPTIONAL ,ALLOCATABLE :: P_FACE(:,:)
              INTEGER(KIND=4) ,OPTIONAL ,ALLOCATABLE :: P_LOC(:)
              REAL(KIND=8) ,OPTIONAL :: P_VELOCITY(:,:)
              REAL(KIND=8) ,OPTIONAL :: P_DISPLACEMENT(:,:)
              REAL(KIND=8) ,OPTIONAL :: P_FORCE(:,:)
              REAL(KIND=8) ,OPTIONAL ,ALLOCATABLE :: P_FACE_AREA(:)
              INTEGER(KIND=4) ,OPTIONAL ,ALLOCATABLE :: P_CORNER_INDEX(:&
     &)
              INTEGER(KIND=4) ,OPTIONAL :: P_RIDGE_GROUP_NUM
              INTEGER(KIND=4) ,OPTIONAL ,ALLOCATABLE :: P_RIDGE_NUM(:)
              INTEGER(KIND=4) ,OPTIONAL ,ALLOCATABLE :: P_RIDGE(:,:)
              INTEGER(KIND=4) ,OPTIONAL :: C_POINT_NUM
              REAL(KIND=8) ,OPTIONAL ,ALLOCATABLE :: C_POINT(:,:)
              INTEGER(KIND=4) ,OPTIONAL :: C_FACE_NUM
              INTEGER(KIND=4) ,OPTIONAL ,ALLOCATABLE :: C_FACE(:,:)
              REAL(KIND=8) ,OPTIONAL :: C_VELOCITY(:,:)
              REAL(KIND=8) ,OPTIONAL :: C_DISPLACEMENT(:,:)
              REAL(KIND=8) ,OPTIONAL :: C_FORCE(:,:)
              LOGICAL(KIND=4) ,OPTIONAL :: FLAG
              INTEGER(KIND=4) ,OPTIONAL ,ALLOCATABLE :: FLAG_ARRAY(:)
              INTEGER(KIND=4) ,OPTIONAL :: FILENUM
              INTEGER(KIND=4) ,OPTIONAL :: PATCHNUM
            END SUBROUTINE SURFACE_3D
          END INTERFACE 
        END MODULE SURFACE_3D__genmod
