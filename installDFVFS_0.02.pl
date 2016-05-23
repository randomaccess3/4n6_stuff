# Sunday Funday Challenge
# http://www.hecfblog.com/2016/04/daily-blog-377-sunday-funday-41716.html
# Author: Phillip Moore
# Email: randomaccess3@gmail.com
# Blog: thisweekin4n6.wordpress.com

# InstallDFVFS
# version 0.01

# 0.01 - Initial commit
# 0.02 - Fix error in downloading x64 packages

# This has only been tested on my machine so far, so I've gotten it to work at least once!
# This assumes that Python2.7 is installed

# Tests pass, except fail on some IO calls and the existance of xedmynd.dd 

# TO DO:
# Check for crypto mispelling - I think this may have been fixed in the newly released version
# Check to see if Python is installed - not urgent
# SQLite Version/URL is hard linked and could be updated to automatically detect location of latest version
# Assumes no libraries have been installed - add section to detect if libraries installed are up to date or need to be uninstalled before the newer version is installed
# Add backports lzma download - tests are skipped (https://github.com/peterjc/backports.lzma)

use warnings;
use strict;
use WWW::Mechanize;
use version;
use Archive::Zip qw( :ERROR_CODES );


#Unzips an archive to a single folder (doesn't work well for archives with folders)
sub unzipArchive($$){
	my $zipname = shift;
	my $destinationDirectory = shift;
	my $zip = Archive::Zip->new($zipname);
	
	#$zip->extractTree( $zipname, $destinationDirectory );
	
	foreach my $member ($zip->members){
		next if $member->isDirectory;
		(my $extractName = $member->fileName) =~ s{.*/}{};
		$member->extractToFileNamed($extractName);
		}
}

#Reads a one line temp file and returns the result
sub readTemp($){
	my $temp = shift;
	my $line;
	open(my $fh, '<', $temp) or die "cannot open file $temp";
	{
			local $/;
			$line = <$fh>;
	}
	close($fh);
	chomp $line;
	return $line;
}

#Checks if the SQLite Version is correct, otherwise downloads a version and installs.
# This version is hard linked so would have to be adjusted when updated
sub checkSQLiteVersion(){

	system('C:\python27\python -c "import sqlite3; print sqlite3.sqlite_version" > sqliteversion.temp');
	my $sqtemp = "sqliteversion.temp";
	my $sqliteversion = readTemp($sqtemp);

	print "You are currently running sqlite version $sqliteversion in Python\n";

	if ( version->parse($sqliteversion) >= version->parse("3.7.8") ) {
		print "You don't need to upgrade to continue\n";
		return 0;
	}
	else{
		print "This will need to be upgraded, I'll start the download and install process now\n";
		
		my $sqlite_zip;
		my $sqlite_URL;
		system ('python -c "import platform; str = platform.architecture()[0]; print str[0]+str[1]" > pythonarch.temp');
		my $pythonarch = "x".readTemp("pythonarch.temp");		
		print "\nPython Architecture is $pythonarch\n";

		if ($pythonarch eq "x64"){
			$sqlite_zip = "sqlite-dll-win64-x64-3130000.zip";
			$sqlite_URL = "https://www.sqlite.org/2016";
		}
		else { #download 32
			$sqlite_zip = "sqlite-dll-win32-x86-3130000.zip";
			$sqlite_URL = "https://www.sqlite.org/2016";
		}
		
		downloadFile($sqlite_zip, $sqlite_URL);
		unzipArchive($sqlite_zip, "");
		system('copy C:\Python27\DLLS\sqlite3.dll C:\Python27\DLLS\sqlite3.dll.old');
		system('copy sqlite3.dll C:\Python27\DLLS\sqlite3.dll');		
	}
	return 1;
}

#--------------------------------------------------------------------------------------------------------------
# Downloads a given file from a path
# ie downloadFile(index.html, www.google.com)
#--------------------------------------------------------------------------------------------------------------
  
sub downloadFile($$){
	my $filename = shift;
	my $path = shift;

	if (-e $filename){
		print "$filename exists and will not be downloaded\n";
	}
	else{
		my $url = $path.'/'.$filename;
		print "Downloading $url\n";
		my $mech = WWW::Mechanize->new();
			$mech->get("$url");
			$mech->save_content($filename);
	}
	return;
}


#--------------------------------------------------------------------------------------------------------------
# MAIN
#--------------------------------------------------------------------------------------------------------------

system ('python -c "import platform; str = platform.architecture()[0]; print str[0]+str[1]" > pythonarch.temp');
my $pythonarch = "x".readTemp("pythonarch.temp");		
print "\nPython Architecture is $pythonarch\n";
				
#download sha256sums to determine latest version of each package
my $packageURL;
$packageURL = "https://raw.githubusercontent.com/log2timeline/l2tbinaries/master/win32" if ($pythonarch eq "x32");
$packageURL = "https://raw.githubusercontent.com/log2timeline/l2tbinaries/master/win64" if  ($pythonarch eq "x64");	
my $filename = "SHA256SUMS";

#print "$packageURL\n";

downloadFile($filename, $packageURL);

my $packagelisting = "SHA256SUMS";
print "Reading Package List\n";
#split up SHA256SUMS into hash
my %packages;
die "Usage: $packagelisting FILENAMEs\n" if $packagelisting eq "";
open my $fh, '<:encoding(UTF-8)', $packagelisting or die;
	while (my $line = <$fh>) {
		my ($sha1, $packagename) = split /  /, $line;
		chomp $sha1; chomp $packagename;
        $packages{$packagename} = $sha1;
		#print "$packagename, $sha1\n"
    }

#Determine the latest version of each of the required binaries (added dfdatetime and fwnt which was not in the original list)
# potentially download dfvfs first then parse the output of the run_test.py script to determine what needs to be downloaded

my @required_binaries = ('dfdatetime', 'libfwnt', 'six', 'construct', 'protobuf', 'pytsk3', 'pybde', 'pyewf', 'pycrypto', 'libqcow', 'libsigscan', 'libsmdev', 'libsmraw', 'libvhdi', 'libvmdk', 'libvshadow', 'libfsntfs', 'libvslvm', 'dfvfs');
my @download;
my @keys = keys %packages;
#This section does a regex match in the list of binary names from the SHA256SUMS file
foreach my $rb (@required_binaries){
	foreach my $k (@keys){
		if($k =~ m/^$rb.*/ ){
			push @download, $k;
		}
	}
}

print "\n";
print "------------------------------------------------------------------------\n";
print "Downloading packages\n";
print "------------------------------------------------------------------------\n";


#download l2tbinaries from https://github.com/log2timeline/l2tbinaries
foreach $filename (@download){
    downloadFile($filename, $packageURL);
}

print "\n";
print "------------------------------------------------------------------------\n";
print "Installing packages\n";
print "------------------------------------------------------------------------\n";


my $dfvfs = pop @download;


#check 

foreach $filename (@download){
	print "Installing $filename\n";
	system("msiexec /i $filename -q");
	sleep 5; #this sleep has been added to ensure one installer doesn't try to start before the previous has finished
}


#check that crypto is "Crypto" - This does not appear to be an issue with the current version of Crypto
#if cryptoFolder eq "crypto"{
# rename to "Crypto";
#}


print "\n";
print "------------------------------------------------------------------------\n";
print "Checking Python SQLite Library\n";
print "------------------------------------------------------------------------\n";

#keeps checking until python 2.7 has been updated
while (checkSQLiteVersion()){

}

print "\n";
print "------------------------------------------------------------------------\n";
print "Installing DfVFS\n";
print "------------------------------------------------------------------------\n";

#Install DFVFS
	print "Installing $dfvfs\n";
	system("start $dfvfs -q");


print "\n";
print "------------------------------------------------------------------------\n";
print "Download and Run Tests\n";
print "------------------------------------------------------------------------\n";
my $testsArchive = "master.zip";
my $testsDirectory = "dfvfs/";
downloadFile($testsArchive, "https://github.com/log2timeline/dfvfs/archive");

print "Extracting DFVFS\n";
my $zip = Archive::Zip->new();
die 'read error' unless ( $zip->read( $testsArchive ) == AZ_OK );
$zip->extractTree( '', $testsDirectory );
# The tests will fail if you dont run them from the directory that run_tests.py is in
# For future reference this is why: https://stackoverflow.com/questions/7009055/how-do-i-cd-into-a-directory-using-perl
chdir('dfvfs\\dfvfs-master\\') or die "$!";
system('python "run_tests.py"');
	
print "\n You're good to go if the tests all say OK!\n";