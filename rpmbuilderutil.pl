#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;
use File::Basename;
use File::Copy;
use File::Find;
use JSON qw(decode_json);
use Cwd qw(abs_path);

my $configfile   = "build.json";
my $verbose      = 0;
my $help         = 0;
my $basepath     = "./";
my $version      = "1.0.0"; 
my $rpmworkspace = ".rpmbuilder/";
my $rpmbuildexec = "rpmbuild";
my $rpmoutput    = "./"; 
my $target       = "";

GetOptions(
    "config=s"   => \$configfile,
    "basepath=s" => \$basepath,
    "rpmbuild=s" => \$rpmworkspace,
    "verbose"    => \$verbose,
    "help"       => \$help,
    "version=s"  => \$version,
    "rpmout=s"   => \$rpmoutput,
    "target=s"   => \$target
) or die("Error in command line arguments\n");

show_usage() if ($help);

$basepath     = abs_path($basepath);
$rpmoutput    = abs_path($rpmoutput);

$rpmworkspace =~ s/([^\/])$/$1\//;
$basepath     =~ s/([^\/])$/$1\//;
$rpmoutput    =~ s/([^\/])$/$1\//;

die("Configuration file '$configfile' did not exist") unless (-e $configfile);
print("Configuration $configfile\n") if $verbose;

die("RPM output path '$rpmoutput' is not a dir or did not exist") unless (-d $rpmoutput);
print("RPM output $rpmoutput\n") if $verbose;

my @config_list;
my $rpm_config  = load_json_file($configfile);

if (ref($rpm_config) eq "HASH") {
    push(@config_list, $rpm_config);        
} else {
    @config_list = @{$rpm_config};
}

foreach my $config (@config_list) {
    my $lookup = {
        "VERSION" => $version,
        "RELEASE" => "1",
        "LICENSE" => "none",
        "GROUP"   => "Utilities",
        "URL"     => "none",
        "TARGET"  => "development"
    };  
    
    create_lookup_map($lookup, $config);
    my $pkgPath = create_rpm_workspace($rpmworkspace, $lookup);    
    prepare_files($pkgPath, $lookup, $config);    
    my $specPath = create_rpm_spec($rpmworkspace, $lookup, $config);
    run_rpm_build($rpmworkspace, $specPath);
    copy_rpm($rpmoutput, $rpmworkspace, $lookup);
    delete_rpm_workspace($rpmworkspace);    
}

sub show_usage {
    print("rpmbuilder.pl --config=<configfile>\n");
    print("config=s\t\tConfiguration file\n");
    print("basepath=s\t\tProject basepath\n");
    print("rpmbuild=s\t\tRPM build workspace\n");
    print("rpmout=s\t\tRPM output folder\n");
    print("verbose\t\t\tSet verbose output\n");
    print("target=s\t\t\tSet default target\n");
	print("version=s\t\t\tSet version\n");
    print("help\t\t\tShow usage message\n");
    exit(0);
}

sub create_rpm_workspace {
    my $path   = shift;
    my $lookup = shift;
    
    die("RPM workspace '$path' already exists. Will not be deleted!") if (-e $path);    
    die("Can't create RPM workspace '$path'") unless mkdir($path);        
        
    my @folders = (
        "RPMS",
        "SRPMS",
        "BUILD",
        "SOURCES",
        "SPECS",
        "BUILDROOT",
        "tmp"        
    );
    
    my $packagePath = "BUILDROOT/" . $lookup->{"RPM"};
    push(@folders, $packagePath);
    
    foreach (@folders) {
        my $subpath = "${path}${_}";
        mkdir($subpath) or die("Can't create workspace sub folder '$subpath'");
    }
    
    return abs_path($path . $packagePath);
}

sub delete_rpm_workspace {
    my $path = shift;
    die("Can't delete RPM workspace '$path' exit($?)") if (system('rm', '-r', $path)); 
}

sub create_rpm_spec {
    my $path     = shift;
    my $lookup   = shift;
    my $config   = shift;    
    my $specdata = "";
    my $filepath = "${path}/SPECS/generic.spec";
    
    open(SPEC, ">", $filepath);
    print(SPEC create_spec($lookup, $config));
    close(SPEC);

    return $filepath;
}

sub get_spec_requirement {
    my $config  = shift;
    my $require = "";
    
    return undef unless (exists($config->{"require"}));
    
    foreach (keys %{$config->{"require"}}) {
        my $key   = $_;
        my $value = $config->{"require"}->{$key};        
        $require .= "," if (length($require));
        
        $value =~ s/([<>=]+)([^\s])/$1 $2/g;
        
        if ($value eq "*") {
            $require .= $key;
        } else {
            $require .= $key . " " . $value;
        }        
    }
    
    return $require;
}

sub get_spec_script_hook {
    my $config  = shift;
    my $hook    = shift;
    my $script  = "";
    
    return undef unless (exists($config->{$hook}));
    
    foreach (@{$config->{$hook}}) {
        $script .= $_ . "\n";
    }
    
    return $script;
}

sub create_spec {
    my $lookup   = shift;
    my $config   = shift;
    
    my $spec = "" 
        . "Summary: {NAME} binary package\n"
        . "Name: {NAME}\n"
        . "Version: {VERSION}\n"
        . "Release: {RELEASE}\n"
        . "License: {LICENSE}\n"
        . "Group: {GROUP}\n"
        . "URL: {URL}\n";
        
    my $requires = get_spec_requirement($config);    
    $spec .= "Requires: $requires\n" if ($requires && length($requires));            
        
    $spec .= "\n"
        . "%description\n{DESCRIPTION}\n\n"
        . "%files\n";
        
    foreach (@{$lookup->{"FILES"}}) {
        $spec .= "$_\n";
    } 
        
    my $scripthook = get_spec_script_hook($config, "preinstall");    
    $spec .= "%pre\n$scripthook" if ($scripthook && length($scripthook));    
        
    $scripthook = get_spec_script_hook($config, "postinstall");    
    $spec .= "%post\n$scripthook" if ($scripthook && length($scripthook));        
        
    $scripthook = get_spec_script_hook($config, "preuninstall");    
    $spec .= "%preun\n$scripthook" if ($scripthook && length($scripthook));    
        
    $scripthook = get_spec_script_hook($config, "postuninstall");    
    $spec .= "%postun\n$scripthook" if ($scripthook && length($scripthook));                                            
        
    $spec .= "\n";        
    $spec = lookup_replace($lookup, $spec);
        
    return $spec;
}

sub lookup_replace {
    my $lookup = shift;
    my $data   = shift;
    
    foreach my $key (keys(%{$lookup})) {
        $data =~ s/{$key}/$lookup->{$key}/g;
    }
    
    return $data;
}

sub create_lookup_map {
    my $lookup = shift;
    my $config = shift;
    chomp(my $arch = `uname -m`);
    $lookup->{"VERSION"} = $version;
    $lookup->{"RELEASE"} = "1";
    $lookup->{"TARGET"}  = "";
    $lookup->{"ARCH"}    = $arch;
    $lookup->{"FILES"}   = [];
    $lookup->{"TARGET"}  = $target;
        
    foreach my $key (keys(%{$config})) {
        if (ref($config->{$key}) eq "ARRAY") {
            next;
        }
        
        $lookup->{uc($key)} = $config->{$key};                
    }
        
    foreach my $key1 (keys(%{$lookup})) {
        $lookup->{$key1} = lookup_replace($lookup, $lookup->{$key1});
    }    
}

sub prepare_files {
    my $path       = shift;
    my $lookup     = shift;
    my $config     = shift;
    my $sourcepath = $basepath;
    
    my $files = $config->{'files'};
    die("Package contains zero files") if (@$files == 0);    
    
    foreach my $file (@{$files}) {
        copy_file($path, $lookup, $sourcepath, $file);
    }
}

sub copy_file {
    my $destpath   = shift;
    my $lookup     = shift;
    my $sourcepath = shift;    
    my $file       = shift;
    
    my @requiredKeys = ("destination","type","mode","source");
    foreach (@requiredKeys) {
        die("Missing file.$_ property") unless (exists($file->{$_}));
    }    
    
    $sourcepath .= lookup_replace($lookup, $file->{"source"});    
    die("Source '$sourcepath' did not exist") unless (-e $sourcepath);
    
    my $rel_dest = lookup_replace($lookup, $file->{"destination"}); 
    $destpath   .= $rel_dest; 
    die("Destination '$destpath' can not be terminated by '\/' character") if ($destpath =~ m/\/$/);
    
    if ($file->{"type"} eq "file") {
        my $dirname = dirname($destpath);
        my $mkdirout = `mkdir -p "$dirname" 2>&1`;
        die("Can't create destination path '$dirname' $mkdirout") if ($?);            
        my $perm = $file->{"mode"};
        my $installout = `install -m $perm "$sourcepath" "$destpath"`;
        die("Can't copy file '$sourcepath' '$destpath' perm($perm) $installout") if ($?);
        
        if (exists($file->{"substitution"})) {
            my $buffer = "";
            {
                local $/ = undef;
                open(FILE, $destpath) or die("Could not open file: $!");
                $buffer = <FILE>;
                close(FILE);
            }
            
            foreach (keys %{$file->{"substitution"}}) {
                my $search  = $_;
                my $replace = lookup_replace($lookup, $file->{"substitution"}->{$search});
                $buffer =~ s/$search/$replace/g;
            }
            
            open(FILE, ">", $destpath) or die("Could not open file for writing: $!");
            print(FILE $buffer);
            close(FILE);
        }
        
        push(@{$lookup->{"FILES"}}, $rel_dest);                
    } elsif ($file->{"type"} eq "directory") {
        $destpath   =~ s/\/$//;
        $sourcepath =~ s/\/$//;
        
        my $mkdirout = `mkdir -p "$destpath" 2>&1`;
        die("Can't create destination path '$destpath' $mkdirout") if ($?);
        my $perm = $file->{"mode"};         

        find(
            sub {
                my $rel_file_path = $File::Find::name;
                $rel_file_path =~ s/^.*$sourcepath//;
                                
                my $from = $sourcepath . $rel_file_path;
                my $to   = $destpath   . $rel_file_path;
                                
                if (-d $_) {                    
                    return;
                }
                
                if (exists($file->{"include"})) {
                    my $pass = 0;
                    foreach (@{$file->{"include"}}) {
                        if ($rel_file_path =~ m/$_/ig) {
                            $pass = 1;
                            last;
                        }
                    }

                    return unless($pass);
		}

                my $basedir = dirname($to); 
                `mkdir -p "$basedir" 2>&1`;
                my $out  = `install -m $perm "$from" "$to"`;
                die("Can't copy file '$from' '$to' perm($perm) $out") if ($?);
                push(@{$lookup->{"FILES"}}, $rel_dest . $rel_file_path);
            }, 
            $sourcepath
        );          
    }
}

sub run_rpm_build {
    my $rpmpath  = shift;
    my $specpath = shift;

    $rpmpath  = abs_path($rpmpath);
    $specpath = abs_path($specpath);

    my $topdir = "--define=\"_topdir $rpmpath\"";
    my $output = qx/$rpmbuildexec -bb $topdir $specpath/;
    my $exit   = $?;

    print($output) if ($verbose);
    die("RPM builder failed with code $exit.") if ($exit);
}

sub copy_rpm {
    my $rpmoutpath = shift;
    my $rpmpath    = shift;
    my $lookup     = shift;

    $rpmpath      .= "RPMS/" . $lookup->{"ARCH"};
    my @files      = glob "${rpmpath}/*.rpm";

    print("RPM lookup path '$rpmpath'\n") if ($verbose);

    foreach (@files) {
        move($_, $rpmoutpath . basename($_)) or die("Can't move RPM to rpmoutput path '$rpmoutpath'");
    }
}

sub load_json_file {
    my $file = shift;
    local $/;
    open(JSON, "<${file}"); 
    my $data = <JSON>; 
    close(JSON);
    return decode_json($data);
}



