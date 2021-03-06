import os, fnmatch, ConfigParser, re, pwd
from collections import defaultdict

class ProblemFile:
    path = ""
    size = 0
    uid = 0
    gid = 0

    def display(self):
        print (self.path + " is " + str(self.size/1024/1024) + "mb UID:" + str(self.uid) + " GID:" + str(self.gid))

problem_files = []



def find_files(check_path, pattern, size_limit):
    print "Path:" + check_path + "Pattern: " + pattern + "Size Limit: " + str(size_limit)
    p = re.compile(pattern, re.IGNORECASE)
    matched_file_list = []
    for directory_name, subdirectory_list, file_list in os.walk(check_path):
        for file_name in file_list:
            if p.match(file_name): # Match search string
                inspect_file(os.path.join(directory_name, file_name), size_limit)


def inspect_file(file_name, size_limit):
    try:
        stat_info = os.stat(file_name)
    except:
        return
    if (stat_info.st_size >= size_limit):
        #print file_name, stat_info.st_size, size_limit
        pf = ProblemFile()
        pf.path = file_name
        pf.size = stat_info.st_size
        pf.uid = stat_info.st_uid
        pf.gid = stat_info.st_gid
        problem_files.append(pf)

def print_sizes():
    total_size = 0
    uid_sizes = {}

    for problem_file in problem_files:
        problem_file.display()
        total_size += problem_file.size
        if str(problem_file.uid) in uid_sizes:
            uid_sizes[str(problem_file.uid)] += problem_file.size
        else:
            uid_sizes[str(problem_file.uid)] = problem_file.size

    print "Total size of", total_size / 1024 / 1024 / 1024, "gb."

    for uid_size in uid_sizes:
        try: 
            print pwd.getpwuid(int(uid_size))[0], "UID", uid_size, "is using", uid_sizes[uid_size]/1024/1024/1024, "gb."
        except:
            print "Unknown user", "UID", uid_size, "is using", uid_sizes[uid_size]/1024/1024/1024, "gb."




# Parse the configuration file. 
conf = ConfigParser.ConfigParser()
conf.read("file-parameters.ini")

# For each of the defined conditions, find the files that match.
for section in conf.sections():
    find_files(conf.get(section, "directory_root"), conf.get(section, "file_name_pattern"), int(conf.get(section, "file_size")))

print_sizes()

