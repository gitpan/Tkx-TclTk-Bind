if (  $^O =~ /MSWin32/ismx
   or $^O =~ /linux/ismx
   or $^O =~ /darwin/ismx )
{
   use ExtUtils::MakeMaker;
   WriteMakefile(
      NAME         => 'Tkx::TclTk::Bind',
      VERSION_FROM => 'lib/Tkx/TclTk/Bind.pm',
      PREREQ_PM    => {
         Archive::Tar => 0,
         Config       => 0,
         Const::Fast  => 0,
         English      => 0,
         Exporter     => 0,
         File::Remove => 0,
         File::Spec   => 0,
         Tkx          => 0,
      },
      (  $] >= 5.005
         ?    ## Add these new keywords supported since 5.005
            (
            ABSTRACT => 'Load Tcl/Tk-Library to Temp-Directory',
            AUTHOR   => 'Jürgen von Brietzke <brietzkej@t-online.de>'
            )
         : ()
      ),
   );
}
else {
   {
      print("OS unsupported\nModul supported Linux, MSWin32 and MacOS X")
         and exit;
   }
}
