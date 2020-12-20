# Relion
## unify the Microtubules classification in your star file.

In the one micrograph, there are a lot of images include. In the one image, there are some MTs. (called HelicalTubeID)

One MT has several images these are the extracted position is difference. Some images are good, others are bad. 
After 2D/3D classification, all images get specific class number.
To see the class average, we can know which class is good and which is bad.

If the most of all images extracted from the one MT have good class ID, I can say "Yes, this MT is entire good".
But, if 50% (for example) images extracted from the one MT have bad class ID, I want to say "This MT is bad. I don't need this MT to use for getting average".

### USAGE
```
$awk -v border_score=0.7 -f unify_mt_classification.awk input.star good-class-num.txt > output.star
```
If more than 70% images of one MT in the one micrograph is clasified the good class, all images from the MT is re-named good class ID (now is "1").
"70%" is defined at ```border_score=0.7```.

good-class-num.txt is only written good class number for each line in the text.
If you think class 1 and class 2 is good, and others are bad, you make like below.
```
$cat good-class-num.txt
1
2
```
Note: this script give you a new ClassNumber. If classes are good, the new class number is 1. If classes are bad, the new class number is 2. 

### if you treat large file for input...you should use ver2.awk like below
```
awk -v GoodClassId=1,2 -v border_score=0.7 -f unify_mt_classification_ver2.awk input.star > output.star
```
You should check the way how to set Good Class ID is changed.
In the ver2, you can set the number directly, but you shouldn't add space between "," and the next number.
(ex) ```GoodClassId=1, 2``` is wrong usage. ```GoodClassId=1,2``` is correct.

Honestly I think that the way of setting ID like this (not used good-class-num.txt) is boring.
If you also think so, you can use some simple bash&awk script.

## Generate segment average (rolling average) of the Microtubules.

When you use Helical Processing in Relion, you might get the continued images along some MT.
Before/After 2D/3D classification, and before the refinement process, someone wants to make more clear (higher S/N ratio) image.

The objective is getting segment average along each MT.
To read a binary file (.mrc) with a text file (.star), and make a new one.

### USAGE
#### Case1
```
$python particlestar2segmentaverage.py --istar example.star --ostar fuga.star --gnum 5
```
In the example star file, some movie files are listed. Reading this star file and open the listed movie file.
Then, based on the HelicalTubeID written in the input star file, this code makes segment average images from the movie files.

```--gnum 5``` mean the number of images for makeing one segment average is 5. Basically, you should select the value more than 5.

New movies (convert images) are named automatically.
If the input movie file name (written in the star file) is ```hoge.mrc```, the output movie file is named ```hoge_SAs.mrc```.
Also, you can define the output star file name by ```--ostar fuga.star```.

Note: mrcs files are needed at the same directory with the input star file and this script

#### Case2
If you want a microtubule-by-microtubule average image instead of every 5 or 7 images, use this script.
```
$python particlestar2allsegmentaverage.py --istar example.star
```
Note: This script doesn't output a star file. It only outputs images for the number of HelicalTubeID in each mrc.

#### Case 3
If you want rolling average for each ClassNumber for each HelicalTubeID, use this script.
```
$python particlestar2classsegmentaverage.py --istar example.star --oinfo output_info.txt
```
Note: The information about new mrc files are written in the file you named by ```--oinfo```
