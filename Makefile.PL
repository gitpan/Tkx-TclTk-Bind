use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Tkx::TclTk::Bind',
    VERSION_FROM      => 'lib/Tkx/TclTk/Bind.pm',
    PREREQ_PM         => { Archive::Tar => 0,
                           Const::Fast => 0,
                           English => 0,
                           Exporter => 0,
                           File::Remove => 0,
                           File::Spec => 0,
                           Tkx => 0,
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT  => 'Load Tcl/Tk-Library to Temp-Directory',
       AUTHOR         => 'Jürgen von Brietzke <brietzkej@t-online.de>') : ()),
);
