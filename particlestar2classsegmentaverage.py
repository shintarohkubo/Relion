import os, sys, argparse
import numpy as np

### USAGE
#  python particles2segmentaverage.py --istar input.star --ostar output.star --gnum 5 (if one average images made from 5 original images)

class Body_mrc:
    def __init__(self, filename, shape, dtype, idx):
        self.filename = filename
        self.shape = (int(shape[0]), int(shape[1]))
        self.idx = idx
        self.dtype = dtype
        self.length = (np.dtype(dtype).itemsize) * shape[0] * shape[1]
        self.offset = 1024 + idx * self.length  # header + num-of-image * one-image-size

    def get(self):
        with open(self.filename, "rb") as f:
            f.seek(self.offset)  # go to idx-th  image data in mrc-file
            # get x_pixel x y_pixel data and reshape to the self.shape format by Fortrun method
            data = np.reshape(np.fromfile(f, dtype=self.dtype, count=np.prod(self.shape)), self.shape, order='F')
        return data

    def view(self):
        return self.get()

def Read_mrc_header(filename):
    hdr = None
    with open(filename, "rb") as f:
        hdr = {}
        header = np.fromfile(f, dtype=np.int32, count=256)
        header_f = header.view(np.float32)
        [hdr['nx'], hdr['ny'], hdr['nz'], hdr['datatype']] = header[0:4]
        [hdr['xlen'], hdr['ylen'], hdr['zlen']] = header_f[10:13]
    return hdr

def Write_mrc_header(filename, nxyz=0, dmin=0, dmax=0, dmean=0, mode=2, psize=1):
    filename.seek(0)
    header          = np.zeros(256, dtype=np.int32)
    header_f        = header.view(np.float32)
    header[:3]      = nxyz
    header[3]       = mode  # node=2: float32
    header[7:10]    = nxyz  # mx, my, mz (grid size) #this is not correct. mxyz is right.
    header_f[10:13] = [psize*i for i in nxyz] # xlen, ylen, zlen
    header_f[13:16] = 90.0 # CELLB
    header[16:19]   = [1, 2, 3]
    header_f[19:22] = [dmin, dmax, dmean]  # data stats
    header[52]      = 542130509  # 'MAP ' chars
    header[53]      = 16708
    header.tofile(filename)

def get_dtype(hdr):
    return {0:np.int8, 1:np.int16, 2:np.float32, 6:np.uint16} [hdr['datatype']]

def Read_mrc_body(filename):
    hdr = Read_mrc_header(filename)
    shape = (hdr['nx'], hdr['ny'])
    image_num = hdr['nz']
    dtype = get_dtype(hdr)
    body_data = [Body_mrc(filename, shape, dtype, idx) for idx in range(image_num)]
    return body_data

def Write_mrc_body(data, output):
    np.require(np.reshape(data, (-1, ), order='F'), dtype=np.float32).tofile(output)

def Read_star_header(instar):
    instar.seek(0)
    before_loop = False
    header_star = False
    headerlabels = []
    while not before_loop:
        line=instar.readline()
        if line.startswith('loop_'):
            before_loop = True

    while not header_star:
        line=instar.readline()
        if not line.startswith('_'):
            header_star = True
        else:
            headerlabels += [line]
    instar.seek(0)
    return headerlabels

def get_col_star(starlabels, labelname):
    for i, s in enumerate(starlabels):
        if labelname in s:
            return i
    return -1

def check_specific_col_exist(col_num, col_name):
    if col_num == -1:
        print("input star file doesn't contain " + str(col_name) + " column")
        exit()

if __name__=='__main__':
    parser = argparse.ArgumentParser(description='Reading star file and making rolling average for each ClassNumber of each HelicalTubes, output new mrc file is added "_SAs_Class" tag to the original mrc files.')
    parser.add_argument('--istar', help='Input star file',  required=True)
    parser.add_argument('--oinfo', help='Output info text',  required=True)
    args = parser.parse_args()

    # parameter of makein average images

    with open(args.istar, 'r') as instar, open(args.oinfo, 'w') as outinfo:
        # Read header information from input-star file 
        starlabels = Read_star_header(instar)
        col_HelicalTubeID = get_col_star(starlabels, 'HelicalTubeID')
        col_ImageName = get_col_star(starlabels, 'ImageName')
        col_ClassNumber = get_col_star(starlabels, 'ClassNumber')

        check_specific_col_exist(col_HelicalTubeID, 'HelicalTubeID')
        check_specific_col_exist(col_ImageName, 'ImageName')
        check_specific_col_exist(col_ImageName, 'ClassNumber')

        # initialize 
        List_mrc_name = {}
        num_mrc_name = -1
        List_num_tubeid = {}
        List_imageid_each_class = {}
        count_image = {}
        max_class_id = 1
        min_class_id = 1
        # read star file for getting each images information
        for line in instar:
            record = line.split()
            if len(record) == len(starlabels):
                # get original mrc file name from a reading line
                tubeid = int(record[col_HelicalTubeID])
                imagenum_and_mrcname = record[col_ImageName].split('@')
                classid = int(record[col_ClassNumber])

                max_class_id = max(max_class_id, classid)
                min_class_id = min(min_class_id, classid)

                if imagenum_and_mrcname[1] in List_mrc_name.keys():
                    List_num_tubeid[imagenum_and_mrcname[1]] = max(List_num_tubeid[imagenum_and_mrcname[1]], tubeid)
                else:
                    num_mrc_name += 1
                    List_mrc_name[imagenum_and_mrcname[1]] = num_mrc_name
                    List_num_tubeid[imagenum_and_mrcname[1]] = tubeid

                a = List_mrc_name[imagenum_and_mrcname[1]]
                b = tubeid
                if (a, b) in count_image.keys():
                    count_image[(a, b)] += 1
                else:
                    count_image[(a, b)]  = 1

                c = classid
                if (a, b, c) in List_imageid_each_class.keys():
                    List_imageid_each_class[(a, b, c)].append(int(imagenum_and_mrcname[0]) - 1)
                else:
                    List_imageid_each_class[(a, b, c)] = []
                    List_imageid_each_class[(a, b, c)].append(int(imagenum_and_mrcname[0]) - 1)


        # get image mrc body data
        for i in range(num_mrc_name+1):
            mrc_name = ''.join([k for k, v in List_mrc_name.items() if v == i])
            all_images_in_one_mrc = Read_mrc_body(mrc_name)
            tube_num = List_num_tubeid[mrc_name]

            # prepare temporaly output mrc file header
            output_each_mrcname = str(mrc_name).split('.')
            output_edit_mrcname = output_each_mrcname[0] + "_SAs_Class." + output_each_mrcname[1]
            nxyz  =  np.array([0, 0, 0])
            dmin  =  np.inf
            dmax  = -np.inf
            dmean =   0
            with open(output_edit_mrcname, 'wb') as output_edit_mrcname:
                Write_mrc_header(output_edit_mrcname, nxyz, dmin, dmax, dmean, mode=2)
                tot_image_num = 0
                for j in range(tube_num):
                    for k in range(min_class_id, max_class_id+1):
                        if (i, j+1, k) in List_imageid_each_class.keys():
                            one_image_mrc_body_data = 0
                            tmp_count = 0
                            for l in List_imageid_each_class[(i, j+1, k)]:
                                tmp_count += 1
                                one_image_mrc_body_data += all_images_in_one_mrc[l].view()
                            output_info=str('{}   HelicalTubeID: {}  ClaaNumber: {}  Num_of_images_for_average: {}\n').format(mrc_name, j+1, k, tmp_count)
                            outinfo.write(output_info)
                    
                            one_image_mrc_body_data /= tmp_count
                            Write_mrc_body(one_image_mrc_body_data, output_edit_mrcname)
                            dmean += np.sum(one_image_mrc_body_data)
                            dmin   = min(np.min(one_image_mrc_body_data), dmin)
                            dmax   = max(np.max(one_image_mrc_body_data), dmax)
                            tot_image_num += 1

                # re-write mrc header
                output_info=str('total_image_number_of_{}: {}\n').format(mrc_name, tot_image_num)
                outinfo.write(output_info)
                nxyz = np.array([one_image_mrc_body_data.shape[0], one_image_mrc_body_data.shape[1], tot_image_num])
                dmean = dmean/(nxyz[0] * nxyz[1] * nxyz[2])
                Write_mrc_header(output_edit_mrcname, nxyz, dmin, dmax, dmean, mode=2)
