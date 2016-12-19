# Perl script to wrap regripper 2.8 in a GUI
# Run from regripper folder

#INSTALL
#This will work on Perl32bit, on 64bit you will need to compile the GUI libraries yourself, which I've had trouble with.

#Run on perl v22
# ppm install dmake
# ppm install Parse-Win32Registry 	# to install Win32Registry required to run regripper
# ppm install Win32-GUI 			# to install Win32-GUI required to run this script
 
# Known Issues:
# Tabbing currently hasn't been implemented

use Win32::GUI;
use POSIX qw(strftime);
use strict;
use File::Spec;
use Cwd;

#use Parse::Win32Registry qw(:REG_);
#use Getopt::Long;


my $VERSION = "0\.01";
my $TITLE = "RegRipper Runner";
my %plugins = {};
my $plugindir = File::Spec->catfile("plugins");

my @allHives = ("NTUSER.dat", "USRCLASS.dat", "SYSTEM", "SAM", "SECURITY", "SOFTWARE", "Amcache"); 
my @alerts = ();

my $linesprinted = 0;
my $printFlag = 0;




#=======================================================
# GUI LAYOUT VARIABLES
#=======================================================

#General
my $buttonLength = 50;
my $buttonHeight = 25;
my $leftSideMargain = 40;
my $inputBox_Height = 22;


#View Plugin Window
my $viewPlugin_Window_X 				= 40;
my $viewPlugin_Window_Y 				= 40;
my $viewPlugin_Window_MaxWidth 			= 300;
my $viewPlugin_Window_MaxHeight 		= 500;
my $viewPlugin_Window_Width 			= $viewPlugin_Window_MaxWidth;
my $viewPlugin_Window_Height 			= $viewPlugin_Window_MaxHeight;
my $viewPlugin_pluginWindowTextField_X 	= 10; 
my $viewPlugin_pluginWindowTextField_Y 	= 10;
my $viewPlugin_pluginWindowTextField_Height = 30;
my $viewPlugin_pluginWindowTextField_Width	= 30;




#Main Window
my $main_Window_X 			= 0;
my $main_Window_Y 			= 0;
my $main_Window_MaxWidth 	= 1000;
my $main_Window_MaxHeight 	= 700;
my $main_Window_Width 		= $main_Window_MaxWidth;
my $main_Window_Height 		= $main_Window_MaxHeight;

#Registry Box
my $registryTextField_Y 			= 15;
my $registryTextField_X 			= $leftSideMargain+90;
my $registryTextField_Width 		= 500;
my $registryTextField_Height 		= $inputBox_Height;

#Report Box
my $reportTextField_Y 				= $registryTextField_Y+50;
my $reportTextField_X 				= $leftSideMargain+90;
my $reportTextField_Width 			= $registryTextField_Width;
my $reportTextField_Height 			= $inputBox_Height;

#Output Text Field
my $outputWindowTextField_Width 	= 475;
my $outputWindowTextField_Height 	= 650;
my $outputWindowTextField_X 		= 280;
my $outputWindowTextField_Y 		= 110;

#Plugin List
my $pluginList_X 					= $leftSideMargain;
my $pluginList_Y 					= $outputWindowTextField_Y;
my $pluginList_Width 				= 200;
my $pluginList_Height 				= 300;

# User Text Field Label
my $userTextField_Label_X			= $registryTextField_X+$registryTextField_Width+100;
my $userTextField_Label_Y 			= $registryTextField_Y+3;

# Computer Text Field Label
my $space = 10;
my $computerTextField_Label_X		= $userTextField_Label_X;
my $computerTextField_Label_Y 		= $userTextField_Label_Y + $space + $inputBox_Height;

# User Text Field
my $userTextField_Width 			= 120;
my $userTextField_Height 			= $inputBox_Height;
my $userTextField_X					= $userTextField_Label_X+80;
my $userTextField_Y					= $userTextField_Label_Y;

# Computer Text Field
my $computerTextField_Width 		= $userTextField_Width;
my $computerTextField_Height 		= $inputBox_Height;
my $computerTextField_X				= $userTextField_Label_X+80;
my $computerTextField_Y				= $computerTextField_Label_Y;

#ConvertTime CheckBox Label
my $convertTimeCheckBox_Label_X 	= $userTextField_Label_X;
my $convertTimeCheckBox_Label_Y 	= $computerTextField_Y+30;

#ConvertTime CheckBox
my $convertTimeCheckBox_Width 		= 15;
my $convertTimeCheckBox_Height 		= $convertTimeCheckBox_Width;
my $convertTimeCheckBox_X			= $userTextField_X+0;
my $convertTimeCheckBox_Y			= $convertTimeCheckBox_Label_Y;

#Buttons
my $addToReportButton_X				= $leftSideMargain;
my $addToReportButton_Y				= $pluginList_Y + $pluginList_Height + 10;
my $addToReportButton_Width			= $buttonLength;
my $addToReportButton_Height		= $buttonHeight;

my $browseRegistryButton_X 			= $leftSideMargain;
my $browseRegistryButton_Y 			= $registryTextField_Y;
my $browseRegistryButton_Width 		= $buttonLength;
my $browseRegistryButton_Height 	= $buttonHeight;

my $browseReportButton_X 			= $leftSideMargain;
my $browseReportButton_Y 			= $reportTextField_Y;
my $browseReportButton_Width 		= $buttonLength;
my $browseReportButton_Height 		= $buttonHeight;






# ---------------------------------
# Menu Bar
# ---------------------------------
my $pwd = "explorer \"".cwd()."\"";
#replace "/" with "\"
$pwd =~ s/\//\\/g;

my $menu = Win32::GUI::MakeMenu(
		"&File"                => "File",
			" > O&pen RR"          => { -name => "OpenRRFolder", -onClick => sub {system (qq{$pwd})}},
		#	" > -"                 => 0,
			" > E&xit"             => { -name => "Exit", -onClick => sub {exit 1;}},
		"&Help"                => "Help",
			" > &About"            => { -name => "About", -onClick => \&aboutBox},
);

# Create Main Window
my $main = new Win32::GUI::Window (
    -name     => "Main",
    -title    => $TITLE." v.".$VERSION,
    -pos      => [$main_Window_X, $main_Window_Y],
# Format: [width, height]
    -maxsize  => [$main_Window_MaxWidth, $main_Window_MaxHeight],
    -size     => [$main_Window_Width, $main_Window_Height],
    -menu     => $menu,
    -dialogui => 1,
) or die "Could not create a new Window: $!\n";

my $icon_file = "q\.ico";
my $icon = new Win32::GUI::Icon($icon_file);
$main->SetIcon($icon);

#----------------------------------------------------------------------------------------
# MAIN WINDOW
#----------------------------------------------------------------------------------------	
# Report box (right side)

my $outputWindow = $main->AddTextfield(
    -name      		=> "Report",
    -pos       		=> [$outputWindowTextField_X,$outputWindowTextField_Y],
    -size      		=> [$outputWindowTextField_Height,$outputWindowTextField_Width],
    -multiline 		=> 1,
    -vscroll   		=> 1,
	-hscroll   		=> 1,
	-autohscroll 	=> 1,
	-readonly		=> 1,
    -keepselection 	=> 1,
    #-tabstop 		=> 1,
	-foreground => "#000000",
    -background => "#FFFFFF"
);

$outputWindow->MaxLength(0);
	
my $registryLocation = $main->AddTextfield(
    -name     	=> "registryLocation",
	-pos		=> [$registryTextField_X, $registryTextField_Y],
	-size		=> [$registryTextField_Width, $registryTextField_Height],
    #-tabstop  	=> 1,
    -foreground => "#000000",
    -background => "#FFFFFF"
);

my $reportLocation = $main->AddTextfield(
    -name     	=> "reportLocation",
	-pos		=> [$reportTextField_X, $reportTextField_Y],
	-size		=> [$reportTextField_Width, $reportTextField_Height],
    #-tabstop  	=> 1,
    -foreground => "#000000",
    -background => "#FFFFFF"
);
	
	
my $pluginList = $main->AddListbox(
	-name   	=> "pluginList",
	-pos		=> 	[$pluginList_X,$pluginList_Y],
	-size		=>	[$pluginList_Width,$pluginList_Height],
	-vscroll   	=> 1,
	#-tabstop	=> 1
);

$main->AddLabel(
    -text   => "User:",
	-pos	=> [$userTextField_Label_X,$userTextField_Label_Y]
);
	
my $field_user = $main->AddTextfield(
    -name   => "user",
	-pos	=> [$userTextField_X,$userTextField_Y],
	-size	=> [$userTextField_Width,$userTextField_Height]
);

$main->AddLabel(
    -text   => "Computer:",
	-pos	=> [$computerTextField_Label_X,$computerTextField_Label_Y]
);
	
my $field_computer = $main->AddTextfield(
    -name   => "computer",
	-pos	=> [$computerTextField_X,$computerTextField_Y],
	-size	=> [$computerTextField_Width,$computerTextField_Height]
);

$main->AddLabel(
    -text   => "Convert Time:",
	-pos	=> [$convertTimeCheckBox_Label_X,$convertTimeCheckBox_Label_Y]
);
	
my $convertTime = $main->AddCheckbox(
	-name 	=> 'convertTimeCheckBox',
	-pos	=> [$convertTimeCheckBox_X,$convertTimeCheckBox_Y],
	-size	=> [$convertTimeCheckBox_Width,$convertTimeCheckBox_Height],
	#-tabstop  => 1
	);

#Buttons
my $addToReport = $main->AddButton(
	-name => 'addToReport',
	-pos	=> [$addToReportButton_X, $addToReportButton_Y],
	-size	=> [$addToReportButton_Width, $addToReportButton_Height],
	#-tabstop => 1,
	-text => "+"
	);

my $browse_registry = $main->AddButton(
	-name => 'browse_registry',
	-pos	=> [$browseRegistryButton_X, $browseRegistryButton_Y],
	-size	=> [$browseRegistryButton_Width, $browseRegistryButton_Height],
	#-tabstop  => 2,
	-text => "Registry:");
	
my $browse_report = $main->AddButton(
	-name => 'browse_report',
	-pos	=> [$browseReportButton_X, $browseReportButton_Y],
	-size	=> [$browseReportButton_Width, $browseReportButton_Height],
	#-tabstop  => 1,
	-text => "Report:");


	
my $status = new Win32::GUI::StatusBar($main,
		-text  => $TITLE." v.".$VERSION." opened\.",
);
	
	
populatePluginsList();

$main->Show();
Win32::GUI::Dialog();


#=======================================================
# User Actions
#=======================================================


sub addToReport_Click{
	#copy contents of report to $reportTab
	if ($reportLocation->Text() eq ""){
		$status->Text("No report file");
		return;
	}
	
	my $outputfile = $reportLocation->Text();
	my $text = $outputWindow->Text;

	$text =~ s/\n\n/\r\n/g;
	open(FILE, '>>', $outputfile) or die "cannot open file $outputfile";
	print FILE $text;	
	print FILE "\n";
	close(FILE);
	$status->Text("Save complete"); 
}

sub browse_registry_Click {
  # Open a file
  my $folder = Win32::GUI::BrowseForFolder (
                   -owner  => $main,
                   -title  => "Open a Folder",
                   -filter => ['All files' => '*.*',],
				   );
  
  print $registryLocation->Text($folder);
  print $reportLocation->Text($folder."\\report.txt");
  0;
}

sub browse_report_Click {
	# Open a file
	my $file = Win32::GUI::GetSaveFileName(
                   -owner  => $main,
                   -title  => "Save a report file",
                   -filter => [
                       'Report file (*.txt)' => '*.txt',
                       'All files' => '*.*',
                    ],
                   );
  
 	$file = $file."\.txt" unless ($file =~ m/\.\w+$/i);
	$reportLocation->Text($file);
	0;
}

sub clearoutputWindow(){
	$outputWindow->Text("");
}

sub pluginList_SelChange {
	$linesprinted = 0;
	my $selection =  $pluginList->GetText($pluginList->SelectedItem());   
	my $regPath = $registryLocation->Text(); 
	my $endLine = "--------------------------------------------------------------------------------------------------------------------------------------------------------------------"."\n";
	#print $selection." - ". $plugins{$selection}{"description"}."-".$plugins{$selection}{"hive"}."\n";
	
	clearoutputWindow();
	$status->Text($selection." - ". $plugins{$selection}{"description"}."\n");
	
	if ($regPath ne ""){		
		if ($plugins{$selection}{"hive"} =~ m/[aA][lL][lL]/){
			#If plugin runs on all hives then iterate across all available hives
			foreach my $h (@allHives){
				$outputWindow->Append("Running $selection plugin over $h\n");
				runPluginRip($selection, $regPath."\\".$h);
				#runPlugin($selection, $regPath."\\".$h);
				$outputWindow->Append($endLine);
			}
		}	
		else{
			foreach my $p_hive (split (/\,/, $plugins{$selection}{"hive"})){ #this is for hash entries with multiple hives
				$p_hive =~ s/ //g;
				my $hive = $regPath."\\".$p_hive;
				runPluginRip($selection, $hive);
				#runPlugin($selection, $hive);
				$outputWindow->Append($endLine);
			}
		}
		#$outputWindow->Append("Print requirements for $selection, $plugins{$selection}{\"hive\"}\n");
	}
	
	#Reset horizontal scroll to position 1
	#Not sure how to reset the vertical scroll
	#my @sel =$outputWindow->GetSel();
	#$outputWindow->SetSel(@sel);
	$outputWindow->SetSel(0,0);
	$outputWindow->ScrollCaret();
	$outputWindow->SetFocus();
	$pluginList->SetFocus();
	return;
}


#------------------------------------------------------------------------
# About box
#------------------------------------------------------------------------

sub aboutBox {
  my $self = shift;
  $self->MessageBox(
     $TITLE.", v.".$VERSION."\r\n".
     "GUI for Regripper\r\n"
  );
  0;
}


#=======================================================
# Application component
#=======================================================

#-----------------------------------------------------------
# get a list of plugins files from the plugins dir and populates the plugins hash
#-----------------------------------------------------------

sub populatePluginsList {
	opendir(DIR,$plugindir) || die "Could not open $plugindir: $!\n";
	my @allPlugins = readdir(DIR);
	my @profiles;
	closedir(DIR);
	
	#my @tlnPlugins;
	
	foreach my $p (@allPlugins) {
		#skip . and ..
		next if ($p =~ m/^\.$/ || $p =~ m/^\.\.$/);		
		
		#Only continue for files with .pl extension
		next unless ($p =~ m/\.pl$/);
	
		my $pkg = (split(/\./,$p,2))[0];
		$p = File::Spec->catfile($plugindir,$p);	
		
		#check if plugin has _tln in the title
		#	if ($p =~ m/.*_tln/){
		#		push @tlnPlugins, $p;
		#		next
		#	}
		
		eval {
			require $p;
			$plugins{$pkg}{"hive"} = $pkg->getHive();
			$plugins{$pkg}{"version"} = $pkg->getVersion();
			$plugins{$pkg}{"description"}   = $pkg->getShortDescr();
			$pluginList->InsertItem($pkg);
		};
		print "Error: $@\n" if ($@);
	}

	return;
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

sub populateRegistry {
	my $directory = shift;
	my @reg;
	open(DIR, $directory);
	my @files = readdir(DIR);
	close(DIR);
	
	foreach my $f (@files) {
		if ($f =~ m/SAM$/ || $f =~ m/SYSTEM$/ || $f =~ m/SOFTWARE$/ || $f =~ m/SECURITY$/ || $f =~ m/NTUSER.DAT$/ || $f =~ m/USRCLASS.DAT$/){
			push(@reg,$f)
		}
	}	
}

#Runs the original rip.pl program instead of internally running the plugin
sub runPluginRip($$){
	my $regPath = $registryLocation->Text();
	my $pluginSelected = shift;
	my $hive = shift;
	my $outputFile = "output.temp";
	
	$printFlag = 0;
	my $status_command = "perl rip.pl -r \"".$hive."\" -p ".$pluginSelected;
	my $run_command = $status_command."> $outputFile";
	$status->Text("Running command: ".$status_command);
	$outputWindow->Append("Running command: ".$status_command);
	$outputWindow->Append("\n");
		
	#If hive exists, write output temp file and then read it back into the rip window
	if (-e $hive){
		my $pluginfile = $plugindir."\\".$pluginSelected."\.pl";
		
		eval {
			require $pluginfile;
			
			system (qq{$run_command});
		};
		
		#read through temp file and print to outputWindow
		
		my $line;
		open(my $fh, '<', $outputFile) or die "cannot open file $outputFile";
		while ($line = <$fh>){
		
			#adds in the computer and user fields if TLN plugins are run. 
			#Also the option to convert the time into a more human readable format if the option is selected
			if (($field_computer || $field_user) && $pluginSelected =~ m/_tln$/){
				#print "Computer:".$field_computer->Text()."\n";
				#print "User:".$field_user->Text()."\n";
				
				my @vals = split(/\|/,$line,5);
		
				$vals[0] = gmtime($vals[0]) if ($convertTime->GetCheck() == 1);
				$vals[2] = $field_computer->Text() if ($vals[2] eq "");
				$vals[3] = $field_user->Text() if ($vals[3] eq "");

				my $str = $vals[0]."|".$vals[1]."|".$vals[2]."|".$vals[3]."|".$vals[4];
				
				#my $str = $vals[0]."|".$vals[1]."|".$field_computer->Text()."|".$field_user->Text()."|".$vals[4];
				$outputWindow->Append($str."\n");
			}
			else{
				$outputWindow->Append($line."\n");
			}
		}
		close($fh);
		
		$status->Text("Rip complete - Command: ".$status_command);
	}
	else{
		$outputWindow->Append("$hive doesn't exist\n");
	}
}
