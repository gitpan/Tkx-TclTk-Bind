package Tkx::TclTk::Bind;

# ##############################################################################
# # Script     : Tkx::TclTk::Bind.pm                                           #
# # -------------------------------------------------------------------------- #
# # Copyright  : Frei unter GNU General Public License  bzw.  Artistic License #
# # Autoren    : Jürgen von Brietzke                                   JvBSoft #
# # Version    : 1.2.01                                            16.Jun.2013 #
# # -------------------------------------------------------------------------- #
# # Aufgabe    : Bindet TclTk-Bibliotheken an Perl::Tkx                        #
# # -------------------------------------------------------------------------- #
# # Sprache    : PERL 5                                (V)  5.8.xx  -  5.16.xx #
# # Kodierung  : ISO 8859-15 / Latin-9                         UNIX-Zeilenende #
# # Standards  : Perl-Best-Practices                       severity 1 (brutal) #
# # -------------------------------------------------------------------------- #
# # Pragmas    : base, strict, version, warnings                               #
# # -------------------------------------------------------------------------- #
# # Module     : Archive::Tar                           ActivePerl-CORE-Module #
# #              Config                                                        #
# #              English                                                       #
# #              Exporter                                                      #
# #              File::Spec                                                    #
# #              Tkx                                                           #
# #              ------------------------------------------------------------- #
# #              Const::Fast                                       CPAN-Module #
# #              File::Remove                                                  #
# # -------------------------------------------------------------------------- #
# # TODO       : POD - Documentation                                           #
# ##############################################################################

use strict;
use warnings;

use version;
our $VERSION = q{1.2.01};

use Archive::Tar;
use Config;
use Const::Fast;
use English qw{-no_match_vars};
use File::Remove qw{remove};
use File::Spec;
use Tkx;

# ##############################################################################

use base qw{ Exporter };
our @EXPORT_OK = qw{ &load_library };

# ##############################################################################

our $TEMP_DIR;
our @PACKAGES;

# ##############################################################################
# #                            D E S T R U K T O R                             #
# ##############################################################################
# # Aufgabe   | Löscht die temporären Dateien                                  #
# ##############################################################################

sub END {

   foreach my $package (@PACKAGES) {
      my $dir = File::Spec->catfile( $TEMP_DIR, $package );
      remove( \1, $dir );
   }

} # end of sub END

# ##############################################################################
# # Name      | load_library                                                   #
# # ----------+--------------------------------------------------------------- #
# # Aufgabe   | Lädt ein Bibliotheks-Archiv in das System-Temp-Verzeichnis     #
# # ----------+------------+-------------------------------------------------- #
# # Parameter | scalar     | Name des Bibliothek-Archivs ohne '.xx.tar'        #
# #           | array      | Zu installierender Tcl/Tk-Package-Name            #
# # ----------+------------+-------------------------------------------------- #
# # Rückgabe  | scalar     | Pfad zum entpackten Archiv                        #
# ##############################################################################

sub load_library {

   my ( $library, @package ) = @ARG;

   const my $CONST_UMASK => oct 777;

   # --- TEMP-Verzeichnis bestimmen --------------------------------------------
   $TEMP_DIR
      = defined $ENV{TMP}    ? $ENV{TMP}
      : defined $ENV{TEMP}   ? $ENV{TEMP}
      : defined $ENV{TMPDIR} ? $ENV{TMPDIR}
      :                        undef;
   if ( not defined $TEMP_DIR ) {
      _error( 'No environment value "ENV{TMP & TEMP & TMPDIR}" found',
         $library );
   }

   # --- TEMP-Verzeichnis erzeugen wenn nötig ----------------------------------
   $TEMP_DIR = File::Spec->catfile( $TEMP_DIR, 'TclTk' );
   if ( not -e $TEMP_DIR ) {
      mkdir $TEMP_DIR, $CONST_UMASK
         or _error( "Can't create directory\n$TEMP_DIR", $library );
   }

   # --- Archiv-Name und -Typ bestimmen ----------------------------------------
   my $archname
      = $OSNAME =~ /MSWin32/ismx ? 'mswin'
      : $OSNAME =~ /linux/ismx   ? 'linux'
      : $OSNAME =~ /darwin/ismx  ? 'darwin'
      :                            undef;
   if ( not defined $archname ) {
      _error( "System $OSNAME is not supported", $library );
   }
   my $archtype
      = $Config{archname} =~ /i686-linux/smx   ? '32'
      : $Config{archname} =~ /x86_64-linux/smx ? '64'
      : $Config{archname} =~ /MSWin32-x86/smx  ? '32'
      : $Config{archname} =~ /MSWin32-x64/smx  ? '64'
      : $Config{archname} =~ /darwin/smx       ? 'xx'
      :                                          undef;
   if ( not defined $archtype ) {
      _error( 'System type unknown - must be 32- or 64-bit', $library );
   }
   my $tar_name = "$library.$archname.$archtype.tar";

   my $archiv;

   # --- Archiv-Datei aus 'PerlApp' laden --------------------------------------
   if ( defined $PerlApp::BUILD ) {
      $archiv = PerlApp::extract_bound_file($tar_name);
      if ( not defined $archiv ) {
         _error( "Library '$archiv' not boundet", $library );
      }
   }

   # --- Archiv-Datei im Installations-Pfad suchen -----------------------------
   else {
      foreach my $lib (@INC) {
         $archiv
            = File::Spec->catfile( $lib, qw(Tkx TclTk Bind TAR), $tar_name );
         last if ( -e $archiv );
         $archiv = undef;
      }
      if ( not defined $archiv ) {
         _error( "Library '$tar_name' not found", $library );
      }
   }

   # --- Archiv-Datei in TEMP-Verzeichnis entpacken ----------------------------
   my $tar = Archive::Tar->new();
   $tar->read($archiv);
   my @entries = $tar->list_files;
   foreach my $entry (@entries) {
      my $target = File::Spec->catfile( $TEMP_DIR, $entry );
      if ( $entry =~ /[\/]$/ismx ) {
         if ( not -e $target ) {
            mkdir $target, $CONST_UMASK
               or _error( "Can't create directory\n$target", $library );
         }
      }
      else {
         my $file = $tar->get_content($entry);
         open my $FH, '>', $target or _error( "Can't open\n$target", $library );
         binmode $FH;
         print {$FH} $file or _error( "Can't print\n$target", $library );
         close $FH or _error( "Can't close\n$target", $library );
         chmod $CONST_UMASK, $target;
      }
   }

   push @PACKAGES, @package;

   return $TEMP_DIR;

} # end of sub load_library

# ##############################################################################
# #                        P R I V A T E   --   S U B S                        #
# ##############################################################################

sub _error {

   my ( $error_text, $library ) = @ARG;

   Tkx::package_require('BWidget');
   my $error_window = Tkx::widget->new(q{.});
   my $return       = $error_window->new_MessageDlg(
      -title   => "Tkx::TclTk::Bind::$library",
      -message => $error_text,
      -icon    => 'error',
      -buttons => ['Cancel'],
      -font    => 'TkCaptionFont',
      -width   => 500,
   );
   Tkx::destroy($error_window);
   exit;

} # end of sub _error

# ##############################################################################
# #                                  E N D E                                   #
# ##############################################################################
1;

__END__

=pod

=head1 NAME

Tkx::TclTk::Bind - Load Tcl/Tk-Library to Temp-Directory

=head1 VERSION

This is version 1.2.01

=head1 SYNOPSIS

   use Tkx::TclTk::Bind qw{ &load_library };
   ...
   my $temp_dir = load_library('tlc-tk-library-archiv');

=head1 DESCRIPTION

This modul is a helper-modul for moduls:

=over 3

=item Tkx::TclTk::Bind::IWidgets

=item Tkx::TclTk::Bind::ImageLibrary

=back

Use this modul not direct !!!

=head1 FUNCTIONS

=head2 load_library(...)

Load and extract the given library-archiv (TAR-Ball without system-type and
'.tar') to the User-TEMP-Directory.

When program will ending, the modul delete all temp-files.

The modul include support for B<PerlApp> from B<ActiveState>.

=head1 PRAGMAS

=over 3

=item base

=item strict

=item version

=item warnings

=back

=head1 MODULE

=over 3

=item Archive::Tar

=item Config

=item Const::Fast

=item English

=item Exporter

=item File::Remove

=item File::Spec

=item Tkx

=back

=head1 AUTHOR

Juergen von Brietzke <juergen.von.brietzke@t-online.de>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) by Juergen von Brietzke.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
