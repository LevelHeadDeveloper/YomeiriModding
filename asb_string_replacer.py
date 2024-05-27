import sys

data = []

if (len(sys.argv) < 3):
    print("Usage: python asb_string_replacer.py path/to/input_file.asb path/to/text_dump.txt")
    exit()

filename = sys.argv[1]
text_filepath = sys.argv[2]

#Courtesy of "Mmm Donuts" on StackOverflow
def utf8len(s):
    return len(s.encode('utf-8'))

def getOperNamesAndArguments(opcode):
    if (opcode == 0):
        return ["show_text", ['s', 'i']]
    if (opcode == 906):
        return ["show_text_noindex", ['s']]
    if (opcode == 926):
        return ["show_text_noindex", ['s']]
    if (opcode == 331):
        return ["play_voice_line", ['i', 'i', 's']]
    if (opcode == 1):
        return ["display_choices", ['s', 's', 's', 's', 's', 's']]
    if (opcode == 2):
        return ["display_choices", ['s', 's', 's', 's', 's', 's']]
    if (opcode == 930):
        return ["display_choices", ['s', 's', 's', 's', 's', 's']]
    if (opcode == 931):
        return ["display_choices", ['i', 'i', 's', 's', 's', 's', 's']]
    return []

def getNullTerminatedStringAt(position):
    string_data = bytearray()
    if len(data) < position:
        return ""
    iterator = 0
    while True:
        byte1 = data[position + iterator]
        iterator += 1
        if (len(data) < position + iterator) or (byte1 == 0x00):
            break;
        string_data.append(byte1)
    return string_data.decode()

def get32BitIntegerAt(position):
    int_data = bytearray()
    if (len(data) <= position+3):
        return 0
    for i in range(4):
        byte1 = data[position + i]
        int_data.append(byte1)
    return_value = int.from_bytes(int_data, "little")
    return return_value

def get16BitIntegerAt(position):
    int_data = bytearray()
    if (len(data) <= position+1):
        return 0
    for i in range(2):
        byte1 = data[position + i]
        int_data.append(byte1)
    return_value = int.from_bytes(int_data, "little")
    return return_value

def get8BitIntegerAt(position):
    int_data = bytearray()
    if (len(data) <= position):
        return 0
    byte1 = data[position]
    int_data.append(byte1)
    return_value = int.from_bytes(int_data, "little")
    return return_value 

indices_of_string_indices = {}

string_index_replacements = {}

indexed_strings = {}

def get_all_indexed_strings():
    string_start = string_sections[1][0]
    index = 0
    data_length = len(data)
    while (string_start+index < data_length):
        string1 = getNullTerminatedStringAt(string_start+index)
        indexed_strings[str(index)] = string1
        index += utf8len(string1)+1

def add_string_offset(position, index):
    string_index_replacements[str(index)] = index
    if (indices_of_string_indices.get(str(index), 0) == 0):
        indices_of_string_indices[str(index)] = []
    indices_of_string_indices[str(index)].append(position)

def get_external_script_command(command_index, args):
    arg_positions = []
    arg_list = []
    for i in range(args):
        arg_positions.append(function_arg_positions[len(function_args)-(args)+i])
        arg_list.append(function_args[len(function_args)-(args)+i])
    types = getOperNamesAndArguments(command)
    if (len(types) != 0):
        command = types[0]
    for i in range(len(arg_list)):
        if (len(types) > 1) and (len(types[1]) > i):
            arg_type = types[1][i]
            if (arg_type == 's'):
                add_string_offset(arg_positions[i], arg_list[i])

def test_voice_line(line):
    if (len(line) < 14):
        print("Error: Voice line "+line+" too short, will cause game to hang.")
    if (len(line) > 16):
        print("Error: Voice line "+line+" too long, will cause game to hang.")
    if (len(line) == 15) and (line.endswith("G") == False):
        print("Error: Voice line "+line+" too long, will cause game to hang.")
    line_test = line[0:3]
    line_test_2 = line[4:7]
    if (line_test != line_test_2):
        print("Error: Voice line not valid. Check that the path matches the filename.")

def get_script_command(type1, args):
    arg_list = []
    arg_positions = []
    for i in range(args):
        arg_positions.append(function_arg_positions[len(function_args)-(args)+i])
        arg_list.append(function_args[len(function_args)-(args)+i])
    types = getOperNamesAndArguments(type1)
    if (len(types) != 0):
        command = types[0]
    for i in range(len(arg_list)):
        if (len(types) > 1) and (len(types[1]) > i):
            arg_type = types[1][i]
            if (arg_type == 's'):
                if (type1 == 331):
                    voice_line = getNullTerminatedStringAt(arg_list[i]+string_sections[1][0])
                    test_voice_line(voice_line)
                if (args == 2) and (type1 == 331):
                    print("Something is seriously wrong.")
                add_string_offset(arg_positions[i], arg_list[i])

file1 = open(filename, mode="rb")

data = bytearray(file1.read())

if len(data) < 14:
    exit()

outputFileName = getNullTerminatedStringAt(0x4)
#print("File name: "+outputFileName)
number_of_sections = get32BitIntegerAt(0x28)
string_sections = []
sections = []
sec_iterator = 0
for i in range(3):
    string_section_start = get32BitIntegerAt(0x2c+(i*8))
    string_section_len = get32BitIntegerAt(0x30+(i*8))
    string_sections.append([string_section_start, string_section_len])
for i in range(number_of_sections):
    func_name_offset = get32BitIntegerAt(0x44+sec_iterator)
    add_string_offset(0x44+sec_iterator, func_name_offset)
    script_section_start = get32BitIntegerAt(0x50+sec_iterator)
    script_section_len = get32BitIntegerAt(0x54+sec_iterator)
    function_name = getNullTerminatedStringAt(func_name_offset+string_sections[1][0])
    args = []
    sec_iterator += 0x14
    sections.append([script_section_start, script_section_len, function_name])

output_file = open(outputFileName.replace(".asb", ".asb"), "wb")

function_args = []

function_arg_positions = []

get_all_indexed_strings()

for i in sections:
    if (i[0]+string_sections[0][0]) >= string_sections[1][0]:
        print("invalid section. Skipping")
        break
    else:
        start_at = i[0]+string_sections[0][0]
        end_at = i[0]+i[1]+string_sections[0][0]-1
        current_pos = start_at
        current_index = get8BitIntegerAt(start_at)
        tabs = 1
        while (current_index != 0x2b) and (current_pos < end_at):
            if (current_index == 0x01):
                function_args.append(get32BitIntegerAt(current_pos + 1))
                function_arg_positions.append(current_pos + 1)
                current_pos += 0x05
            elif (current_index == 0x03):
                function_args.append(get32BitIntegerAt(current_pos + 1))
                function_arg_positions.append(current_pos + 1)
                current_pos += 0x05
            elif (current_index == 0x04):
                function_args.append(get32BitIntegerAt(current_pos + 1))
                function_arg_positions.append(current_pos + 1)
                current_pos += 0x05
            elif (current_index == 0x08):
                function_args.append(get32BitIntegerAt(current_pos + 1))
                function_arg_positions.append(current_pos + 1)
                current_pos += 0x05
            elif (current_index == 0x14):
                current_pos += 0x01
            elif (current_index == 0x16):
                function_args.append(get16BitIntegerAt(current_pos + 1))
                function_arg_positions.append(current_pos + 1)
                current_pos += 0x03
            elif (current_index == 0x0a):
                function_args.append(get32BitIntegerAt(current_pos + 1))
                function_arg_positions.append(current_pos + 1)
                current_pos += 0x06
            elif (current_index == 0x02):
                function_args.append(get8BitIntegerAt(current_pos + 1))
                function_arg_positions.append(current_pos + 1)
                current_pos += 0x02
            elif (current_index == 0x13):
                current_pos += 0x01
            elif (current_index == 0x20):
                if get8BitIntegerAt(current_pos+1) == 0x18:
                    current_pos += 0x01
                current_pos += 0x01
            elif (current_index == 0x07):
                function_args.append(get8BitIntegerAt(current_pos + 1))
                function_arg_positions.append(current_pos + 1)
                current_pos += 0x02
            elif (current_index == 0x05):
                current_pos += 0x01
            elif (current_index == 0x1b):
                if get8BitIntegerAt(current_pos+1) == 0x18:
                    current_pos += 0x01
                if get8BitIntegerAt(current_pos+1) == 0x19:
                    current_pos += 0x01
                if get8BitIntegerAt(current_pos+1) == 0x06:
                    current_pos += 0x01
                current_pos += 0x01
            elif (current_index == 0x1c):
                current_pos += 0x06
            elif (current_index == 0x1d):
                current_pos += 0x01
            elif (current_index == 0x1e):
                current_pos += 0x01
            elif (current_index == 0x1f):
                current_pos += 0x01
            elif (current_index == 0x0b):
                current_pos += 0x09
            elif (current_index == 0x0c):
                current_pos += 0x09
            elif (current_index == 0x25):
                current_pos += 0x05
            elif (current_index == 0x21):
                current_pos += 0x05
            elif (current_index == 0x22):
                current_pos += 0x05
            elif (current_index == 0x24):
                number_of_outcomes = get8BitIntegerAt(current_pos+1)
                current_pos += 0x02 + number_of_outcomes*0x4
            elif (current_index == 0x28):

                import_from = get32BitIntegerAt(current_pos+1)
                command_index = get32BitIntegerAt(current_pos+5)
                args2 = get8BitIntegerAt(current_pos+9)

                arg_positions = []
                arg_list = []
                for i in range(args2):
                    arg_positions.append(function_arg_positions[len(function_args)-(args2)+i])
                    arg_list.append(function_args[len(function_args)-(args2)+i])
                add_string_offset(current_pos+1, import_from)
                add_string_offset(current_pos+5, command_index)
                types = getOperNamesAndArguments(999)
                for i in range(len(arg_list)):
                    if (len(types) > 1) and (len(types[1]) > i):
                        arg_type = types[1][i]
                        if (arg_type == 's'):
                            add_string_offset(arg_positions[i], arg_list[i])

                current_pos += 0x0a
            elif (current_index == 0x26):
                add_string_offset(current_pos+5, get32BitIntegerAt(current_pos+5))
                current_pos += 0x09
            elif (current_index == 0x29):
                get_script_command(get32BitIntegerAt(current_pos+1), get8BitIntegerAt(current_pos+5))
                current_pos += 0x06
            elif (current_index == 0x27):
                current_pos += 0x06
            else:
                print("error: unknown operation at "+hex(current_pos)+": "+hex(current_index))
                exit()
            current_index = get8BitIntegerAt(current_pos)

string_data_len = string_sections[1][1] + string_sections[2][1]

temporary_string_data = bytearray(string_data_len)

def write_string_data_to_file(string, index):
    strdata = string.encode("utf-8", errors="ignore")
    for i in range(len(strdata)):
        temporary_string_data[index+i] = strdata[i]
    pass
    temporary_string_data[index+len(strdata)] = 0

expected_strings = []
unindexed_strings = []

indices_of_strings_to_add = {}

index = 0

empty_string_sections = []

start_of_section = 0
length_of_section = 0

dummy_data = "dummy_data"

for i in indexed_strings.keys():
    expected_strings.append(indexed_strings[i])
    if (string_index_replacements.get(i, "") == ""):
        if (length_of_section != 0):
            empty_string_sections.append([start_of_section, length_of_section+1])
        unindexed_strings.append(i)
        write_string_data_to_file( indexed_strings[i], int(i) )
        start_of_section = int(i)+utf8len(indexed_strings[i])+1
        length_of_section = 0
    else:
        indices_of_strings_to_add[i] = index
        length_of_section += utf8len(indexed_strings[i])
    index += 1
if (length_of_section != 0):
    empty_string_sections.append([start_of_section, length_of_section+1])



text_file = open(text_filepath)

index = 0

for line in text_file.read().splitlines():
    if (index >= len(expected_strings)):
        break
    expected_strings[index] = line.rstrip().replace("[nl]", "\n")
    index += 1

text_file.close()

def squeeze_string_into_file(string1):
    required_length = utf8len(string1)
    for i in empty_string_sections:
        if (i[1] > required_length+1):
            i[1] -= required_length
            write_string_data_to_file(string1, i[0])
            return_val = i[0]
            i[0] += required_length+1
            return return_val
    return 0

for i in indices_of_strings_to_add.keys():
    new_index = squeeze_string_into_file(expected_strings[indices_of_strings_to_add[i]])
    string_index_replacements[i] = new_index
    bytes1 = new_index.to_bytes(4, "little")
    for j in indices_of_string_indices[i]:
        for k in range(4):
            data[j+k] = bytes1[k]

output_file.write(data[0:string_sections[1][0]])
output_file.write(temporary_string_data)

output_file.close()

