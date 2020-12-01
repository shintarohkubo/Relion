#!/usr/bin/awk

### USAGE ###
# awk -v border_score=0.7 -f unify_mt_classification.awk input.star good-class-num.txt > output.star
# good-class-num.txt is only written good class number for each line in the text
# If you think class 1 and class 2 is good, and others are bad, you make like below.
# $cat good-class-num.txt
#  1
#  2
#
# Note: this script give you a new HelicalTubeID. If some is good, the new number is 1. If some is bad, the new number is 2. 
#############

BEGIN{
    num_rln=0
    num_micrograph=0
    line=0
    good_class_num = 0
}
FILENAME == ARGV[1]{
    if ($1 ~ /_rln/){
        num_rln += 1
        if ($1 == "_rlnMicrographName"){column_MicrographName=substr($2, 2)+0}
        if ($1 == "_rlnHelicalTubeID"){column_HelicalTubeID=substr($2, 2)+0}
        if ($1 == "_rlnClassNumber"){column_ClassNumber=substr($2, 2)+0}
    }

    if (NF == num_rln && $1 ~ /^[0-9]/){
        line+=1
        LINE[line]=$0

        if (num_micrograph > 0){
            tag_micrograph=0
            for (i=1; i<=num_micrograph; i++){
                if ($column_MicrographName == MicrographName[i]){
                    tag_micrograph = 1

                    tag_helicaltubeid = 0
                    for (j=1; j<=num_HelicalTubeID[i]; j++){
                        if ($column_HelicalTubeID == HelicalTubeID[i][j]){
                            tag_helicaltubeid = 1

                            num_ClassNumber[i][num_HelicalTubeID[i]] = num_ClassNumber[i][num_HelicalTubeID[i]] + 1
                            ClassNumber[i][num_HelicalTubeID[i]][num_ClassNumber[i][num_HelicalTubeID[i]]] = $column_ClassNumber
                        }
                    }
                    if (tag_helicaltubeid == 0){
                        num_HelicalTubeID[i] = num_HelicalTubeID[i] + 1
                        HelicalTubeID[i][num_HelicalTubeID[i]] = $column_HelicalTubeID

                        num_ClassNumber[i][num_HelicalTubeID[i]] = 1
                        ClassNumber[i][num_HelicalTubeID[i]][num_ClassNumber[i][num_HelicalTubeID[i]]] = $column_ClassNumber
                    }
                }
            }
            if (tag_micrograph == 0){
                num_micrograph+=1
                MicrographName[num_micrograph]=$column_MicrographName

                num_HelicalTubeID[num_micrograph] = 1
                HelicalTubeID[num_micrograph][num_HelicalTubeID[num_micrograph]] = $column_HelicalTubeID

                num_ClassNumber[num_micrograph][num_HelicalTubeID[num_micrograph]] = 1
                ClassNumber[num_micrograph][num_HelicalTubeID[num_micrograph]][num_ClassNumber[num_micrograph][num_HelicalTubeID[num_micrograph]]] = $column_ClassNumber
            }
        } else {
            num_micrograph = 1
            MicrographName[num_micrograph] = $column_MicrographName

            num_HelicalTubeID[num_micrograph] = 1
            HelicalTubeID[num_micrograph][num_HelicalTubeID[num_micrograph]] = $column_HelicalTubeID

            num_ClassNumber[num_micrograph][num_HelicalTubeID[num_micrograph]] = 1
            ClassNumber[num_micrograph][num_HelicalTubeID[num_micrograph]][num_ClassNumber[num_micrograph][num_HelicalTubeID[num_micrograph]]] = $column_ClassNumber
        }
    } else {
        print $0
    }
}
FILENAME == ARGV[2]{
    if (NF != 1){print "Warning!! File format may be not correct"}
    good_class_num += 1
    GoodClass[good_class_num] = $1
}
END{
#print num_micrograph
    for (i=1; i<=num_micrograph; i++){
#print num_HelicalTubeID[i]
        for (j=1; j<=num_HelicalTubeID[i]; j++){
            good = 0
#print num_ClassNumber[i][j]
            for (k=1; k<=num_ClassNumber[i][j]; k++){
                for (l=1; l<=good_class_num; l++){
#print i, j, k, ClassNumber[i][j][k], l, GoodClass[l]
                    if (ClassNumber[i][j][k] == GoodClass[l]){
                        good+=1
                    }
                }
            }

#print good, num_ClassNumber[i][j], good/num_ClassNumber[i][j], border_score
            if (good/num_ClassNumber[i][j] >= border_score){
                edit_ClassNumber[i][j] = 1
            } else {
                edit_ClassNumber[i][j] = 2
            }
#print i, j, edit_ClassNumber[i][j], edit_ClassNumber[i][j]
        }
    }

    for (l=1; l<=line; l++){
        node_num=split(LINE[l], node)
        for (i=1; i<=num_micrograph; i++){
            for (j=1; j<=num_HelicalTubeID[i]; j++){
                if (node[column_MicrographName] == MicrographName[i] && node[column_HelicalTubeID] == HelicalTubeID[i][j]){
                    node[column_ClassNumber] = edit_ClassNumber[i][j]
                }
            }
        }

        for (i=1; i<=node_num; i++){
            printf("%s ", node[i])
        }
        printf("\n")
    }
}
