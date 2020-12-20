#!/usr/bin/awk

### USAGE
# awk -v GoodClassId=1,2 -v border_score=0.7 -f hoge.awk input.star

function Init_read_line(image_num){
    class[image_num] = $column_ClassNumber
    LINE[image_num] = $0
}

function Calc_edit_ClassNumber(image_num){
    good = 0
    for (i=1; i<=image_num; i++){
        for (j=1; j<=good_class_num; j++){
            if (class[i] == GoodClass[j]){
                good += 1
                break
            }
        }
    }
    if (good/image_num >= border_score){
        return 1
    } else {
        return 2
    }
}

function Print_edit_class_line(image_num, LINE){
    for (i=1; i<=image_num; i++){
        node_num = split(LINE[i], node)
        node[column_ClassNumber] = edit_ClassNumber
        for (j=1; j<=node_num; j++){
            printf("%s ", node[j])
        }
        printf("\n")
        LINE[i] = 0
    }
}

BEGIN{
    good_class_num = split(GoodClassId, GoodClass, ",")
    init_Micrograph = 0
    if (border_score <= 0 || border_score >= 1) {print "ERROR: border_score is (0, 1)"; exit}
    if (good_class_num < 1) {print "ERROR; define good class id at least one, maybe your define tag is wrong. (ex) GoodClassID -> GoodClassId"; exit}
}
{
    if ($1 ~ /_rln/){
        num_rln += 1
        if ($1 == "_rlnMicrographName"){column_MicrographName=substr($2, 2)+0}
        if ($1 == "_rlnHelicalTubeID"){column_HelicalTubeID=substr($2, 2)+0}
        if ($1 == "_rlnClassNumber"){column_ClassNumber=substr($2, 2)+0}
        print $0
    } else if (NF == num_rln && $1 ~ /^[0-9]/){
        if (init_Micrograph == 0){
            init_Micrograph = 1
            read_Micrograph = $column_MicrographName
            read_HelicalTube = $column_HelicalTubeID
            image_num = 1
            Init_read_line(image_num)
        } else {
            if (read_Micrograph == $column_MicrographName){
                if (read_HelicalTube == $column_HelicalTubeID){
                    image_num += 1
                    Init_read_line(image_num)
                } else {
                    edit_ClassNumber = Calc_edit_ClassNumber(image_num)
                    Print_edit_class_line(image_num, LINE)

                    read_HelicalTube = $column_HelicalTubeID
                    image_num = 1
                    Init_read_line(image_num)
                }
            } else {
                edit_ClassNumber = Calc_edit_ClassNumber(image_num)
                Print_edit_class_line(image_num, LINE)

                read_Micrograph = $column_MicrographName
                read_HelicalTube = $column_HelicalTubeID
                image_num = 1
                Init_read_line(image_num)
            }
        }
    } else {
        print $0
    }
}
END{
    edit_ClassNumber = Calc_edit_ClassNumber(image_num)
    Print_edit_class_line(image_num, LINE)
}
