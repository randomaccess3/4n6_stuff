# Sunday Funday Challenge
# http://www.hecfblog.com/2016/04/daily-blog-377-sunday-funday-41716.html
# Author: Phillip Moore
# Email: randomaccess3@gmail.com
# Blog: thisweekin4n6.wordpress.com

# InstallDFVFS
# version 0.05

# 0.01 - Initial commit
# 0.02 - Fix error in downloading x64 packages
# 0.03 - add comment for requiring version 1.57, adjusted python call to avoid path issues
# 0.04 - 1.57 of Archive::Zip isn't required, added additional code for dealing with unicode taken from perlmonks. This script needs Win32::Unicode, which occasionally fails the tests on install. Install using cpan -f Win32::Unicode.
# 0.05 - updated links

# This assumes that Python2.7 is installed

# TO DO:
# Check for crypto mispelling - I think this may have been fixed in the newly released version
# Check to see if Python is installed - not urgent
# SQLite Version/URL is hard linked and could be updated to automatically detect location of latest version
# Assumes no libraries have been installed - add section to detect if libraries installed are up to date or need to be uninstalled before the newer version is installed
# Add backports lzma download - tests are skipped (https://github.com/peterjc/backports.lzma)
# Cleanup subroutine redefinition

use utf8;
use Win32::Unicode();

use warnings;
use strict;
use WWW::Mechanize;
use version;
use Archive::Zip qw( :ERROR_CODES );

# ======================================================================================================
# Unicode Unzip Code taken from perlmonks
# http://perlmonks.org/?node_id=1113291
sub Archive::Zip::Archive::extractTree {
    package Archive::Zip::Archive;
    my $self = shift;

    my ( $root, $dest, $volume );
    if ( ref( $_[0] ) eq 'HASH' ) {
        $root   = $_[0]->{root};
        $dest   = $_[0]->{zipName};
        $volume = $_[0]->{volume};
    }
    else {
        ( $root, $dest, $volume ) = @_;
    }

    $root = '' unless defined($root);
    $dest = './' unless defined($dest);
    my $pattern = "^\Q$root";
    my @members = $self->membersMatching($pattern);

    foreach my $member (@members) {
        my $fileName = $member->fileName();           # in Unix format
        $fileName =~ s{$pattern}{$dest};    # in Unix format
                                            # convert to platform format:
        $fileName = Archive::Zip::_asLocalName( $fileName, $volume );
#~         ::dd( 'fileName' => $fileName );
        my $status = $member->extractToFileNamed($fileName);
        return $status if $status != AZ_OK;
    }
    return AZ_OK;
}

sub Archive::Zip::DirectoryMember::extractToFileNamed {
    package Archive::Zip::DirectoryMember;
    my $self    = shift;
    my $name    = shift;                                 # local FS name
    my $attribs = $self->unixFileAttributes() & 07777;
#~     ::dd( 'name' => $name );
#~     mkpath( $name, 0, $attribs );                        # croaks on error
#~     utime( $self->lastModTime(), $self->lastModTime(), $name );
    use Encode();
    $name = Encode::decode('UTF-8', $name );
    Win32::Unicode::mkpathW( $name ) or die "Cannot mkpathW( $name ): $!";
    Win32::Unicode::utimeW( $self->lastModTime(), $self->lastModTime(), $name );
    return AZ_OK;
}


sub Archive::Zip::Member::extractToFileNamed {
    package Archive::Zip::Member;
    my $self = shift;

    # local FS name
    my $name = ( ref( $_[0] ) eq 'HASH' ) ? $_[0]->{name} : $_[0];
    $self->{'isSymbolicLink'} = 0;

    # Check if the file / directory is a symbolic link or not
    if ( $self->{'externalFileAttributes'} == 0xA1FF0000 ) {
        $self->{'isSymbolicLink'} = 1;
        $self->{'newName'} = $name;
#~         ::dd( 'newName' => $name );
#~         my ( $status, $fh ) = _newFileHandle( $name, 'r' );
#~         my $retval = $self->extractToFileHandle($fh);
        my $fh = Win32::Unicode::File->new( '<', $name ); ## WHATEVER
        $fh->binmode;
        my $retval = $self->extractToFileHandle($fh);
        $fh->close();
    } else {
        #return _writeSymbolicLink($self, $name) if $self->isSymbolicLink();
        return _error("encryption unsupported") if $self->isEncrypted();
#~         
#~         ::dd( 'dirname' => dirname($name) );
#~         mkpath( dirname($name) );    # croaks on error
#~         my ( $status, $fh ) = _newFileHandle( $name, 'w' );
#~         return _ioError("Can't open file $name for write") unless $status;
#~         my $retval = $self->extractToFileHandle($fh);
#~         $fh->close();
#~         chmod ($self->unixFileAttributes(), $name)
#~             or return _error("Can't chmod() ${name}: $!");
#~         utime( $self->lastModTime(), $self->lastModTime(), $name );
#~         return $retval;

        use Encode();
        $name = Encode::decode('UTF-8', $name );
        my $dir = dirname($name);
        Win32::Unicode::mkpathW( $dir ) or die "Cannot mkpathW( $dir): $!";
        
        my $fh = Win32::Unicode::File->new( '>', $name )
            or return _ioError("Can't open file $name for write: $!");
        $fh->binmode;
        my $retval = $self->extractToFileHandle($fh);
        $fh->close();
        
        Win32::Unicode::utimeW( $self->lastModTime(), $self->lastModTime(), $name );
        return $retval;
    }
}
# If I already exist, extraction is a no-op.
sub Archive::Zip::NewFileMember::extractToFileNamed {
    package Archive::Zip::NewFileMember;
    my $self = shift;
    my $name = shift;    # local FS name
#~     if ( File::Spec->rel2abs($name) eq
#~         File::Spec->rel2abs( $self->externalFileName() ) and -r $name )
    if ( Win32::Unicode::Util::rel2abs($name) eq
         Win32::Unicode::Util::rel2abs( $self->externalFileName() )
         and Win32::Unicode::File->new( '<', $name )
    )
    {
        return AZ_OK;
    }
    else {
        return $self->SUPER::extractToFileNamed( $name, @_ );
    }
}


# Return an opened IO::Handle
# my ( $status, fh ) = _newFileHandle( 'fileName', 'w' );
# Can take a filename, file handle, or ref to GLOB
# Or, if given something that is a ref but not an IO::Handle,
# passes back the same thing.
sub Archive::Zip::_newFileHandle {
    package Archive::Zip;
    my $fd     = shift;
    my $status = 1;
    my $handle;

    if ( ref($fd) ) {
        if ( _ISA($fd, 'IO::Scalar') or _ISA($fd, 'IO::String') ) {
            $handle = $fd;
        } elsif ( _ISA($fd, 'IO::Handle') or ref($fd) eq 'GLOB' ) {
            $handle = IO::File->new;
            $status = $handle->fdopen( $fd, @_ );
        } else {
            $handle = $fd;
        }
    } else {
#~         $handle = IO::File->new;
#~         $status = $handle->open( $fd, @_ );
        my( $mode ) = @_;
        my $name = Encode::decode('UTF-8', $fd );
        $handle = Win32::Unicode::File->new( $mode, $name ) or do { $status = $!; };
    }

    return ( $status, $handle );
}
#=========================================================================================








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
	system('C:\python27\python.exe -c "import sqlite3; print sqlite3.sqlite_version" > sqliteversion.temp');
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
		system ('C:\python27\python.exe -c "import platform; str = platform.architecture()[0]; print str[0]+str[1]" > pythonarch.temp');
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
my $filename;

system ('C:\python27\python.exe -c "import platform; str = platform.architecture()[0]; print str[0]+str[1]" > pythonarch.temp');
my $pythonarch = "x".readTemp("pythonarch.temp");		
print "\nPython Architecture is $pythonarch\n";
				
#download sha256sums to determine latest version of each package
my $packageURL;
$packageURL = "https://github.com/log2timeline/l2tbinaries/raw/master/win32" if ($pythonarch eq "x32");
$packageURL = "https://github.com/log2timeline/l2tbinaries/raw/master/win64" if  ($pythonarch eq "x64");	
my $packagelisting = "SHA256SUMS";

#print "$packageURL\n";

downloadFile($packagelisting, $packageURL);

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
my $testsDirectory = "dfvfs-master";
downloadFile($testsArchive, "https://github.com/log2timeline/dfvfs/archive");

print "Extracting DFVFS\n";

my $zip     = Archive::Zip->new();
my $zipName = $testsArchive;
my $zip_status  = $zip->read($zipName);
die "Read of $zipName failed\n" if $zip_status != AZ_OK;

$zip->extractTree();


#my $zip = Archive::Zip->new();
#die 'read error' unless ( $zip->read( $testsArchive ) == AZ_OK );
#$zip->extractTree( '', $testsDirectory );

# The tests will fail if you dont run them from the directory that run_tests.py is in
# For future reference this is why: https://stackoverflow.com/questions/7009055/how-do-i-cd-into-a-directory-using-perl
chdir($testsDirectory) or die "$!";
system('C:\python27\python.exe "run_tests.py"');
	
print "\n You're good to go if the tests all say OK!\n";
