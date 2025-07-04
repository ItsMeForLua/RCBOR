#!/usr/bin/perl
use strict;
use warnings;
use File::Find;
use File::Path qw(rmtree make_path);
use File::Basename;
use File::Copy;

# Configuration
my $source_dir = '.';
my $target_dir = 'text-mark';

# Remove existing text-mark directory if it exists
if (-d $target_dir) {
    print "Removing existing $target_dir directory...\n";
    rmtree($target_dir) or die "Cannot remove $target_dir: $!";
}

# Create the target directory
make_path($target_dir) or die "Cannot create $target_dir: $!";

# Find all files recursively
my @files;
find(sub {
    return if -d $_; # Skip directories
    return if $File::Find::dir =~ /\Q$target_dir\E/; # Skip our target directory
    push @files, $File::Find::name;
}, $source_dir);

print "Found " . scalar(@files) . " files to convert...\n";

foreach my $file (@files) {
    # Get relative path from source directory
    my $rel_path = $file;
    $rel_path =~ s/^\Q$source_dir\E\/?//;
    
    # Create target path with .md extension
    my $target_file = "$target_dir/$rel_path.md";
    
    # Create target directory structure if needed
    my $target_subdir = dirname($target_file);
    make_path($target_subdir) unless -d $target_subdir;
    
    # Read source file
    open my $src_fh, '<', $file or do {
        warn "Cannot read $file: $!";
        next;
    };
    
    # Create markdown file
    open my $dst_fh, '>', $target_file or do {
        warn "Cannot create $target_file: $!";
        close $src_fh;
        next;
    };
    
    # Get file extension for syntax highlighting
    my ($name, $dir, $ext) = fileparse($file, qr/\.[^.]*/);
    $ext =~ s/^\.//; # Remove leading dot
    
    # Write markdown header with code block
    print $dst_fh "# $rel_path\n\n";
    print $dst_fh "```$ext\n";
    
    # Copy file contents
    while (my $line = <$src_fh>) {
        print $dst_fh $line;
    }
    
    print $dst_fh "\n```\n";
    
    close $src_fh;
    close $dst_fh;
    
    print "Converted: $file -> $target_file\n";
}

print "\nConversion complete! All files saved to $target_dir/\n";