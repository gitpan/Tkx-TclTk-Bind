package Tkx::TclTk::Bind;

# ##############################################################################
# # Script     : Tkx::TclTk::Bind.pm                                           #
# # -------------------------------------------------------------------------- #
# # Sprache    : PERL 5                                (V)  5.8.xx  -  5.16.xx #
# # Standards  : Perl-Best-Practices                       severity 1 (brutal) #
# # -------------------------------------------------------------------------- #
# # Autoren    : Jürgen von Brietzke                                   JvBSoft #
# # Version    : 1.0.00                                            17.Dez.2012 #
# # -------------------------------------------------------------------------- #
# # Aufgabe    : Bindet TclTk-Bibliotheken an Perl::Tkx                        #
# # -------------------------------------------------------------------------- #
# # Pragmas    : base, strict, warnings                                        #
# # -------------------------------------------------------------------------- #
# # Module     : Archive::Tar                       ActivePerl-Standard-Module #
# #              English                                                       #
# #              Exporter                                                      #
# #              File::Spec                                                    #
# #              Tkx                                                           #
# #              ------------------------------------------------------------- #
# #              Const::Fast                             ActivePerl-PPM-Module #
# #              File::Remove                                                  #
# # -------------------------------------------------------------------------- #
# # Copyright  : Frei unter GNU General Public License bzw. Artistic License   #
# ##############################################################################

use strict;
use warnings;

our $VERSION = q{1.0.00};

use Archive::Tar;
use Const::Fast;
use English qw{-no_match_vars};
use File::Remove qw(remove);
use File::Spec;
use Tkx;

use base qw{ Exporter };

our @EXPORT_OK = qw{ &load_library };

our $TEMP_DIR;

# ##############################################################################
# # Aufgabe   : Lädt ein Bibliotheks-Archiv in das System-Temp-Verzeichnis     #
# # Parameter : scalar        Name des Bibliothek-Archivs ohne '.tar'          #
# # Rückgabe  : scalar        Pfad zum entpackten Archiv                       #
# ##############################################################################

sub load_library {

   my ($library) = @ARG;

   const my $UMASK => oct 777;

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
      mkdir $TEMP_DIR, $UMASK
         or _error( "Can't create directory\n$TEMP_DIR", $library );
   }

   # --- Archiv-Suffix bestimmen -----------------------------------------------
   my $suffix
      = $OSNAME =~ /MSWin32/ismx ? 'mswin'
      : $OSNAME =~ /linux/ismx   ? 'linux'
      : $OSNAME =~ /darwin/ismx  ? 'darwin'
      :                            undef;
   if ( not defined $suffix ) {
      _error( "Library '$library' not for $OSNAME not boundet", $library );
   }

   # --- Archiv-Datei suchen ---------------------------------------------------
   my $archiv;
   if ( defined $PerlApp::BUILD ) {    ### Archiv-Pfad für PerApp
      $archiv = PerlApp::extract_bound_file("$library.tar");
      if ( not defined $archiv ) {
         _error( "Library '$library.tar' not boundet", $library );
      }
   }
   else {                              ### Archiv-Pfad für Perl
      foreach my $lib (@INC) {
         $archiv = File::Spec->catfile( $lib, qw(Tkx TclTk Bind TAR),
            "$library.$suffix.tar" );
         last if ( -e $archiv );
      }
      if ( not defined $archiv ) {
         _error( "Library '$library.tar' not found", $library );
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
            mkdir $target, $UMASK
               or _error( "Can't create directory\n$target", $library );
         }
      }
      else {
         my $file = $tar->get_content($entry);
         open my $FH, '>', $target or _error( "Can't open\n$target", $library );
         binmode $FH;
         print {$FH} $file or _error( "Can't print\n$target", $library );
         close $FH or _error( "Can't close\n$target", $library );
         chmod $UMASK, $target;
      }
   }

   return $TEMP_DIR;

} # end of sub load_library

# ##############################################################################
# # Aufgabe   : Löscht beim Programmende die temporären Dateien                #
# # Parameter : keine                                                          #
# # Rückgabe  : keine                                                          #
# ##############################################################################

sub END {

   remove( \1, $TEMP_DIR );

} # end of sub END

# ##############################################################################
# #                        P R I V A T E   --   S U B S                        #
# ##############################################################################

sub _error {

   my ( $error_text, $library ) = @ARG;
   my $error_window = Tkx::widget->new(q{.});
   $error_window->g_wm_title('ERROR');
   Tkx::tk___messageBox(
      -parent  => $error_window,
      -title   => "Tkx::TclTk::Bind::$library",
      -type    => 'ok',
      -icon    => 'error',
      -message => $error_text,
   );

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

This is version 1.0.00

=head1 SYNOPSIS

   use Tkx::TclTk::Bind qw{ &load_library };
   ...
   my $temp_dir = load_library('tlc-tk-library-archiv');

=head1 DESCRIPTION

This modul is a helper-modul for moduls:

=over3

=item Tkx::TclTk::Bind::IWidgets

=item Tkx::TclTk::Bind::ImageLibrary

=back

=head1 FUNCTIONS

=head2 load_library(...)

Load and extract the given library-archiv (TAR-Ball without system-type and
'.tar') to the User-TEMP-Directory.

When program will ending, the modul delete all temp-files.

The modul include support for B<PerlApp> from B<ActiveState>.

=head1 PRAGMAS

=over 3

=item strict

=item warnings

back

=head1 MODULE

=over 3

=item Archive::Tar

=item Const::Fast

=item Englich

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
