# YomeiriModding

A collection of information about modding the game Nisekoi: Yomeiri!? (and possibly others made by Artdink Studios).

# What can I get here?

Right now, I've finished one tool, and I'll give you lots of information.

# The Game

[Nisekoi: Yomeiri!?](https://nisekoi.fandom.com/wiki/Nisekoi_Yomeiri!%3F) was released for the PlayStation Vita on November 27, 2014. It was a Japan-only visual novel based on the manga and anime series Nisekoi.
The game can no longer be purchased digitally and must be dumped from a physical game card.

# The Files

The main files you'll need to worry about are pack/all.apk and pack/fs.apk. To access and extract them, you need an unencrypted dump of the game.
Once you have that, copy those two files to a secure location and **back them up**. Once you have them, move on.

# QuickBMS

QuickBMS is a general-purpose tool made by Luigi Auriemma that can be used to extract resources from certain games.
Using a script made for Artdink's Dragon Ball Z game, you can extract the game's resource files from all.apk and fs.apk.
You can download it [here](https://aluigi.altervista.org/quickbms.htm).
You will also need this [script](http://hl.altervista.org/split.php?http://www.aluigi.altervista.org/bms/dragon_ball_z_boz.bms).
Once you've extracted all.apk and fs.apk, *make backups of the resulting files*. Make your edits, and then use QuickBMS's reinsert function to put the edited files back into the .apk files.
NOTE: The files must be the same size or smaller than they were originally.

# fs.apk

This file contains the following folders:
+ eventscript
+ map_select
+ setup1
+ setup2
+ touchpart

*eventscript* contains another folder (scripts) which in turn contains around 600 .asb files. These files contain data used in the game's cutscenes
and hold the vast majority of its dialogue. It is important to note that all.apk also contains all of these files, but the ones in fs.apk are the ones
you will need to modify.

*map_select* contains a few nested folders, several .gxt textures (see below), and one .ark file.

*setup1* and *setup2* appear to have the same contents: each contains one folder named *gop* and another one named *setup*. *setup* contains
the splash textures that appear at boot (the Konami and Artdink logos, as well as the anti-piracy warning). These are in gxt format. The *gop* folder
contains .gop files, which hold most of the string data not found in the asb files.

*touchpart* contains a few .dat files. I have not managed to get into them.

# all.apk

This file contains a huge mess of files, including:
+ ASB files
  - These are compiled binary files containing cutscene information. You can view them with a hex editor, and edit the strings within in the same way, bearing in mind that the
start of each string must be at the same offset as it was when you started, and each string must end with a null character.
  - Alternatively, download the experimental editor from the releases section, which can somewhat overcome these limitations.
  - Every .asb file the game uses can be found in both all.apk and fs.apk, and you will need to put your edited files into both of them.
+ GOP files
  - These are also compiled binary files, containing data such as character names, anagram minigame data, the text in those bubble minigames,
the questions and answers for the quiz minigame, system text, and the texts that display when the stealth minigame starts.
  - To edit these, I have written a quick and dirty
tool that will not only edit the string data, but will move around the file offsets so that you can focus on translating. (For example, you should be able to fit a four-byte
string into a space that was previously three bytes, and the tool will accomodate that.)
  - Limitation: The file cannot be a single byte longer than it was! If you are one or two bytes over the limit, try removing some erroneous words.
  - Every .gop file the game uses can be found in both all.apk and fs.apk, but the ones in all.apk are the ones you want to edit.
+ GXT files
  - These are just standard PS Vita textures.
  - To edit these, you can use [Scarlet](https://github.com/xdanieldzd/Scarlet) to convert the .gxt into a .png.
  - Use GIMP to make your changes and then export the file as a .dds image.
  - When exporting, set the compression to match that of the original file. To find this information, open the .gxt in a hex editor and find the four bytes starting at 0x34, cross-referencing the [Vita Developer Wiki's page on GXT images](https://www.psdevwiki.com/vita/index.php?title=GXT). All of the images I have checked have used DXT1 compression if they didn't have transparency, and DXT5 compression if they did.
  - Use psp2gxt from the leaked SDK to turn your .dds into a .gxt.
  - Some .gxt files can be found in fs.apk, but the ones in all.apk are the ones you need to modify.
+ ARK Files
  - I have no clue what these are.
+ 2DC Files
  - Seem to contain sprites, but I haven't found a good way to extract them yet.
+ TBL Files
  - Contains plain-text information for stealth sections and cutscenes, but not enough to be useful.
+ AT9 Files
  - Contain sound effects. I haven't checked all of them yet, but the ones that play music seem to be kept outside of the .apk files, in the game's *bgm* directory.
+ AAC Files
  - Contain voice lines. You can just play these in VLC or whatever, and edit them with Audacity.
